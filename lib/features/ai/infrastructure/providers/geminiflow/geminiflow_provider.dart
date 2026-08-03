import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/geminiflow/sdk/client.dart';
import 'package:equity_tracker/features/ai/domain/exceptions/ai_connection_error.dart';

class GeminiFlowProvider implements AIProvider {
  @override
  final String name = 'geminiflow';
  
  final GeminiFlowClient _client;
  final String _model;

  GeminiFlowProvider({
    required String modelName,
    required String baseUrl,
  })  : _model = modelName,
        _client = GeminiFlowClient(baseUrl: baseUrl);

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    try {
      final response = await _client.chat(
        prompt: request.prompt,
        systemPrompt: request.systemPrompt,
        model: _model,
        language: 'zh-TW',
        saveImages: false,
      );

      return GenerateResponse(
        text: response.text,
      );
    } catch (e) {
      throw AIConnectionError(name, e.toString());
    }
  }

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    try {
      final stream = _client.stream(
        prompt: request.prompt,
        systemPrompt: request.systemPrompt,
        model: _model,
        language: 'zh-TW',
        saveImages: false,
      );

      await for (final chunk in stream) {
        yield GenerateResponse(text: chunk.text);
      }
    } on UnimplementedError {
      rethrow;
    } catch (e) {
      throw AIConnectionError(name, e.toString());
    }
  }
}
