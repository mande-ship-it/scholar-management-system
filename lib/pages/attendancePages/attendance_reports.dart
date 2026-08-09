import 'package:flutter/material.dart';
import '../../attendance/attendance_reports.dart';
import '../../academics/academics_utils.dart';

class AttendanceModuleReportsPage extends StatelessWidget {
  const AttendanceModuleReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Attendance Reports", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: AttendanceReportsComponent(),
      ),
    );
  }
}
