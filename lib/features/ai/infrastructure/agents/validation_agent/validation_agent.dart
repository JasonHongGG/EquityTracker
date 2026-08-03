import 'package:equity_tracker/features/ai/domain/models/record_data.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/prompts.dart';

class ValidationInput {
  final RecordData record;

  ValidationInput({required this.record});
}

class ValidationResult {
  final bool isValid;
  final String? question;

  ValidationResult({
    required this.isValid,
    this.question,
  });

  factory ValidationResult.fromMap(Map<String, dynamic> map) {
    return ValidationResult(
      isValid: map['isValid'] as bool? ?? false,
      question: map['question'] as String?,
    );
  }
}

class ValidationAgent extends BaseAgent<ValidationInput, ValidationResult> {
  ValidationAgent(AIProvider provider) : super('Validation', provider);

  @override
  Future<ValidationResult> execute(ValidationInput input, {void Function(String)? onChunk}) async {
    final systemPrompt = buildSystemPrompt();
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);
    
    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }
    
    final map = extractJson<Map<String, dynamic>>(resultText, 'object');
    return ValidationResult.fromMap(map);
  }
}
