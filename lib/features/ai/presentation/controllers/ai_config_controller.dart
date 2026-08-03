import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/features/ai/domain/models/ai_provider_config.dart';

import 'package:equity_tracker/core/providers/shared_prefs_provider.dart';

class AIConfigState {
  final AIProviderType providerType;
  final Map<AIProviderType, ProviderConfig> configs;
  final String googleMapApiKey;

  AIConfigState({
    this.providerType = AIProviderType.geminiflow,
    Map<AIProviderType, ProviderConfig>? configs,
    this.googleMapApiKey = '',
  }) : configs = configs ?? {
         AIProviderType.geminiflow: const GeminiFlowConfig(),
         AIProviderType.ollama: const OllamaConfig(),
         AIProviderType.vertexai: const VertexAIConfig(),
       };

  ProviderConfig get activeConfig => configs[providerType]!;

  AIConfigState copyWith({
    AIProviderType? providerType,
    Map<AIProviderType, ProviderConfig>? configs,
    String? googleMapApiKey,
  }) {
    return AIConfigState(
      providerType: providerType ?? this.providerType,
      configs: configs ?? this.configs,
      googleMapApiKey: googleMapApiKey ?? this.googleMapApiKey,
    );
  }
}

class AIConfigController extends Notifier<AIConfigState> {
  @override
  AIConfigState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    final typeStr = prefs.getString('ai_provider_type');
    final type = typeStr != null ? AIProviderType.values.byName(typeStr) : AIProviderType.geminiflow;
    
    final Map<AIProviderType, ProviderConfig> loadedConfigs = {
      AIProviderType.geminiflow: const GeminiFlowConfig(),
      AIProviderType.ollama: const OllamaConfig(),
      AIProviderType.vertexai: const VertexAIConfig(),
    };

    final geminiflowJson = prefs.getString('ai_config_geminiflow');
    if (geminiflowJson != null) loadedConfigs[AIProviderType.geminiflow] = GeminiFlowConfig.fromJson(jsonDecode(geminiflowJson));

    final ollamaJson = prefs.getString('ai_config_ollama');
    if (ollamaJson != null) loadedConfigs[AIProviderType.ollama] = OllamaConfig.fromJson(jsonDecode(ollamaJson));

    final vertexaiJson = prefs.getString('ai_config_vertexai');
    if (vertexaiJson != null) loadedConfigs[AIProviderType.vertexai] = VertexAIConfig.fromJson(jsonDecode(vertexaiJson));

    final googleMapApiKey = prefs.getString('google_map_api_key') ?? '';

    return AIConfigState(
      providerType: type,
      configs: loadedConfigs,
      googleMapApiKey: googleMapApiKey,
    );
  }

  Future<void> saveConfig({
    AIProviderType? providerType,
    ProviderConfig? activeProviderConfig,
    String? googleMapApiKey,
  }) async {
    final newConfigs = Map<AIProviderType, ProviderConfig>.from(state.configs);
    
    if (activeProviderConfig != null) {
      newConfigs[providerType ?? state.providerType] = activeProviderConfig;
    }

    state = state.copyWith(
      providerType: providerType,
      configs: newConfigs,
      googleMapApiKey: googleMapApiKey,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider_type', state.providerType.name);
    
    await prefs.setString('ai_config_geminiflow', jsonEncode(state.configs[AIProviderType.geminiflow]!.toJson()));
    await prefs.setString('ai_config_ollama', jsonEncode(state.configs[AIProviderType.ollama]!.toJson()));
    await prefs.setString('ai_config_vertexai', jsonEncode(state.configs[AIProviderType.vertexai]!.toJson()));
    
    if (googleMapApiKey != null) {
      await prefs.setString('google_map_api_key', googleMapApiKey.trim());
    }
  }
}

final aiConfigControllerProvider = NotifierProvider<AIConfigController, AIConfigState>(
  AIConfigController.new,
);
