import 'package:flutter/material.dart';
import '../../reports/schoolReports.dart';

class SchoolReportsPage extends StatelessWidget {
  const SchoolReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SchoolReportsComponent(),
      ),
    );
  }
}
