import 'package:flutter/material.dart';
import '../../schools/registerSchool.dart';

class RegisterSchoolPage extends StatelessWidget {
  const RegisterSchoolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: RegisterSchoolComponent(),
      ),
    );
  }
}
