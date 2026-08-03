import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/enums/record_status.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_record.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_session.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/extraction_agent/extraction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/store_lookup_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/validation_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/google_map_search_service.dart';
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

/// 定義花費紀錄的處理步驟介面 (Pipeline Step)
abstract class RecordProcessingStep {
  /// 執行此步驟，若需要中斷等待使用者輸入，則回傳 UseCaseResult
  Future<UseCaseResult?> execute(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  );

  /// 處理使用者的修正輸入，若處理完畢後仍需等待，可回傳 UseCaseResult
  Future<UseCaseResult?> handleCorrection(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    String userInput,
    {void Function(String)? onProgress}
  );
}

/// 步驟一：店家名稱查詢與確認
class StoreResolutionStep implements RecordProcessingStep {
  final StoreLookupAgent storeLookupAgent;
  final IMapSearchService mapSearchService;

  StoreResolutionStep(this.storeLookupAgent, this.mapSearchService);

  @override
  Future<UseCaseResult?> execute(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  ) async {
    if (record.status != RecordStatus.extracted) return null;
    if (!record.requiresStoreLookup()) {
      record.markValidating();
      return null;
    }

    final data = record.data;
    onProgress?.call('處理第 ${recordIndex + 1} 筆商品: ${data.item}');
    
    // 友善顯示：如果 store 為 null，顯示提示而非 "null"
    final hintDisplay = (data.store == null || data.store!.isEmpty) ? '可能的線索' : data.store;
    onProgress?.call('查詢店家名稱: $hintDisplay...');

    final queryParts = [data.locationClue, data.store, data.item]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    final queryStr = queryParts.join(' ').trim();

    List<StoreSearchResult> searchResults = [];
    if (queryStr.isNotEmpty) {
      searchResults = await mapSearchService.search(queryStr);
      if (searchResults.isEmpty) {
        onProgress?.call('(Google Map 查無結果，或未啟用，交由 AI 直接推斷)');
      } else {
        onProgress?.call('(Google Map 找到 ${searchResults.length} 筆可能店家，交由 AI 篩選)');
      }
    } else {
      onProgress?.call('(無足夠線索查詢地圖，交由 AI 盲猜)');
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

    if (lookupResponse.isCertain && lookupResponse.storeName != null && lookupResponse.storeName!.isNotEmpty) {
      onProgress?.call('✅ 確認店家名稱為: ${lookupResponse.storeName}');
      record.updateStore(lookupResponse.storeName!);
      record.markValidating();
      return null;
    } else {
      record.markNeedsStoreResolution();
      
      final options = lookupResponse.options ?? [];
      String message;
      if (options.isEmpty) {
        message = '請問「${data.item}」是在哪家店消費的？請直接輸入：';
      } else {
        message = '請問「${data.item}」是在哪家店消費的？';
      }

      return RequireStoreSelectionResult(
        recordIndex: recordIndex,
        options: options,
        message: message,
      );
    }
  }

  @override
  Future<UseCaseResult?> handleCorrection(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    String userInput,
    {void Function(String)? onProgress}
  ) async {
    if (record.status != RecordStatus.needsStoreResolution) return null;
    
    onProgress?.call('✅ 更新店家名稱為: $userInput');
    record.updateStore(userInput);
    record.markValidating();
    return null;
  }
}

/// 步驟二：資料完整性驗證
class ValidationStep implements RecordProcessingStep {
  final ValidationAgent validationAgent;
  final CorrectionAgent correctionAgent;

  ValidationStep(this.validationAgent, this.correctionAgent);

  @override
  Future<UseCaseResult?> execute(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    {void Function(String)? onProgress}
  ) async {
    if (record.status != RecordStatus.validating) return null;

    onProgress?.call('驗證商品資訊...');
    final validationResponse = await validationAgent.execute(
      ValidationInput(record: record.data),
    );

    if (validationResponse.isValid) {
      onProgress?.call('✅ 資訊確認無誤。');
      record.markResolved();
      return null;
    } else {
      final question = validationResponse.question ?? '請補充缺失的資訊。';
      record.markNeedsHumanCorrection(question);
      return RequireCorrectionResult(
        recordIndex: recordIndex,
        question: question,
      );
    }
  }

