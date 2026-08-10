import 'package:flutter/material.dart';
import '../../academics/report_cards.dart';
import '../../academics/academics_utils.dart';

class ReportCardsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const ReportCardsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ReportCardsComponent(onBack: onBack);
  }
}
