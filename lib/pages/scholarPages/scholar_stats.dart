import 'package:flutter/material.dart';
import '../../scholars/scholar_stats.dart';
import '../../academics/academics_utils.dart';

class ScholarStatsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const ScholarStatsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ScholarStatsComponent(onBack: onBack);
  }
}
