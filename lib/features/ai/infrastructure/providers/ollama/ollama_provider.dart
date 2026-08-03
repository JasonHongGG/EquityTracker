import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/domain/exceptions/ai_connection_error.dart';

class OllamaProvider implements AIProvider {
  @override
  final String name = 'ollama';
  
  final String _model;
  final String _baseUrl;

  OllamaProvider({
    required String modelName,
    required String baseUrl,
  })  : _model = modelName,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl/api/generate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': request.prompt,
          'system': request.systemPrompt,
          'stream': false,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ollama API error: ${response.statusCode}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return GenerateResponse(
        text: data['response'] ?? '',
      );
    } catch (e) {
      throw AIConnectionError(name, e.toString());
    }
  }

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    throw UnimplementedError('Streaming not fully ported. Please use generate().');
  }
}
