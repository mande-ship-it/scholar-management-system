import 'package:flutter/material.dart';
import '../../attendance/attendance_history.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: AttendanceHistoryComponent(),
      ),
    );
  }
}
