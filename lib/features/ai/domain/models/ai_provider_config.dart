import 'dart:convert';

enum AIProviderType {
  geminiflow,
  ollama,
  vertexai
}

abstract class ProviderConfig {
  final String modelName;
  
  const ProviderConfig({required this.modelName});
  
  Map<String, dynamic> toJson();
}

class GeminiFlowConfig extends ProviderConfig {
  final String baseUrl;

  const GeminiFlowConfig({
    super.modelName = 'gemini-3.6-flash',
    this.baseUrl = 'http://127.0.0.1:8000',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'baseUrl': baseUrl,
      };

  factory GeminiFlowConfig.fromJson(Map<String, dynamic> json) {
    return GeminiFlowConfig(
      modelName: json['modelName'] ?? 'gemini-3.6-flash',
      baseUrl: json['baseUrl'] ?? 'http://127.0.0.1:8000',
    );
  }
  
  GeminiFlowConfig copyWith({String? modelName, String? baseUrl}) {
    return GeminiFlowConfig(
      modelName: modelName ?? this.modelName,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class OllamaConfig extends ProviderConfig {
  final String baseUrl;

  const OllamaConfig({
    super.modelName = 'llama3',
    this.baseUrl = 'http://localhost:11434',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'baseUrl': baseUrl,
      };

  factory OllamaConfig.fromJson(Map<String, dynamic> json) {
    return OllamaConfig(
      modelName: json['modelName'] ?? 'llama3',
      baseUrl: json['baseUrl'] ?? 'http://localhost:11434',
    );
  }
  
  OllamaConfig copyWith({String? modelName, String? baseUrl}) {
    return OllamaConfig(
      modelName: modelName ?? this.modelName,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class VertexAIConfig extends ProviderConfig {
  final String projectId;
  final String region;
  final String accessToken;

  const VertexAIConfig({
    super.modelName = 'gemini-1.5-pro-preview-0409',
    this.projectId = '',
    this.region = 'us-central1',
    this.accessToken = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'projectId': projectId,
        'region': region,
        'accessToken': accessToken,
      };

  factory VertexAIConfig.fromJson(Map<String, dynamic> json) {
    return VertexAIConfig(
      modelName: json['modelName'] ?? 'gemini-1.5-pro-preview-0409',
      projectId: json['projectId'] ?? '',
      region: json['region'] ?? 'us-central1',
      accessToken: json['accessToken'] ?? '',
    );
  }
  
  VertexAIConfig copyWith({
    String? modelName,
    String? projectId,
    String? region,
    String? accessToken,
  }) {
    return VertexAIConfig(
      modelName: modelName ?? this.modelName,
      projectId: projectId ?? this.projectId,
      region: region ?? this.region,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
