class Expense {
  final String item;
  final String category;
  final double amount;

  Expense({required this.item, required this.category, required this.amount});

  Map<String, dynamic> toJson() {
    return {'item': item, 'category': category, 'amount': amount};
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      item: json['item'],
      category: json['category'],
      amount: json['amount'].toDouble(),
    );
  }
}
