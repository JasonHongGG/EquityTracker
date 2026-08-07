import 'dart:async';
import 'package:equity_tracker/features/voice_command/domain/models/voice_command.dart';

abstract class VoiceCommandService {
  /// A stream of parsed CreateTransactionCommands coming from native side.
  Stream<CreateTransactionCommand> get onTransactionCommand;
  
  /// Initialize the listener
  void initialize();
  
  /// Cleanup resources
  void dispose();
}
