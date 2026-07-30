enum TransactionType {
  income,
  expense;

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}
