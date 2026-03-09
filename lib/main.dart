import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/expense.dart';
import 'screens/add_expense.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('expensesBox');

  runApp(const RenoBudgetApp());
}

class RenoBudgetApp extends StatelessWidget {
  const RenoBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RenoBudget SG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', primarySwatch: Colors.indigo),
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
  final expenseBox = Hive.box('expensesBox');

  double totalBudget = 50000;

  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  void loadExpenses() {
    final data = expenseBox.get('expense_list', defaultValue: []);

    setState(() {
      expenses = (data as List)
          .map(
            (e) => Expense(
              item: e['item'],
              category: e['category'],
              amount: e['amount'],
            ),
          )
          .toList();
    });
  }

  void saveExpenses() {
    final data = expenses
        .map(
          (e) => {'item': e.item, 'category': e.category, 'amount': e.amount},
        )
        .toList();

    expenseBox.put('expense_list', data);
  }

  double get totalSpent => expenses.fold(0, (sum, item) => sum + item.amount);

  double get remainingBudget => totalBudget - totalSpent;

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

  Future<bool> confirmDelete() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Expense"),
            content: const Text(
              "Are you sure you want to delete this expense?",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
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
      appBar: AppBar(title: const Text("RenoBudget SG")),

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

              /// PIE CHART
              SizedBox(
                height: 220,
                child: categoryData.isEmpty
                    ? const Center(child: Text("No expenses yet"))
                    : PieChart(
                        PieChartData(
                          sections: categoryData.entries.map((entry) {
                            final percentage = (entry.value / totalSpent) * 100;

                            return PieChartSectionData(
                              value: entry.value,
                              title: "${percentage.toStringAsFixed(0)}%",
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
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

                  return Dismissible(
                    key: Key(expense.item + index.toString()),

                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    confirmDismiss: (direction) async {
                      return await confirmDelete();
                    },

                    onDismissed: (direction) {
                      deleteExpense(index);
                    },

                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),

                      child: ListTile(
                        title: Text(
                          expense.item,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: Text(expense.category),

                        trailing: Text(
                          "SGD ${expense.amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
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
