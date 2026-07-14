import 'package:flutter/material.dart';
import '../../finance/budget.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: BudgetComponent(),
      ),
    );
  }
}
