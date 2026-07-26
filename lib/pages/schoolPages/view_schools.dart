import 'package:flutter/material.dart';
import '../../schools/view_schools.dart';

class ViewSchoolsPage extends StatelessWidget {
  final VoidCallback? onRegisterSchool;
  const ViewSchoolsPage({super.key, this.onRegisterSchool});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ViewSchoolsComponent(onRegisterSchool: onRegisterSchool),
      ),
    );
  }
}
