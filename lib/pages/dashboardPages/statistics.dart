import 'package:flutter/material.dart';
import '../../dashBoard/statistics.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final level = args?['level'] ?? 'University';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StatisticsComponent(level: level),
      ),
    );
  }
}
