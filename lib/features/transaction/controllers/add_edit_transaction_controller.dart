import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class AddEditTransactionState {
  final TransactionType type;
  final DateTime date;
  final int amount;
  final String title;
  final String note;
  final String? categoryId;
  final bool isSaving;
  final String? error;

  AddEditTransactionState({
    required this.type,
    required this.date,
    this.amount = 0,
    this.title = '',
    this.note = '',
    this.categoryId,
    this.isSaving = false,
    this.error,
  });

  AddEditTransactionState copyWith({
    TransactionType? type,
    DateTime? date,
    int? amount,
    String? title,
    String? note,
    String? categoryId,
    bool? isSaving,
    String? error,
  }) {
    return AddEditTransactionState(
      type: type ?? this.type,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class AddEditTransactionController extends Notifier<AddEditTransactionState> {
  TransactionModel? _transaction;

  @override
  AddEditTransactionState build() {
    return AddEditTransactionState(
      type: TransactionType.expense,
      date: DateTime.now(),
    );
  }

  void init(TransactionModel? transaction, DateTime? initialDate) {
    _transaction = transaction;
    if (transaction != null) {
      state = AddEditTransactionState(
        type: transaction.type,
        date: transaction.date,
        amount: transaction.amount,
        title: transaction.title ?? '',
        note: transaction.note ?? '',
        categoryId: transaction.categoryId,
      );
    } else if (initialDate != null) {
      final now = DateTime.now();
      state = state.copyWith(
        date: DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
          now.hour,
          now.minute,
          now.second,
        ),
      );
    } else {
      state = AddEditTransactionState(
        type: TransactionType.expense,
        date: DateTime.now(),
      );
    }
  }

  void updateType(TransactionType type) {
    state = state.copyWith(type: type, categoryId: null); // Reset category on type change
  }

  void updateDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void updateAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  void updateCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  // Returns true if save was successful
  Future<bool> saveTransaction({
    required String titleText,
    required String amountText,
    required String noteText,
  }) async {
    final parsed = int.tryParse(amountText);
    if (parsed == null || parsed <= 0) {
      state = state.copyWith(error: 'Amount must be > 0');
      return false;
    }
    if (state.categoryId == null) {
      state = state.copyWith(error: 'Please select a category');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    final newTx = TransactionModel(
      id: _transaction?.id,
      notionId: _transaction?.notionId,
      title: titleText.isNotEmpty ? titleText : null,
      type: state.type,
      amount: parsed,
      categoryId: state.categoryId!,
      date: state.date,
      createdAt: _transaction?.createdAt ?? DateTime.now(),
      note: noteText,
    );

    try {
      if (_transaction == null) {
        await ref.read(transactionListProvider.notifier).addTransaction(newTx);
      } else {
        await ref.read(transactionListProvider.notifier).updateTransaction(newTx);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<void> deleteTransaction() async {
    if (_transaction?.id != null) {
      await ref.read(transactionListProvider.notifier).deleteTransaction(_transaction!.id!, _transaction!.notionId);
    }
  }
}

final addEditTransactionControllerProvider = NotifierProvider<AddEditTransactionController, AddEditTransactionState>(
  AddEditTransactionController.new,
);
