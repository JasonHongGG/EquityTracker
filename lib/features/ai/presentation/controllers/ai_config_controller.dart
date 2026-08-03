import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AIProviderType {
  gemini,
  ollama
}

class AIConfigState {
  final AIProviderType providerType;
  final String baseUrl;
  final String modelName;
  final String googleMapApiKey;

  AIConfigState({
    this.providerType = AIProviderType.gemini,
    this.baseUrl = 'http://127.0.0.1:8000',
    this.modelName = 'gemini-2.5-flash',
    this.googleMapApiKey = '',
  });

  AIConfigState copyWith({
    AIProviderType? providerType,
    String? baseUrl,
    String? modelName,
    String? googleMapApiKey,
  }) {
    return AIConfigState(
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      googleMapApiKey: googleMapApiKey ?? this.googleMapApiKey,
    );
  }
}

class AIConfigController extends Notifier<AIConfigState> {
  @override
  AIConfigState build() {
    _loadConfig();
    return AIConfigState();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString('ai_provider_type');
    final type = typeStr != null ? AIProviderType.values.byName(typeStr) : AIProviderType.gemini;
    final baseUrl = prefs.getString('ai_base_url') ?? 'http://127.0.0.1:8000';
    final modelName = prefs.getString('ai_model_name') ?? 'gemini-2.5-flash';
    final googleMapApiKey = prefs.getString('google_map_api_key') ?? '';

    state = AIConfigState(
      providerType: type,
      baseUrl: baseUrl,
      modelName: modelName,
      googleMapApiKey: googleMapApiKey,
    );
  }

  Future<void> saveConfig({
    required AIProviderType providerType,
    required String baseUrl,
    required String modelName,
    required String googleMapApiKey,
  }) async {
    state = state.copyWith(
      providerType: providerType,
      baseUrl: baseUrl,
      modelName: modelName,
      googleMapApiKey: googleMapApiKey,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_provider_type', providerType.index);
    await prefs.setString('ai_base_url', baseUrl.trim());
    await prefs.setString('ai_model_name', modelName.trim());
    await prefs.setString('google_map_api_key', googleMapApiKey.trim());
  }
}

final aiConfigControllerProvider = NotifierProvider<AIConfigController, AIConfigState>(
  AIConfigController.new,
);
