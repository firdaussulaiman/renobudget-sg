import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'screens/add_expense.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const RenoBudgetApp());
}

class RenoBudgetApp extends StatelessWidget {
  const RenoBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RenoBudget SG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xffF5F7FB),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalBudget = 50000;

  List<Expense> expenses = [];

  int touchedIndex = -1;

  /// Renovation Timeline
  Map<String, bool> renovationTimeline = {
    "Hacking": false,
    "Plumbing": false,
    "Electrical": false,
    "Carpentry": false,
    "Painting": false,
    "Cleaning": false,
  };

  final List<Color> chartColors = [
    Colors.indigo,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    loadBudget();
    loadExpenses();
    loadTimeline();
  }

  double get totalSpent => expenses.fold(0, (sum, item) => sum + item.amount);

  double get remainingBudget => totalBudget - totalSpent;

  double get progress =>
      totalBudget == 0 ? 0 : (totalSpent / totalBudget).clamp(0, 1);

  /// SAVE BUDGET
  Future<void> saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalBudget', totalBudget);
  }

  /// LOAD BUDGET
  Future<void> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      totalBudget = prefs.getDouble('totalBudget') ?? 50000;
    });
  }

  /// SAVE EXPENSES
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    final data = expenses
        .map(
          (e) => jsonEncode({
            'item': e.item,
            'category': e.category,
            'amount': e.amount,
            'receiptPath': e.receiptPath,
          }),
        )
        .toList();

    await prefs.setStringList('expenses', data);
  }

  /// LOAD EXPENSES
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList('expenses');

    if (data != null) {
      setState(() {
        expenses = data.map((e) {
          final decoded = jsonDecode(e);

          return Expense(
            item: decoded['item'],
            category: decoded['category'],
            amount: decoded['amount'],
            receiptPath: decoded['receiptPath'],
          );
        }).toList();
      });
    }
  }

  /// SAVE TIMELINE
  Future<void> saveTimeline() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("timeline", jsonEncode(renovationTimeline));
  }

  /// LOAD TIMELINE
  Future<void> loadTimeline() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString("timeline");

    if (data != null) {
      setState(() {
        renovationTimeline = Map<String, bool>.from(jsonDecode(data));
      });
    }
  }

  /// ADD EXPENSE
  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });

    saveExpenses();
  }

  /// UPDATE EXPENSE
  void updateExpense(int index, Expense updatedExpense) {
    setState(() {
      expenses[index] = updatedExpense;
    });

    saveExpenses();
  }

  /// DELETE EXPENSE
  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });

    saveExpenses();
  }

  /// EDIT TOTAL BUDGET
  void editBudget() {
    final controller = TextEditingController(text: totalBudget.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Total Budget"),

          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Budget Amount"),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  totalBudget = double.tryParse(controller.text) ?? totalBudget;
                });

                saveBudget();

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Map<String, double> getCategoryTotals() {
    Map<String, double> data = {};

    for (var expense in expenses) {
      data[expense.category] = (data[expense.category] ?? 0) + expense.amount;
    }

    return data;
  }

  /// EXPORT PDF
  Future<void> exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "RenoBudget SG Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text("Total Budget: SGD ${totalBudget.toStringAsFixed(0)}"),
              pw.Text("Total Spent: SGD ${totalSpent.toStringAsFixed(0)}"),
              pw.Text(
                "Remaining Budget: SGD ${remainingBudget.toStringAsFixed(0)}",
              ),

              pw.SizedBox(height: 20),

              pw.Text("Expenses", style: pw.TextStyle(fontSize: 18)),

              pw.SizedBox(height: 10),

              ...expenses.map((e) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("${e.item} (${e.category})"),

                    pw.Text("SGD ${e.amount.toStringAsFixed(0)}"),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> openAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result != null && result is Expense) {
      addExpense(result);
    }
  }

  Future<void> openEditExpense(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddExpenseScreen(existingExpense: expenses[index]),
      ),
    );

    if (result != null && result is Expense) {
      updateExpense(index, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = getCategoryTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text("RenoBudget SG"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportPDF,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddExpense,
        child: const Icon(Icons.add),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              /// TOTAL BUDGET
              Card(
                child: ListTile(
                  title: const Text("Total Budget"),
                  subtitle: Text("SGD ${totalBudget.toStringAsFixed(0)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: editBudget,
                  ),
                ),
              ),

              /// TOTAL SPENT
              Card(
                child: ListTile(
                  title: const Text("Total Spent"),
                  subtitle: Text("SGD ${totalSpent.toStringAsFixed(0)}"),
                ),
              ),

              /// REMAINING
              Card(
                child: ListTile(
                  title: const Text("Remaining Budget"),
                  subtitle: Text("SGD ${remainingBudget.toStringAsFixed(0)}"),
                ),
              ),

              const SizedBox(height: 20),

              /// BUDGET PROGRESS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Budget Usage",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(value: progress, minHeight: 10),

                      const SizedBox(height: 6),

                      Text("${(progress * 100).toStringAsFixed(0)}% used"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// RENOVATION TIMELINE
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Renovation Timeline",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...renovationTimeline.keys.map((stage) {
                        return CheckboxListTile(
                          title: Text(stage),

                          value: renovationTimeline[stage],

                          onChanged: (value) {
                            setState(() {
                              renovationTimeline[stage] = value!;
                            });

                            saveTimeline();
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// PIE CHART
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: categoryData.isEmpty
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              "No expenses yet.\nTap + to add your first renovation item.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sections: categoryData.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final data = entry.value;

                                    final percentage = totalSpent == 0
                                        ? 0
                                        : (data.value / totalSpent * 100);

                                    return PieChartSectionData(
                                      color:
                                          chartColors[index %
                                              chartColors.length],
                                      value: data.value,
                                      title:
                                          "${percentage.toStringAsFixed(0)}%",
                                      radius: 70,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              /// EXPENSE LIST
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,

                itemBuilder: (context, index) {
                  final expense = expenses[index];

                  return Card(
                    child: Dismissible(
                      key: Key(expense.item + index.toString()),

                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),

                      onDismissed: (direction) {
                        deleteExpense(index);
                      },

                      child: ListTile(
                        title: Text(expense.item),

                        subtitle: Row(
                          children: [
                            Text(expense.category),

                            const SizedBox(width: 6),

                            if (expense.receiptPath != null)
                              const Icon(Icons.receipt, size: 16),
                          ],
                        ),

                        trailing: Text(
                          "SGD ${expense.amount.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        onTap: () {
                          openEditExpense(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
