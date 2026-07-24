import 'package:flutter/material.dart';
import '../../sponsors/sponsor_stats.dart';

class SponsorStatsPage extends StatelessWidget {
  const SponsorStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SponsorStatsComponent(),
      ),
    );
  }
}
