import 'package:flutter/material.dart';
import '../../attendance/takeAttendance.dart';

class TakeAttendancePage extends StatelessWidget {
  const TakeAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: TakeAttendanceComponent(),
      ),
    );
  }
}
