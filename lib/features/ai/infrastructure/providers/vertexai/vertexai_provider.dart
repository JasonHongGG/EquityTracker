import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/domain/exceptions/ai_connection_error.dart';

class VertexAIProvider implements AIProvider {
  @override
  final String name = 'vertexai';
  
  final String _model;
  final String _projectId;
  final String _region;
  final String _accessToken;

  VertexAIProvider({
    required String modelName,
    required String projectId,
    required String region,
    required String accessToken,
  })  : _model = modelName,
        _projectId = projectId,
        _region = region,
        _accessToken = accessToken;

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    try {
      final url = Uri.parse(
          'https://$_region-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_region/publishers/google/models/$_model:generateContent');
      
      final contents = [
        {
          'role': 'user',
          'parts': [{'text': request.prompt}]
        }
      ];

      final Map<String, dynamic> body = {
        'contents': contents,
      };

      if (request.systemPrompt != null && request.systemPrompt!.isNotEmpty) {
        body['systemInstruction'] = {
          'role': 'system',
          'parts': [{'text': request.systemPrompt}]
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Vertex AI API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      String text = '';
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final content = data['candidates'][0]['content'];
        if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'] ?? '';
        }
      }

      return GenerateResponse(
        text: text,
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
