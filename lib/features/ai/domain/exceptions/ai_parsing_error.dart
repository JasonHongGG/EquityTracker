import 'package:equity_tracker/features/ai/domain/exceptions/base_exception.dart';

class AIParsingError extends BaseException {
  final String rawResponse;
  
  AIParsingError(String agentName, this.rawResponse)
      : super('\$agentName failed to parse AI response', 'AI_PARSE_ERR');
}
