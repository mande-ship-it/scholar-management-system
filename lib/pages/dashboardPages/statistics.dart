import 'package:flutter/material.dart';
import '../../dashBoard/statistics.dart';
import '../../academics/academics_utils.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final level = args?['level'] ?? 'University';

    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Performance Intelligence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        padding: const EdgeInsets.all(20),
        child: StatisticsComponent(level: level),
      ),
    );
  }
}
