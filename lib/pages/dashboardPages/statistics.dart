import 'package:flutter/material.dart';
import '../../dashBoard/statistics.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: StatisticsComponent(),
      ),
    );
  }
}
