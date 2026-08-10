import 'package:flutter/material.dart';
import '../../attendance/scholar_attendance.dart';
import '../../academics/academics_utils.dart';

class ScholarAttendancePage extends StatelessWidget {
  final VoidCallback? onBack;
  final SchoolType? forcedSchoolType;
  final AttendanceModuleType? forcedModuleType;

  const ScholarAttendancePage({
    super.key,
    this.onBack,
    this.forcedSchoolType,
    this.forcedModuleType,
  });

  @override
  Widget build(BuildContext context) {
    // Check for arguments from navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    SchoolType? effectiveSchoolType = forcedSchoolType;
    AttendanceModuleType? effectiveModuleType = forcedModuleType;

    if (args != null) {
      if (args.containsKey('forcedSchoolType')) {
        effectiveSchoolType = args['forcedSchoolType'];
      }
      if (args.containsKey('forcedModuleType')) {
        final m = args['forcedModuleType'];
        if (m == 'chats') effectiveModuleType = AttendanceModuleType.chats;
        else if (m == 'studyCircle') effectiveModuleType = AttendanceModuleType.studyCircle;
        else if (m == 'classAttendance') effectiveModuleType = AttendanceModuleType.classAttendance;
      }
    }

    return ScholarAttendanceComponent(
      onBack: onBack,
      forcedSchoolType: effectiveSchoolType,
      forcedModuleType: effectiveModuleType,
    );
  }
}