  @override
  Future<UseCaseResult?> handleCorrection(
    int recordIndex,
    TransactionRecord record,
    TransactionSession session,
    String userInput,
    {void Function(String)? onProgress}
  ) async {
    if (record.status != RecordStatus.needsHumanCorrection) return null;

    onProgress?.call('處理您的補充資訊...');
    final correctionResponse = await correctionAgent.execute(
      CorrectionInput(record: record.data, answer: userInput),
    );

    record.updateData(correctionResponse.record);
    record.markValidating(); // 修正後重設為 validating，讓管線重新驗證
    return null; // 回傳 null 代表這一步的 correction 做完了，後續讓主迴圈繼續走
  }
}

/// 統籌花費紀錄處理流程的 UseCase
class ProcessExpenseUseCase {
  final ExtractionAgent extractionAgent;
  final List<RecordProcessingStep> pipeline;

  ProcessExpenseUseCase({
    required this.extractionAgent,
    required StoreLookupAgent storeLookupAgent,
    required ValidationAgent validationAgent,
    required CorrectionAgent correctionAgent,
    required IMapSearchService mapSearchService,
  }) : pipeline = [
         StoreResolutionStep(storeLookupAgent, mapSearchService),
         ValidationStep(validationAgent, correctionAgent),
       ];

  Future<UseCaseResult> execute(TransactionSession session, List<CategoryModel> categories, {void Function(String)? onProgress}) async {
    // 1. Extraction Phase
    if (session.records.isEmpty) {
      onProgress?.call('🔍 正在提取花費資訊...');
      final extractedData = await extractionAgent.execute(
        session.originalText, 
        categories: categories,
      );
      final records = extractedData.map((data) => TransactionRecord(data)).toList();
      session.setRecords(records);
      session.markProcessingRecords();
    }

    // 2. Pipeline Processing Phase
    for (int i = 0; i < session.records.length; i++) {
      final record = session.records[i];
      
      // 將 record 依序餵給 Pipeline 中的每一個 Step
      for (final step in pipeline) {
        // 若 Record 已處理完成，則提早結束該 Record 的 Pipeline
        if (record.status == RecordStatus.resolved) break;
        
        final result = await step.execute(i, record, session, onProgress: onProgress);
        
        // 若 Step 回傳了需要中斷並詢問使用者的 Result，則直接跳出 UseCase 執行
        if (result != null) {
          return result;
        }
      }
    }

    // 所有紀錄皆跑完 Pipeline 且無中斷，代表全部完成
    session.markCompleted();
    return SuccessResult();
  }

  Future<UseCaseResult> handleUserCorrection(
    TransactionSession session, 
    int recordIndex, 
    String userInput,
    List<CategoryModel> categories,
    {void Function(String)? onProgress}
  ) async {
    final record = session.records[recordIndex];

    // 讓 Pipeline 中的每個 Step 都有機會處理使用者的修正
    for (final step in pipeline) {
      await step.handleCorrection(recordIndex, record, session, userInput, onProgress: onProgress);
    }

    // 修正完畢後，再次啟動主 Pipeline 以繼續後續流程
    return execute(session, categories, onProgress: onProgress);
  }
}

final processExpenseUseCaseProvider = Provider.autoDispose<ProcessExpenseUseCase>((ref) {
  return ProcessExpenseUseCase(
    extractionAgent: ref.watch(extractionAgentProvider),
    storeLookupAgent: ref.watch(storeLookupAgentProvider),
    validationAgent: ref.watch(validationAgentProvider),
    correctionAgent: ref.watch(correctionAgentProvider),
    mapSearchService: ref.watch(mapSearchServiceProvider),
  );
});
