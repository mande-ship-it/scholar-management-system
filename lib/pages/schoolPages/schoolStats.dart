import 'package:flutter/material.dart';
import '../../schools/schoolStats.dart';

class SchoolStatsPage extends StatelessWidget {
  const SchoolStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SchoolStatsComponent(),
      ),
    );
  }
}
