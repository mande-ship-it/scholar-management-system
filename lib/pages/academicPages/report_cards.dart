import 'package:flutter/material.dart';
import '../../academics/report_cards.dart';

class ReportCardsPage extends StatelessWidget {
  const ReportCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const ReportCardsComponent(),
      ),
    );
  }
}
