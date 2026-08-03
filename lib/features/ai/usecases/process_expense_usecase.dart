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

class ProcessExpenseUseCase {
  final ExtractionAgent extractionAgent;
  final StoreLookupAgent storeLookupAgent;
  final ValidationAgent validationAgent;
  final CorrectionAgent correctionAgent;
  final IMapSearchService mapSearchService;

  ProcessExpenseUseCase({
    required this.extractionAgent,
    required this.storeLookupAgent,
    required this.validationAgent,
    required this.correctionAgent,
    required this.mapSearchService,
  });

  Future<UseCaseResult> execute(TransactionSession session, {void Function(String)? onProgress}) async {
    // 1. Extraction Phase
    if (session.records.isEmpty) {
      onProgress?.call('🔍 正在提取花費資訊...');
      final extractedData = await extractionAgent.execute(session.originalText);
      final records = extractedData.map((data) => TransactionRecord(data)).toList();
      session.setRecords(records);
      session.markProcessingRecords();
    }

    final records = session.records;

    // 2. Processing Phase (Linear pipeline per record)
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      var status = record.status;

      // Step A: Store Resolution
      if (status == RecordStatus.extracted) {
        if (record.requiresStoreLookup()) {
          final data = record.data;
          onProgress?.call('\n處理第 \${i + 1} 筆商品: \${data.item}');
          onProgress?.call('查詢店家名稱: \${data.store}...');

          final queryParts = [data.locationClue, data.store, data.item]
              .where((s) => s != null && s.isNotEmpty)
              .toList();
          final queryStr = queryParts.join(' ').trim();

          List<StoreSearchResult> searchResults = [];
          if (queryStr.isNotEmpty) {
            searchResults = await mapSearchService.search(queryStr);
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
            onProgress?.call('✅ 更新店家名稱為: \${lookupResponse.storeName}');
            record.updateStore(lookupResponse.storeName!);
            record.markValidating();
          } else {
            record.markNeedsStoreResolution();
            return RequireStoreSelectionResult(
              recordIndex: i,
              options: lookupResponse.options ?? [],
              message: '無法確定第 \${i + 1} 筆商品 (\${data.item}) 的店家名稱，請從地圖結果中選擇：',
            );
          }
        } else {
          record.markValidating();
        }
        status = record.status;
      }

      // Step B: Validation
      if (status == RecordStatus.validating) {
        onProgress?.call('驗證商品資訊...');
        final validationResponse = await validationAgent.execute(
          ValidationInput(record: record.data),
        );

        if (validationResponse.isValid) {
          onProgress?.call('✅ 資訊確認無誤。');
          record.markResolved();
        } else {
          record.markNeedsHumanCorrection(validationResponse.question ?? '請補充缺失的資訊。');
          return RequireCorrectionResult(
            recordIndex: i,
            question: record.validationQuestion!,
          );
        }
        status = record.status;
      }
    }

    session.markCompleted();
    return SuccessResult();
  }

  Future<UseCaseResult> handleUserCorrection(
    TransactionSession session, 
    int recordIndex, 
    String userInput, 
    {void Function(String)? onProgress}
  ) async {
    final record = session.records[recordIndex];

    if (record.status == RecordStatus.needsStoreResolution) {
      onProgress?.call('✅ 更新店家名稱為: \$userInput');
      record.updateStore(userInput);
      record.markValidating();
    } else if (record.status == RecordStatus.needsHumanCorrection) {
      final correctionResponse = await correctionAgent.execute(
        CorrectionInput(record: record.data, answer: userInput),
      );

      record.updateData(correctionResponse.record);
      record.markValidating(); // Re-validate after correction
    }

    return execute(session, onProgress: onProgress);
  }
}

final processExpenseUseCaseProvider = Provider<ProcessExpenseUseCase>((ref) {
  return ProcessExpenseUseCase(
    extractionAgent: ref.watch(extractionAgentProvider),
    storeLookupAgent: ref.watch(storeLookupAgentProvider),
    validationAgent: ref.watch(validationAgentProvider),
    correctionAgent: ref.watch(correctionAgentProvider),
    mapSearchService: ref.watch(mapSearchServiceProvider),
  );
});
