import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'screens/add_expense.dart';
import 'package:fl_chart/fl_chart.dart';

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
  double totalBudget = 50000;

  List<Expense> expenses = [];

  double get totalSpent => expenses.fold(0, (sum, item) => sum + item.amount);

  double get remainingBudget => totalBudget - totalSpent;

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
  }

  void updateExpense(int index, Expense updatedExpense) {
    setState(() {
      expenses[index] = updatedExpense;
    });
  }

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
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

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// TOTAL BUDGET
            Card(
              child: ListTile(
                title: const Text("Total Budget"),
                subtitle: Text("SGD ${totalBudget.toStringAsFixed(0)}"),
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

            /// PIE CHART
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categoryData.entries.map((entry) {
                    final percentage = (entry.value / totalSpent * 100)
                        .toStringAsFixed(0);

                    return PieChartSectionData(
                      value: entry.value,
                      title: "$percentage%",
                      radius: 70,
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// EXPENSE LIST
            Expanded(
              child: ListView.builder(
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

                    onDismissed: (direction) {
                      deleteExpense(index);
                    },

                    child: Card(
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
            ),
          ],
        ),
      ),
    );
  }
}
