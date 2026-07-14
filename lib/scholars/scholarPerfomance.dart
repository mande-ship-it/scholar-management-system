import 'package:flutter/material.dart';

class ScholarPerformanceComponent extends StatelessWidget {
  const ScholarPerformanceComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.bar_chart),
        title: Text("Scholar Performance"),
        subtitle: Text("Academic performance summary."),
      ),
    );
  }
}