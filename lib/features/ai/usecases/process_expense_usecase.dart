import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_record.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_session.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/extraction_agent/extraction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/store_lookup_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/validation_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/google_map_search_service.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

abstract class UseCaseResult {}

class RequireStoreSelectionResult extends UseCaseResult {
  final int recordIndex;
  final List<String> options;
  final String message;

  RequireStoreSelectionResult({
    required this.recordIndex,
    required this.options,
    required this.message,
  });
}

class RequireCorrectionResult extends UseCaseResult {
  final int recordIndex;
  final String question;

  RequireCorrectionResult({
    required this.recordIndex,
    required this.question,
  });
}

class SuccessResult extends UseCaseResult {}

/// 黑板模式 (Blackboard Pattern) 的自治專家介面
abstract class IAgenticWorker {
  /// 評估是否需要處理此筆紀錄
  Future<bool> requiresProcessing(TransactionRecord record);

  /// 處理紀錄，並修改 record 的資料。若需要等待使用者輸入，回傳 UseCaseResult
  Future<UseCaseResult?> process(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  );
}

/// 專家一：店家名稱查詢與確認
class StoreLookupWorker implements IAgenticWorker {
  final StoreLookupAgent storeLookupAgent;
  final IMapSearchService mapSearchService;
  final bool isGoogleMapEnabled;

  StoreLookupWorker(this.storeLookupAgent, this.mapSearchService, {required this.isGoogleMapEnabled});

  @override
  Future<bool> requiresProcessing(TransactionRecord record) async {
    final data = record.data;
    
    // 如果沒有店名也沒有地點，則不需要查地圖
    if ((data.store == null || data.store!.isEmpty) && 
        (data.locationClue == null || data.locationClue!.isEmpty)) {
      return false;
    }

    // 取得當前的查詢關鍵字組合
    final currentQueryStr = [data.locationClue, data.store].join('|');
    
    // 檢查黑板記憶：如果跟上次查詢的字串一樣，代表已經查過了，不要再查 (避免無窮迴圈)
    final lastQueryStr = record.metadata['StoreLookupWorker_LastQuery'] as String?;
    if (currentQueryStr == lastQueryStr) {
      return false;
    }

    return true; // 資料有變，且有線索，需要處理！
  }

  @override
  Future<UseCaseResult?> process(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  ) async {
    final data = record.data;
    onProgress?.call('處理第 ${recordIndex + 1} 筆商品: ${data.item}');
    
    final hintDisplay = (data.store == null || data.store!.isEmpty) ? '可能的線索' : data.store;
    onProgress?.call('查詢店家名稱: $hintDisplay...');

    final queryParts = [data.locationClue, data.store, data.item]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    final queryStr = queryParts.join(' ').trim();

    List<StoreSearchResult> searchResults = [];
    if (!isGoogleMapEnabled) {
      onProgress?.call('Google Map 查詢未啟用，交由 AI 直接推斷');
    } else if (queryStr.isNotEmpty) {
      searchResults = await mapSearchService.search(queryStr);
      if (searchResults.isEmpty) {
        onProgress?.call('Google Map 查無結果，交由 AI 直接推斷');
      } else {
        onProgress?.call('Google Map 找到 ${searchResults.length} 筆可能店家，交由 AI 篩選');
      }
    } else {
      onProgress?.call('無足夠線索查詢地圖，交由 AI 推斷');
    }

    final lookupResponse = await storeLookupAgent.execute(
      StoreLookupInput(
        originalText: session.originalText,
        hint: data.store ?? '',
        location: data.locationClue ?? '',
        item: data.item ?? '',
        searchResults: searchResults,
      ),
    );

    // 紀錄這次查詢的關鍵字，寫入黑板記憶
    record.metadata['StoreLookupWorker_LastQuery'] = [data.locationClue, data.store].join('|');

    if (lookupResponse.isCertain && lookupResponse.storeName != null && lookupResponse.storeName!.isNotEmpty) {
      onProgress?.call('確認店家名稱為: ${lookupResponse.storeName}');
      record.updateStore(lookupResponse.storeName!);
      // 因為 updateStore 改變了 store 名字，這會導致 requiresProcessing 再度回傳 true，
      // 所以我們必須同時更新 metadata 的 LastQuery，防止下一次迴圈再次執行！
      record.metadata['StoreLookupWorker_LastQuery'] = [data.locationClue, lookupResponse.storeName].join('|');
      return null;
    } else {
      final options = lookupResponse.options ?? [];
      String message;
      if (options.isEmpty) {
        message = '請問「${data.item ?? data.store ?? '未知項目'}」是在哪家店消費的？請直接輸入：';
      } else {
        message = '請問「${data.item ?? data.store ?? '未知項目'}」是在哪家店消費的？';
      }

      return RequireStoreSelectionResult(
        recordIndex: recordIndex,
        options: options,
        message: message,
      );
    }
  }
}

