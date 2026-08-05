import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/record_data.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/prompts.dart';

class CorrectionInput {
  final RecordData record;
  final String answer;
  final String? question;

  CorrectionInput({
    required this.record,
    required this.answer,
    this.question,
  });
}

class CorrectionResult {
  final RecordData record;

  CorrectionResult({required this.record});
}

class CorrectionAgent extends BaseAgent<CorrectionInput, CorrectionResult> {
  CorrectionAgent(AIProvider provider) : super('Correction', provider);

  @override
  Future<CorrectionResult> execute(CorrectionInput input, {void Function(String)? onChunk}) async {
    final systemPrompt = buildSystemPrompt();
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);
    
    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }
    
    final map = extractJson<Map<String, dynamic>>(resultText, 'object');
    return CorrectionResult(record: RecordData.fromMap(map));
  }
}

final correctionAgentProvider = Provider.autoDispose<CorrectionAgent>((ref) {
  return CorrectionAgent(ref.watch(aiProviderProvider));
});
