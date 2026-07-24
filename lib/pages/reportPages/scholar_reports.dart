import 'package:flutter/material.dart';
import '../../reports/scholar_reports.dart';

class ScholarReportsPage extends StatelessWidget {
  const ScholarReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ScholarReportsComponent(),
      ),
    );
  }
}
