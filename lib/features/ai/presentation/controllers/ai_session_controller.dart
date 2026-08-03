import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_session.dart';
import 'package:equity_tracker/features/ai/usecases/process_expense_usecase.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class AISessionState {
  final TransactionSession? session;
  final List<String> logs;
  final bool isProcessing;
  final UseCaseResult? pendingAction;

  AISessionState({
    this.session,
    this.logs = const [],
    this.isProcessing = false,
    this.pendingAction,
  });

  AISessionState copyWith({
    TransactionSession? session,
    List<String>? logs,
    bool? isProcessing,
    UseCaseResult? pendingAction,
    bool clearPendingAction = false,
  }) {
    return AISessionState(
      session: session ?? this.session,
      logs: logs ?? this.logs,
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

  void _addLog(String msg) {
    state = state.copyWith(logs: [...state.logs, msg]);
  }

  Future<void> startSession(String input) async {
    final session = TransactionSession(input);
    state = AISessionState(session: session, isProcessing: true);

    try {
      final useCase = ref.read(processExpenseUseCaseProvider);
      final result = await useCase.execute(session, onProgress: _addLog);
      
      _handleResult(result);
    } catch (e, st) {
      _addLog('❌ 發生錯誤: \$e');
      state = state.copyWith(isProcessing: false);
      print(st);
    }
  }

  Future<void> submitAnswer(String answer) async {
    if (state.pendingAction == null || state.session == null) return;

    final action = state.pendingAction!;
    state = state.copyWith(isProcessing: true, clearPendingAction: true);
    _addLog('回答: \$answer');

    try {
      final useCase = ref.read(processExpenseUseCaseProvider);
      int recordIndex = 0;
      
      if (action is RequireStoreSelectionResult) {
        recordIndex = action.recordIndex;
      } else if (action is RequireCorrectionResult) {
        recordIndex = action.recordIndex;
      }

      final result = await useCase.handleUserCorrection(
        state.session!, 
        recordIndex, 
        answer,
        onProgress: _addLog
      );
      
      _handleResult(result);
    } catch (e, st) {
      _addLog('❌ 發生錯誤: \$e');
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
      _addLog('❌ 沒有可儲存的紀錄。');
      return;
    }

    _addLog('💾 正在儲存 \${session.records.length} 筆資料...');
    final transactionNotifier = ref.read(transactionNotifierProvider.notifier);
    
    int savedCount = 0;
    for (final record in session.records) {
      final data = record.data;
      if (data.price == null || data.item == null) continue; // Safety check

      final noteSuffix = data.store ?? data.locationClue ?? 'Auto-generated';
      final tx = TransactionModel(
        title: data.item!,
        amount: data.price!,
        categoryId: 'other', // Default category
        type: TransactionType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        note: 'AI: \$noteSuffix',
      );
      
      await transactionNotifier.addTransaction(tx);
      savedCount++;
    }

    _addLog('🎉 成功新增 \$savedCount 筆帳務！');
  }
}

final aiSessionControllerProvider = NotifierProvider<AISessionController, AISessionState>(
  AISessionController.new,
);
