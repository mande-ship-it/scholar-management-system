import 'package:flutter/material.dart';
import '../../academics/view_results.dart';

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ViewResultsComponent(
          onEnterResults: onEnterResults,
          onViewPerformance: onViewPerformance,
          onViewReports: onViewReports,
        ),
      ),
    );
  }
}
