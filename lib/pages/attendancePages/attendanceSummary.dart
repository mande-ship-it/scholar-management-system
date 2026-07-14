import 'package:flutter/material.dart';
import '../../attendance/attendanceSummary.dart';

class AttendanceSummaryPage extends StatelessWidget {
  const AttendanceSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: AttendanceSummaryComponent(),
      ),
    );
  }
}
