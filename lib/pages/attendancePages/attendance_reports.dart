import 'package:flutter/material.dart';
import '../../attendance/attendance_reports.dart';
import '../../academics/academics_utils.dart';

class AttendanceModuleReportsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const AttendanceModuleReportsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AttendanceReportsComponent(onBack: onBack);
  }
}
