import 'package:flutter/material.dart';
import '../../academics/view_results.dart';
import '../../academics/academics_utils.dart';

class ViewResultsPage extends StatelessWidget {
  final VoidCallback? onEnterResults;
  final VoidCallback? onViewPerformance;
  final VoidCallback? onViewReports;

  const ViewResultsPage({
    super.key,
    this.onEnterResults,
    this.onViewPerformance,
    this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    return ViewResultsComponent(
      onEnterResults: onEnterResults,
      onViewPerformance: onViewPerformance,
      onViewReports: onViewReports,
    );
  }
}
