import 'package:flutter/material.dart';
import '../../academics/reportCards.dart';

class ReportCardsPage extends StatelessWidget {
  const ReportCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ReportCardsComponent(),
      ),
    );
  }
}
