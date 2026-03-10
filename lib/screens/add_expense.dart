import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  final bool isProUser;

  const AddExpenseScreen({
    super.key,
    this.existingExpense,
    required this.isProUser,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final itemController = TextEditingController();
  final amountController = TextEditingController();

  String selectedCategory = "Carpentry";

  Uint8List? receiptBytes;
  String? receiptLabel;

  final picker = ImagePicker();

  final List<String> categories = [
    "Carpentry",
    "Electrical",
    "Flooring",
    "Painting",
    "Plumbing",
    "Lighting",
    "Furniture",
    "Appliances",
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existingExpense != null) {
      itemController.text = widget.existingExpense!.item;
      amountController.text = widget.existingExpense!.amount.toString();
      selectedCategory = widget.existingExpense!.category;
      receiptLabel = widget.existingExpense!.receiptPath;
    }
  }

  void showProDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("RenoBudget Pro"),
          content: const Text(
            "Receipt photo upload is a Pro feature.\n\n"
            "Planned one-time purchase: \$2.99",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickImage() async {
    if (!widget.isProUser) {
      showProDialog();
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        receiptBytes = bytes;
        receiptLabel = pickedFile.name;
      });
    }
  }

  void saveExpense() {
    final item = itemController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;

    if (item.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid expense details")),
      );
      return;
    }

    final expense = Expense(
      item: item,
      category: selectedCategory,
      amount: amount,
      receiptPath: receiptLabel,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Expense" : "Add Expense")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Amount (SGD)",
                  prefixText: "SGD ",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(
                    widget.isProUser
                        ? "Add Receipt Photo"
                        : "Add Receipt Photo (Pro)",
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (receiptBytes != null)
                Column(
                  children: [
                    const Text("Receipt Preview"),
                    const SizedBox(height: 10),
                    Image.memory(receiptBytes!, height: 140),
                  ],
                )
              else if (receiptLabel != null)
                Text(
                  "Receipt attached: $receiptLabel",
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saveExpense,
                  child: Text(
                    isEditing ? "Update Expense" : "Save Expense",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
