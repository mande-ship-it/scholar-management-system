import 'package:flutter/material.dart';
import '../../finance/financial_reports.dart';

class FinancialReportsPage extends StatelessWidget {
  const FinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: FinancialReportsComponent(),
      ),
    );
  }
}
