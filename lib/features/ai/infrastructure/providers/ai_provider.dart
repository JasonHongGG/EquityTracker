class GenerateRequest {
  final String prompt;
  final String? systemPrompt;

  GenerateRequest({
    required this.prompt,
    this.systemPrompt,
  });
}

class GenerateResponse {
  final String text;

  GenerateResponse({
    required this.text,
  });
}

abstract class AIProvider {
  String get name;
  Future<GenerateResponse> generate(GenerateRequest request);
  Stream<GenerateResponse> generateStream(GenerateRequest request);
}
