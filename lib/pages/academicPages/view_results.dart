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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("View Academic Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: ViewResultsComponent(
          onEnterResults: onEnterResults,
          onViewPerformance: onViewPerformance,
          onViewReports: onViewReports,
        ),
      ),
    );
  }
}
