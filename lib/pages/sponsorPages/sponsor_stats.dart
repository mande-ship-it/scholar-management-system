import 'package:flutter/material.dart';
import '../../sponsors/sponsor_stats.dart';

class SponsorStatsPage extends StatelessWidget {
  const SponsorStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const SponsorStatsComponent(),
      ),
    );
  }
}
