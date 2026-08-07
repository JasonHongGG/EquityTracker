import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/voice_command/domain/services/voice_command_service.dart';
import 'package:equity_tracker/features/voice_command/services/android_voice_command_service.dart';
import 'package:equity_tracker/features/voice_command/services/no_op_voice_command_service.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';

final voiceCommandServiceProvider = Provider<VoiceCommandService>((ref) {
  VoiceCommandService service;
  if (Platform.isAndroid) {
    service = AndroidVoiceCommandService();
  } else {
    service = NoOpVoiceCommandService();
  }
  
  service.initialize();
  ref.onDispose(() => service.dispose());
  
  return service;
});

final voiceCommandListenerProvider = Provider<void>((ref) {
  final service = ref.watch(voiceCommandServiceProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);

  service.onTransactionCommand.listen((command) async {
    final transaction = TransactionModel(
      type: TransactionType.expense, // Defaulting to expense
      amount: command.amount.toInt(),
      categoryId: command.category.isNotEmpty ? command.category : 'default', // Ideally map to category model ID
      date: command.date,
      createdAt: DateTime.now(),
      note: command.description,
      title: command.category,
    );
    
    await transactionRepository.insertTransaction(transaction);
  });
});
