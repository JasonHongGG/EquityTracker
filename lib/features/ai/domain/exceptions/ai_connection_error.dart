import 'package:equity_tracker/features/ai/domain/exceptions/base_exception.dart';

class AIConnectionError extends BaseException {
  AIConnectionError(String provider, String details)
      : super('Failed to connect to $provider: $details', 'AI_CONN_ERR');
}
