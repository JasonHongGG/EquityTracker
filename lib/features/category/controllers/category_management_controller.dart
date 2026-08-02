import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryManagementState {
  final TransactionType selectedType;
  final bool isEditMode;

  CategoryManagementState({
    this.selectedType = TransactionType.expense,
    this.isEditMode = false,
  });

  CategoryManagementState copyWith({
    TransactionType? selectedType,
    bool? isEditMode,
  }) {
    return CategoryManagementState(
      selectedType: selectedType ?? this.selectedType,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }
}

class CategoryManagementController extends Notifier<CategoryManagementState> {
  @override
  CategoryManagementState build() {
    return CategoryManagementState();
  }

  void updateType(TransactionType type) {
    state = state.copyWith(selectedType: type);
  }

  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }
}

final categoryManagementControllerProvider = NotifierProvider<CategoryManagementController, CategoryManagementState>(
  CategoryManagementController.new,
);
