class CreateTransactionCommand {
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  CreateTransactionCommand({
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  factory CreateTransactionCommand.fromMap(Map<dynamic, dynamic> map) {
    return CreateTransactionCommand(
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null 
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
