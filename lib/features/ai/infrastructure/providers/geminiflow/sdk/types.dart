class GeminiFlowChatPayload {
  final String prompt;
  final String model;
  final String language;
  final bool saveImages;
  final String? systemPrompt;
  final List<String>? images;
  final String? sessionId;

  GeminiFlowChatPayload({
    required this.prompt,
    required this.model,
    required this.language,
    required this.saveImages,
    this.systemPrompt,
    this.images,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'prompt': prompt,
      'model': model,
      'language': language,
      'save_images': saveImages,
    };
    if (systemPrompt != null) {
      data['system_prompt'] = systemPrompt;
    }
    if (images != null && images!.isNotEmpty) {
      data['images'] = images;
    }
    if (sessionId != null) {
      data['session_id'] = sessionId;
    }
    return data;
  }
}

class GeminiFlowChatResponse {
  final String text;
  final List<String>? images;

  GeminiFlowChatResponse({
    required this.text,
    this.images,
  });

  factory GeminiFlowChatResponse.fromJson(Map<String, dynamic> json) {
    return GeminiFlowChatResponse(
      text: json['text'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }
}

class GeminiFlowStreamData {
  final String text;
  final List<String>? images;

  GeminiFlowStreamData({
    required this.text,
    this.images,
  });

  factory GeminiFlowStreamData.fromJson(Map<String, dynamic> json) {
    return GeminiFlowStreamData(
      text: json['text'] ?? json['chunk'] ?? json['response'] ?? json['content'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }
}
