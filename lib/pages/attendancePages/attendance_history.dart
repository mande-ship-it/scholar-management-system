import 'package:flutter/material.dart';
import '../../attendance/attendance_history.dart';
import '../../academics/academics_utils.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final VoidCallback? onMarkAttendance;
  const AttendanceHistoryPage({super.key, this.onMarkAttendance});

  @override
  Widget build(BuildContext context) {
    return const AttendanceHistoryComponent();
  }
}
