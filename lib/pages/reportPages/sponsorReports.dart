import 'package:flutter/material.dart';
import '../../reports/sponsorReports.dart';

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
