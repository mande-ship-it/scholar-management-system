import 'package:flutter/material.dart';
import '../../reports/sponsor_reports.dart';

class SponsorReportsPage extends StatelessWidget {
  const SponsorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SponsorReportsComponent(),
      ),
    );
  }
}
