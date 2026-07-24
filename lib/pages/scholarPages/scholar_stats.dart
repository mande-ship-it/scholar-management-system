import 'package:flutter/material.dart';
import '../../scholars/scholar_stats.dart';

class ScholarStatsPage extends StatelessWidget {
  const ScholarStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ScholarStatsComponent(),
      ),
    );
  }
}
