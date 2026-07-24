import 'package:flutter/material.dart';
import '../../academics/view_results.dart';

class ViewResultsPage extends StatelessWidget {
  const ViewResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ViewResultsComponent(),
      ),
    );
  }
}
