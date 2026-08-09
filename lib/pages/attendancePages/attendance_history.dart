import 'package:flutter/material.dart';
import '../../attendance/view_attendance.dart';
import '../../academics/academics_utils.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final VoidCallback? onMarkAttendance;
  const AttendanceHistoryPage({super.key, this.onMarkAttendance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Attendance History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: ViewAttendanceComponent(onMarkAttendance: onMarkAttendance),
    );
  }
}
