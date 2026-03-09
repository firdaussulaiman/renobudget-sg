import 'package:flutter/material.dart';
import 'screens/add_expense.dart';
import 'models/expense.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
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

  double get spent {
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  double get remaining {
    return totalBudget - spent;
  }

  Future<void> goToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result != null && result is Expense) {
      setState(() {
        expenses.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RenoBudget SG")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("Total Budget"),
                subtitle: Text("SGD $totalBudget"),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text("Total Spent"),
                subtitle: Text("SGD $spent"),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text("Remaining Budget"),
                subtitle: Text("SGD $remaining"),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: goToAddExpense,
              child: const Text("Add Expense"),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];

                  return Card(
                    child: ListTile(
                      title: Text(expense.item),
                      subtitle: Text(expense.category),
                      trailing: Text("SGD ${expense.amount}"),
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
