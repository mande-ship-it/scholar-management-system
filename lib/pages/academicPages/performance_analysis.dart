import 'package:flutter/material.dart';
import '../../academics/performance_analysis.dart';
import '../../academics/academics_utils.dart';

class PerformanceAnalysisPage extends StatelessWidget {
  final SchoolType? forcedSchoolType;
  const PerformanceAnalysisPage({super.key, this.forcedSchoolType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: PerformanceAnalysisComponent(forcedSchoolType: forcedSchoolType),
      ),
    );
  }
}
