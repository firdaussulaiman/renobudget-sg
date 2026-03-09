class Expense {
  final String item;
  final String category;
  final double amount;
  final String? receiptPath;

  Expense({
    required this.item,
    required this.category,
    required this.amount,
    this.receiptPath,
  });
}
