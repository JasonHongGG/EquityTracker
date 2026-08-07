import 'dart:async';
import 'package:flutter/services.dart';
import 'package:equity_tracker/features/voice_command/domain/models/voice_command.dart';
import 'package:equity_tracker/features/voice_command/domain/services/voice_command_service.dart';

class AndroidVoiceCommandService implements VoiceCommandService {
  static const MethodChannel _channel = MethodChannel('com.equitytracker.voice/commands');
  final _commandController = StreamController<CreateTransactionCommand>.broadcast();

  @override
  Stream<CreateTransactionCommand> get onTransactionCommand => _commandController.stream;

  @override
  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'createTransaction') {
        final map = call.arguments as Map<dynamic, dynamic>;
        final command = CreateTransactionCommand.fromMap(map);
        _commandController.add(command);
      }
    });
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    _commandController.close();
  }
}
