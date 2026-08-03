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
    String model = 'gemini-3.6-flash',
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

  // Processes Server-Sent Events (SSE) stream using http.Request and Stream transformers
  Stream<GeminiFlowStreamData> stream({
    required String prompt,
    String? systemPrompt,
    String model = 'gemini-3.6-flash',
    String language = 'zh-TW',
    List<String>? images,
    String? sessionId,
    bool saveImages = true,
  }) async* {
    final payload = GeminiFlowChatPayload(
      prompt: prompt,
      model: model,
      language: language,
      saveImages: saveImages,
      systemPrompt: systemPrompt,
      images: images,
      sessionId: sessionId,
    );

    final url = Uri.parse('$_baseUrl/stream');
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(payload.toJson());

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errorText = await response.stream.bytesToString();
        throw Exception('Stream failed: ${response.statusCode} - $errorText');
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith("event:")) continue;
        
        if (trimmed.startsWith("data:")) {
          final dataStr = trimmed.substring(5).trim();
          try {
            final data = jsonDecode(dataStr);
            // Handle variations in text field name based on typical SSE backends
            final textContent = data['text'] ?? data['chunk'] ?? data['response'] ?? data['content'] ?? '';
            
            yield GeminiFlowStreamData(
              text: textContent,
              images: data['images'] != null ? List<String>.from(data['images']) : null,
            );
          } catch (e) {
            // ignore JSON parse error for incomplete chunks if any
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
