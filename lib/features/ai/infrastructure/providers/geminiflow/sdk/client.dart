import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/ai/infrastructure/providers/geminiflow/sdk/types.dart';

class GeminiFlowClient {
  late final String _baseUrl;

  GeminiFlowClient({String baseUrl = 'http://127.0.0.1:8000'}) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }

  Future<GeminiFlowChatResponse> chat({
    required String prompt,
    String? systemPrompt,
    String model = 'gemini-2.5-flash',
    String language = 'zh-TW',
    List<String>? images,
    String? sessionId,
    bool saveImages = true,
  }) async {
    final payload = GeminiFlowChatPayload(
      prompt: prompt,
      model: model,
      language: language,
      saveImages: saveImages,
      systemPrompt: systemPrompt,
      images: images,
      sessionId: sessionId,
    );

    final url = Uri.parse('$_baseUrl/chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return GeminiFlowChatResponse.fromJson(data);
  }

  // NOTE: Dart's http package stream parsing can be complex for SSE, 
  // but since we only need the unary `chat` call for our current Agents (execute),
  // we leave the stream implementation abstract or basic.
  Stream<GeminiFlowStreamData> stream({
    required String prompt,
    String? systemPrompt,
    String model = 'gemini-2.5-flash',
    String language = 'zh-TW',
    List<String>? images,
    String? sessionId,
    bool saveImages = true,
  }) async* {
    throw UnimplementedError('Streaming is not fully ported to Dart yet. Please use chat().');
  }
}
