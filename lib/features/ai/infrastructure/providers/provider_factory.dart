import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/gemini/gemini_provider.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';

class ProviderFactory {
  static AIProvider createProvider(AIConfigState config) {
    switch (config.providerType) {
      case AIProviderType.gemini:
        if (config.apiKey.isEmpty) {
          throw Exception('Gemini API Key is empty. Please set it in Settings.');
        }
        return GeminiProvider(
          apiKey: config.apiKey,
          modelName: config.modelName,
        );
      case AIProviderType.ollama:
        throw UnimplementedError('Ollama Provider is not yet fully ported.');
    }
  }
}

final aiProviderProvider = Provider<AIProvider>((ref) {
  final config = ref.watch(aiConfigControllerProvider);
  return ProviderFactory.createProvider(config);
});
