import 'package:flutter/material.dart';
import '../../reports/attendanceReports.dart';

class ReportAttendanceReportsPage extends StatelessWidget {
  const ReportAttendanceReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: AttendanceReportsComponent(),
      ),
    );
  }
}
