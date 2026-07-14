import 'package:flutter/material.dart';
import '../../academics/enterResults.dart';

class EnterResultsPage extends StatelessWidget {
  const EnterResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: EnterResultsComponent(),
      ),
    );
  }
}
