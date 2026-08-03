import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/ai/domain/exceptions/ai_connection_error.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/gemini/sdk/types.dart';

class GeminiClient {
  final String apiKey;

  GeminiClient(this.apiKey);

  Future<GeminiChatResponse> chat(GeminiChatPayload payload) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/\${payload.model}:generateContent?key=\$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GeminiChatResponse.fromJson(data);
      } else {
        throw AIConnectionError('Gemini API', 'HTTP \${response.statusCode}: \${response.body}');
      }
    } catch (e) {
      if (e is AIConnectionError) rethrow;
      throw AIConnectionError('Gemini API', e.toString());
    }
  }

  Stream<GeminiChatResponse> stream(GeminiChatPayload payload) async* {
    // For simplicity, falling back to non-streaming
    final res = await chat(payload);
    yield res;
  }
}
