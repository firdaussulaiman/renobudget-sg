import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final itemController = TextEditingController();
  final categoryController = TextEditingController();
  final amountController = TextEditingController();

  void saveExpense() {
    final item = itemController.text;
    final category = categoryController.text;
    final amount = double.tryParse(amountController.text) ?? 0;

    Expense newExpense = Expense(
      item: item,
      category: category,
      amount: amount,
    );

    Navigator.pop(context, newExpense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: saveExpense,
              child: const Text("Save Expense"),
            ),
          ],
        ),
      ),
    );
  }
}
