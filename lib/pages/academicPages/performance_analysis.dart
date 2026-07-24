import 'package:flutter/material.dart';
import '../../academics/performance_analysis.dart';

class PerformanceAnalysisPage extends StatelessWidget {
  const PerformanceAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: PerformanceAnalysisComponent(),
      ),
    );
  }
}
