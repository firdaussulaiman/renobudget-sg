import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final itemController = TextEditingController();
  final amountController = TextEditingController();

  String selectedCategory = "Carpentry";

  File? receiptImage;

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

      if (widget.existingExpense!.receiptPath != null) {
        receiptImage = File(widget.existingExpense!.receiptPath!);
      }
    }
  }

  /// PICK IMAGE
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        receiptImage = File(pickedFile.path);
      });
    }
  }

  /// SAVE EXPENSE
  void saveExpense() {
    final item = itemController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;

    if (item.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid expense details")),
      );
      return;
    }

    Expense expense = Expense(
      item: item,
      category: selectedCategory,
      amount: amount,
      receiptPath: receiptImage?.path,
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
              /// ITEM NAME
              TextField(
                controller: itemController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// CATEGORY
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
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

              /// AMOUNT
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

              /// RECEIPT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text("Add Receipt Photo"),
                ),
              ),

              const SizedBox(height: 10),

              /// IMAGE PREVIEW
              if (receiptImage != null)
                Column(
                  children: [
                    const Text("Receipt Preview"),
                    const SizedBox(height: 10),
                    Image.file(receiptImage!, height: 140),
                  ],
                ),

              const SizedBox(height: 30),

              /// SAVE BUTTON
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
