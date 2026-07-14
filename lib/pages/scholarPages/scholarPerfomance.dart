import 'package:flutter/material.dart';
import '../../scholars/scholarPerfomance.dart';

class ScholarPerformancePage extends StatelessWidget {
  const ScholarPerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ScholarPerformanceComponent(),
      ),
    );
  }
}
