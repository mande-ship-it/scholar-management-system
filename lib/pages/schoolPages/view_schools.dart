import 'package:flutter/material.dart';
import '../../schools/view_schools.dart';

class ViewSchoolsPage extends StatelessWidget {
  final VoidCallback? onRegisterSchool;
  final String? forcedLevel;
  final bool hideRegistration;
  const ViewSchoolsPage({super.key, this.onRegisterSchool, this.forcedLevel, this.hideRegistration = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ViewSchoolsComponent(
          onRegisterSchool: onRegisterSchool,
          forcedLevel: forcedLevel,
          hideRegistration: hideRegistration,
        ),
      ),
    );
  }
}
