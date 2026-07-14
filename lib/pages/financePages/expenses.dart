import 'package:flutter/material.dart';
import '../../finance/expenses.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ExpensesComponent(),
      ),
    );
  }
}
