import 'package:flutter/material.dart';
import '../../attendance/view_attendance.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final VoidCallback? onMarkAttendance;
  const AttendanceHistoryPage({super.key, this.onMarkAttendance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewAttendanceComponent(onMarkAttendance: onMarkAttendance),
    );
  }
}
