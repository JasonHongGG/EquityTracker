import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AIProviderType {
  gemini,
  ollama
}

class AIConfigState {
  final AIProviderType providerType;
  final String apiKey;
  final String modelName;
  final String googleMapApiKey;

  AIConfigState({
    this.providerType = AIProviderType.gemini,
    this.apiKey = '',
    this.modelName = 'gemini-2.5-flash',
    this.googleMapApiKey = '',
  });

  AIConfigState copyWith({
    AIProviderType? providerType,
    String? apiKey,
    String? modelName,
    String? googleMapApiKey,
  }) {
    return AIConfigState(
      providerType: providerType ?? this.providerType,
      apiKey: apiKey ?? this.apiKey,
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
    final providerIdx = prefs.getInt('ai_provider_type') ?? 0;
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final modelName = prefs.getString('ai_model_name') ?? 'gemini-2.5-flash';
    final googleMapApiKey = prefs.getString('ai_google_map_key') ?? '';
    
    state = state.copyWith(
      providerType: AIProviderType.values[providerIdx],
      apiKey: apiKey,
      modelName: modelName,
      googleMapApiKey: googleMapApiKey,
    );
  }

  Future<void> saveConfig({
    required AIProviderType providerType,
    required String apiKey,
    required String modelName,
    required String googleMapApiKey,
  }) async {
    state = state.copyWith(
      providerType: providerType,
      apiKey: apiKey,
      modelName: modelName,
      googleMapApiKey: googleMapApiKey,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_provider_type', providerType.index);
    await prefs.setString('ai_api_key', apiKey.trim());
    await prefs.setString('ai_model_name', modelName.trim());
    await prefs.setString('ai_google_map_key', googleMapApiKey.trim());
  }
}

final aiConfigControllerProvider = NotifierProvider<AIConfigController, AIConfigState>(
  AIConfigController.new,
);
