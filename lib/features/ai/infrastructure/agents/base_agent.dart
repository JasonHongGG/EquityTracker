import 'dart:convert';
import 'package:equity_tracker/features/ai/domain/exceptions/ai_parsing_error.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/ai_agent_logger.dart';

abstract class BaseAgent<TInput, TOutput> {
  final String name;
  final AIProvider provider;
  late final AIAgentLogger logger;

  BaseAgent(this.name, this.provider) {
    logger = AIAgentLogger(name);
  }

  Future<TOutput> execute(TInput input, {void Function(String)? onChunk});

  Stream<String> executeStreamPrompt(String prompt, String? systemPrompt) async* {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final request = GenerateRequest(prompt: prompt, systemPrompt: systemPrompt);
    final stream = provider.generateStream(request);

    String fullResponse = '';
    try {
      await for (final chunk in stream) {
        fullResponse += chunk.text;
        yield chunk.text;
      }
    } finally {
      dynamic parsedResponse = fullResponse;
      try {
        String cleaned = fullResponse.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'\s*```'), '').trim();
        int startIdx = cleaned.indexOf('{');
        if (startIdx == -1) startIdx = cleaned.indexOf('[');
        if (startIdx != -1) {
          int endIdx = cleaned.lastIndexOf('}');
          if (endIdx == -1 || cleaned.lastIndexOf(']') > endIdx) endIdx = cleaned.lastIndexOf(']');
          if (endIdx != -1 && endIdx >= startIdx) {
            parsedResponse = jsonDecode(cleaned.substring(startIdx, endIdx + 1));
          }
        }
      } catch (_) {}

      logger.logInteraction(
        {'prompt': prompt, 'systemPrompt': systemPrompt},
        {'response': parsedResponse},
        startTime,
      );
    }
  }

  T extractJson<T>(String rawText, String expectedType) {
    String cleaned = rawText.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'\s*```'), '').trim();
    
    int startIdx = expectedType == 'array' ? cleaned.indexOf('[') : cleaned.indexOf('{');
    int endIdx = expectedType == 'array' ? cleaned.lastIndexOf(']') : cleaned.lastIndexOf('}');
    
    if (startIdx == -1 || endIdx == -1 || endIdx < startIdx) {
      throw AIParsingError(name, cleaned);
    }

    cleaned = cleaned.substring(startIdx, endIdx + 1);

    try {
      return jsonDecode(cleaned) as T;
    } catch (e) {
      throw AIParsingError(name, '$e: $cleaned');
    }
  }
}
