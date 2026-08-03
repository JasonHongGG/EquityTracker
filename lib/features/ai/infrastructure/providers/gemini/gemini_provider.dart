import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/gemini/sdk/client.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/gemini/sdk/types.dart';

class GeminiProvider implements AIProvider {
  final GeminiClient _client;
  final String modelName;

  GeminiProvider({
    required String apiKey,
    this.modelName = 'gemini-2.5-flash',
  }) : _client = GeminiClient(apiKey);

  @override
  String get name => 'Gemini';

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    final payload = GeminiChatPayload(
      prompt: request.prompt,
      model: modelName,
      systemPrompt: request.systemPrompt,
    );

    final response = await _client.chat(payload);
    return GenerateResponse(text: response.text);
  }

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    final payload = GeminiChatPayload(
      prompt: request.prompt,
      model: modelName,
      systemPrompt: request.systemPrompt,
    );

    await for (final response in _client.stream(payload)) {
      yield GenerateResponse(text: response.text);
    }
  }
}
