import 'package:flutter/material.dart';
import '../../attendance/attendanceReports.dart';

class AttendanceModuleReportsPage extends StatelessWidget {
  const AttendanceModuleReportsPage({super.key});

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
