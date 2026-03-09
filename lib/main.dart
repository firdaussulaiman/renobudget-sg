import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'screens/add_expense.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        fontFamily: 'Roboto',
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
    loadExpenses();
  }

  double get totalSpent => expenses.fold(0, (sum, item) => sum + item.amount);

  double get remainingBudget => totalBudget - totalSpent;

  double get progress =>
      totalBudget == 0 ? 0 : (totalSpent / totalBudget).clamp(0, 1);

  /// SAVE EXPENSES
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    final data = expenses
        .map(
          (e) => jsonEncode({
            'item': e.item,
            'category': e.category,
            'amount': e.amount,
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
          );
        }).toList();
      });
    }
  }

  /// EDIT BUDGET
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
            decoration: const InputDecoration(labelText: "Budget (SGD)"),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  totalBudget = double.tryParse(controller.text) ?? totalBudget;
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });

    saveExpenses();
  }

  void updateExpense(int index, Expense updatedExpense) {
    setState(() {
      expenses[index] = updatedExpense;
    });

    saveExpenses();
  }

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });

    saveExpenses();
  }

  Map<String, double> getCategoryTotals() {
    Map<String, double> data = {};

    for (var expense in expenses) {
      data[expense.category] = (data[expense.category] ?? 0) + expense.amount;
    }

    return data;
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
      appBar: AppBar(title: const Text("RenoBudget SG"), elevation: 0),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddExpense,
        child: const Icon(Icons.add),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              /// BUDGET CARDS
              Card(
                child: ListTile(
                  title: const Text("Total Budget"),
                  subtitle: Text("SGD ${totalBudget.toStringAsFixed(0)}"),
                  trailing: const Icon(Icons.edit),
                  onTap: editBudget,
                ),
              ),

              Card(
                child: ListTile(
                  title: const Text("Total Spent"),
                  subtitle: Text("SGD ${totalSpent.toStringAsFixed(0)}"),
                ),
              ),

              Card(
                child: ListTile(
                  title: const Text("Remaining Budget"),
                  subtitle: Text("SGD ${remainingBudget.toStringAsFixed(0)}"),
                ),
              ),

              const SizedBox(height: 20),

              /// PROGRESS BAR
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

              /// PIE CHART
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,

                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }

                                  touchedIndex = response
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                            ),

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

                                  final isTouched = index == touchedIndex;

                                  return PieChartSectionData(
                                    color:
                                        chartColors[index % chartColors.length],
                                    value: data.value,
                                    title: "${percentage.toStringAsFixed(0)}%",
                                    radius: isTouched ? 80 : 70,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LEGEND
                      Column(
                        children: categoryData.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final data = entry.value;

                              return Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color:
                                        chartColors[index % chartColors.length],
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    "${data.key} - SGD ${data.value.toStringAsFixed(0)}",
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ),
                    ],
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
                        subtitle: Text(expense.category),

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