/// 專家二：資料完整性驗證
class ValidationWorker implements IAgenticWorker {
  final ValidationAgent validationAgent;

  ValidationWorker(this.validationAgent);

  @override
  Future<bool> requiresProcessing(TransactionRecord record) async {
    // 如果這筆紀錄已經被 Orchestrator 標記為 resolved，或者已經問過同一個問題且資料沒變，就不用處理
    if (record.isResolved) return false;

    // 將整包資料轉為 JSON string 作為 Hash
    final currentDataHash = record.data.toMap().toString();
    final lastValidatedHash = record.metadata['ValidationWorker_LastHash'] as String?;
    
    // 如果這筆資料狀態已經被驗證過且要求人類修正，就不該一直重複驗證並卡死迴圈
    if (currentDataHash == lastValidatedHash) {
      return false;
    }

    return true;
  }

  @override
  Future<UseCaseResult?> process(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  ) async {
    onProgress?.call('驗證商品資訊...');
    final validationResponse = await validationAgent.execute(
      ValidationInput(record: record.data),
    );

    // 記住這次驗證的資料狀態
    record.metadata['ValidationWorker_LastHash'] = record.data.toMap().toString();

    if (validationResponse.isValid) {
      onProgress?.call('資訊確認無誤。');
      return null; 
    } else {
      final question = validationResponse.question ?? '請補充缺失的資訊。';
      record.setValidationQuestion(question);
      return RequireCorrectionResult(
        recordIndex: recordIndex,
        question: question,
      );
    }
  }
}

/// 專家三：人類修正與動態分類處理
class CorrectionWorker implements IAgenticWorker {
  final CorrectionAgent correctionAgent;

  CorrectionWorker(this.correctionAgent);

  @override
  Future<bool> requiresProcessing(TransactionRecord record) async {
    // 只要黑板上出現了使用者的輸入，且指定交給 CorrectionWorker 處理，就舉手！
    return record.metadata.containsKey('CorrectionWorker_Input');
  }

  @override
  Future<UseCaseResult?> process(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  ) async {
    // 消耗黑板上的輸入 (拿取並移除)
    final userInput = record.metadata.remove('CorrectionWorker_Input') as String;
    final categories = record.metadata.remove('CorrectionWorker_Categories') as List<CategoryModel>;
    
    onProgress?.call('處理您的補充資訊...');
    final correctionResponse = await correctionAgent.execute(
      CorrectionInput(
        record: record.data, 
        answer: userInput,
        question: record.validationQuestion,
        categories: categories,
      ),
    );
    
    // 更新黑板上的資料
    record.updateData(correctionResponse.record);
    
    return null; // 處理完畢，讓迴圈繼續讓其他專家檢視新資料
  }
}

/// 統籌中心 (The Orchestrator) - 採用黑板模式 (Blackboard Pattern)
class ProcessExpenseUseCase {
  final ExtractionAgent extractionAgent;
  final List<IAgenticWorker> workers;

  ProcessExpenseUseCase({
    required this.extractionAgent,
    required StoreLookupAgent storeLookupAgent,
    required IMapSearchService mapSearchService,
    required ValidationAgent validationAgent,
    required CorrectionAgent correctionAgent,
    required bool isGoogleMapEnabled,
  }) : workers = [
         StoreLookupWorker(storeLookupAgent, mapSearchService, isGoogleMapEnabled: isGoogleMapEnabled),
         ValidationWorker(validationAgent),
         CorrectionWorker(correctionAgent),
       ];

