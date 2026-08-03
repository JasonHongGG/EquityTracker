import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/record_data.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/extraction_agent/prompts.dart';

class ExtractionAgent extends BaseAgent<String, List<RecordData>> {
  ExtractionAgent(AIProvider provider) : super('Extraction', provider);

  @override
  Future<List<RecordData>> execute(String input, {void Function(String)? onChunk}) async {
    final systemPrompt = buildSystemPrompt();
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);
    
    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }
    
    final List<dynamic> jsonArray = extractJson<List<dynamic>>(resultText, 'array');
    return jsonArray.map((map) => RecordData.fromMap(map as Map<String, dynamic>)).toList();
  }
}

final extractionAgentProvider = Provider.autoDispose<ExtractionAgent>((ref) {
  return ExtractionAgent(ref.watch(aiProviderProvider));
});
