import 'dart:async';
import 'package:equity_tracker/features/voice_command/domain/models/voice_command.dart';
import 'package:equity_tracker/features/voice_command/domain/services/voice_command_service.dart';

class NoOpVoiceCommandService implements VoiceCommandService {
  final _commandController = StreamController<CreateTransactionCommand>.broadcast();

  @override
  Stream<CreateTransactionCommand> get onTransactionCommand => _commandController.stream;

  @override
  void initialize() {
    // Do nothing on non-Android platforms
  }

  @override
  void dispose() {
    _commandController.close();
  }
}