  Future<UseCaseResult> execute(TransactionSession session, List<CategoryModel> categories, {void Function(String)? onProgress}) async {
    // 1. Extraction Phase
    if (session.records.isEmpty) {
      onProgress?.call('正在提取花費資訊...');
      final extractedData = await extractionAgent.execute(
        session.originalText, 
        categories: categories,
      );

      final validCategoryIds = categories.map((c) => c.id).toSet();
      final otherCategoryId = categories.firstWhere(
        (c) => c.name == '其他', 
        orElse: () => categories.isNotEmpty ? categories.first : throw Exception('No categories available')
      ).id;

      final records = extractedData.map((data) {
        String safeCategoryId = data.categoryId ?? otherCategoryId;
        if (!validCategoryIds.contains(safeCategoryId)) {
          safeCategoryId = otherCategoryId;
        }
        return TransactionRecord(data.copyWith(categoryId: safeCategoryId));
      }).toList();

      session.setRecords(records);
      session.markProcessingRecords();
    }

    // 2. Blackboard Orchestration Phase (黑板調度迴圈)
    for (int i = 0; i < session.records.length; i++) {
      final record = session.records[i];
      if (record.isResolved) continue;

      bool changed = true;
      while (changed && !record.isResolved) {
        changed = false;
        
        // 讓每位專家檢視黑板上的資料
        for (final worker in workers) {
          if (await worker.requiresProcessing(record)) {
            final result = await worker.process(i, record, session, onProgress: onProgress);
            
            // 如果專家需要人類協助，直接中斷回傳給 UI
            if (result != null) {
              return result;
            }
            
            // 專家處理完畢，資料可能已改變。重新開始迴圈讓所有人再次檢視新資料！
            changed = true;
            break; 
          }
        }
      }
      
      // 當所有專家都不再需要處理這筆資料，代表它完美過關了！
      if (!changed) {
        record.markResolved();
      }
    }

    session.markCompleted();
    return SuccessResult();
  }

  /// 處理人類修正的回覆。此方法與業務邏輯完全解耦，僅做為資料寫入器。
  Future<UseCaseResult> handleUserCorrection(
    TransactionSession session, 
    int recordIndex, 
    String userInput,
    List<CategoryModel> categories,
    UseCaseResult pendingAction,
    {void Function(String)? onProgress}
  ) async {
    final record = session.records[recordIndex];

    if (pendingAction is RequireStoreSelectionResult) {
      onProgress?.call('收到輸入「$userInput」，準備更新店家名稱...');
      // 這種最簡單的修改不需要 AI，直接更新黑板即可。更新完後，其他專家 (如 ValidationWorker) 會自動接手。
      record.updateStore(userInput);
    } 
    else if (pendingAction is RequireCorrectionResult) {
      // 複雜的語義修正，將使用者的輸入寫在黑板上，交給 CorrectionWorker 去處理
      record.metadata['CorrectionWorker_Input'] = userInput;
      record.metadata['CorrectionWorker_Categories'] = categories;
    }

    // 資料/狀態 更新完畢後，直接把黑板重新丟回 Orchestrator 進行新一輪的檢視！
    return execute(session, categories, onProgress: onProgress);
  }
}

final processExpenseUseCaseProvider = Provider.autoDispose<ProcessExpenseUseCase>((ref) {
  final extractionAgent = ref.watch(extractionAgentProvider);
  final storeLookupAgent = ref.watch(storeLookupAgentProvider);
  final mapSearchService = ref.watch(mapSearchServiceProvider);
  final validationAgent = ref.watch(validationAgentProvider);
  final correctionAgent = ref.watch(correctionAgentProvider);
  final isGoogleMapEnabled = ref.watch(aiConfigControllerProvider).isGoogleMapEnabled;

  return ProcessExpenseUseCase(
    extractionAgent: extractionAgent,
    storeLookupAgent: storeLookupAgent,
    mapSearchService: mapSearchService,
    validationAgent: validationAgent,
    correctionAgent: correctionAgent,
    isGoogleMapEnabled: isGoogleMapEnabled,
  );
});
