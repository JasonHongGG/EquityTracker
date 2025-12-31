enum TransactionType {
  income,
  expense;

  String toJson() => name;
  static TransactionType fromJson(String json) => values.byName(json);
}
