import 'package:flutter/material.dart';
import '../../attendance/view_attendance.dart';
import '../../academics/academics_utils.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMarkAttendance;
  final bool showBackButton;
  const AttendanceHistoryPage({
    super.key,
    this.onBack,
    this.onMarkAttendance,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ViewAttendanceComponent(
      onBack: onBack,
      onMarkAttendance: onMarkAttendance,
    );
  }
}
