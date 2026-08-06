import 'package:flutter/material.dart';
import '../../academics/performance_analysis.dart';
import '../../academics/academics_utils.dart';

class PerformanceAnalysisPage extends StatelessWidget {
  final SchoolType? forcedSchoolType;
  const PerformanceAnalysisPage({super.key, this.forcedSchoolType});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: PerformanceAnalysisComponent(forcedSchoolType: forcedSchoolType),
      ),
    );
  }
}
