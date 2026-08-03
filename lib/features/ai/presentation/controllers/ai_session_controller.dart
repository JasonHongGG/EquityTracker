import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_session.dart';
import 'package:equity_tracker/features/ai/usecases/process_expense_usecase.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';

enum ChatMessageType { user, ai, system, error }

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AISessionState {
  final TransactionSession? session;
  final List<ChatMessage> messages;
  final bool isProcessing;
  final UseCaseResult? pendingAction;

  AISessionState({
    this.session,
    this.messages = const [],
    this.isProcessing = false,
    this.pendingAction,
  });

  AISessionState copyWith({
    TransactionSession? session,
    List<ChatMessage>? messages,
    bool? isProcessing,
    UseCaseResult? pendingAction,
    bool clearPendingAction = false,
  }) {
    return AISessionState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingAction: clearPendingAction ? null : (pendingAction ?? this.pendingAction),
    );
  }
}

class AISessionController extends Notifier<AISessionState> {
  @override
  AISessionState build() {
    return AISessionState();
  }

  void _addMessage(String text, ChatMessageType type) {
    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      type: type,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void _addProgress(String msg) {
    _addMessage(msg, ChatMessageType.system);
  }

  Future<void> startSession(String input) async {
    _addMessage(input, ChatMessageType.user);
    
    final session = TransactionSession(input);
    state = state.copyWith(session: session, isProcessing: true);

    try {
      final useCase = ref.read(processExpenseUseCaseProvider);
      final categories = ref.read(categoryListProvider).value ?? [];
      final result = await useCase.execute(session, categories, onProgress: _addProgress);
      
      _handleResult(result);
    } catch (e, st) {
      _addMessage('發生錯誤: $e', ChatMessageType.error);
      state = state.copyWith(isProcessing: false);
      print(st);
    }
  }

  Future<void> submitAnswer(String answer) async {
    if (state.pendingAction == null || state.session == null) return;

    final action = state.pendingAction!;
    state = state.copyWith(isProcessing: true, clearPendingAction: true);
    _addMessage(answer, ChatMessageType.user);

    try {
      final useCase = ref.read(processExpenseUseCaseProvider);
      int recordIndex = 0;
      
      if (action is RequireStoreSelectionResult) {
        recordIndex = action.recordIndex;
      } else if (action is RequireCorrectionResult) {
        recordIndex = action.recordIndex;
      }

      final categories = ref.read(categoryListProvider).value ?? [];
      final result = await useCase.handleUserCorrection(
        state.session!, 
        recordIndex, 
        answer,
        categories,
        onProgress: _addProgress
      );
      
      _handleResult(result);
    } catch (e, st) {
      _addMessage('發生錯誤: $e', ChatMessageType.error);
      state = state.copyWith(isProcessing: false);
      print(st);
    }
  }

  Future<void> _handleResult(UseCaseResult result) async {
    if (result is SuccessResult) {
      await _saveRecordsToDatabase();
      state = state.copyWith(isProcessing: false, clearPendingAction: true);
    } else {
      state = state.copyWith(
        isProcessing: false,
        pendingAction: result,
      );
    }
  }

  Future<void> _saveRecordsToDatabase() async {
    final session = state.session;
    if (session == null || session.records.isEmpty) {
      _addMessage('沒有可儲存的紀錄。', ChatMessageType.error);
      return;
    }

    _addProgress('正在儲存 ${session.records.length} 筆資料...');
    final transactionNotifier = ref.read(transactionNotifierProvider.notifier);
    
    int savedCount = 0;
    for (final record in session.records) {
      final data = record.data;
      if (data.price == null || data.item == null) continue;

      final title = (data.store != null && data.store!.isNotEmpty) ? data.store! : data.item!;
      final note = data.item!;
      
      final tx = TransactionModel(
        title: title,
        amount: data.price!,
        categoryId: data.categoryId ?? 'other',
        type: TransactionType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        note: note,
      );
      
      await transactionNotifier.addTransaction(tx);
      savedCount++;
    }

    _addMessage('成功新增 $savedCount 筆帳務！', ChatMessageType.ai);
  }
}

final aiSessionControllerProvider = NotifierProvider<AISessionController, AISessionState>(
  AISessionController.new,
);
