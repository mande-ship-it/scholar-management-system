import 'package:flutter/material.dart';
import '../../attendance/attendance_history.dart';
import '../../academics/academics_utils.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMarkAttendance;
  const AttendanceHistoryPage({super.key, this.onBack, this.onMarkAttendance});

  @override
  Widget build(BuildContext context) {
    return AttendanceHistoryComponent(onBack: onBack);
  }
}
