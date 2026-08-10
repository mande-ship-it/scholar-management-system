import 'package:flutter/material.dart';
import '../../academics/performance_analysis.dart';
import '../../academics/academics_utils.dart';

class PerformanceAnalysisPage extends StatelessWidget {
  final SchoolType? forcedSchoolType;
  final VoidCallback? onBack;
  const PerformanceAnalysisPage({super.key, this.forcedSchoolType, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PerformanceAnalysisComponent(forcedSchoolType: forcedSchoolType, onBack: onBack);
  }
}
