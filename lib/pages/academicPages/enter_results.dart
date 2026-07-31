import 'package:flutter/material.dart';
import '../../academics/enter_results.dart';

class EnterResultsPage extends StatelessWidget {
  const EnterResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AcademicsManagementComponent(),
      ),
    );
  }
}
