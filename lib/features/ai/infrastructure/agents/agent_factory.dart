import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/extraction_agent/extraction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/store_lookup_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/validation_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';

class AgentFactory {
  final Ref ref;

  AgentFactory(this.ref);

  ExtractionAgent createExtractionAgent() {
    final provider = ref.read(aiProviderProvider);
    return ExtractionAgent(provider);
  }

  StoreLookupAgent createStoreLookupAgent() {
    final provider = ref.read(aiProviderProvider);
    return StoreLookupAgent(provider);
  }

  ValidationAgent createValidationAgent() {
    final provider = ref.read(aiProviderProvider);
    return ValidationAgent(provider);
  }

  CorrectionAgent createCorrectionAgent() {
    final provider = ref.read(aiProviderProvider);
    return CorrectionAgent(provider);
  }
}

final agentFactoryProvider = Provider<AgentFactory>((ref) {
  return AgentFactory(ref);
});
