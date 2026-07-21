import 'package:flutter/material.dart';
import '../../academics/academicStats.dart';

class AcademicStatsPage extends StatelessWidget {
  const AcademicStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: AcademicStatsComponent(),
      ),
    );
  }
}
