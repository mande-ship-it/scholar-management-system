import 'package:flutter/material.dart';
import '../../academics/performance_analysis.dart';
import '../../academics/academics_utils.dart';

class PerformanceAnalysisPage extends StatelessWidget {
  final SchoolType? forcedSchoolType;
  final String? scholarId;
  final VoidCallback? onBack;
  final bool showBackButton;
  const PerformanceAnalysisPage({super.key, this.forcedSchoolType, this.scholarId, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return PerformanceAnalysisComponent(forcedSchoolType: forcedSchoolType, scholarId: scholarId, onBack: onBack, showBackButton: showBackButton);
  }
}
