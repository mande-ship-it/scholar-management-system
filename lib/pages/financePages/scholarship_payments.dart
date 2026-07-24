import 'package:flutter/material.dart';
import '../../finance/scholarship_payments.dart';

class ScholarshipPaymentsPage extends StatelessWidget {
  const ScholarshipPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ScholarshipPaymentsComponent(),
      ),
    );
  }
}
