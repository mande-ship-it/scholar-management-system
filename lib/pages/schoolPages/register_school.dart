import 'package:flutter/material.dart';
import '../../schools/register_school.dart';

class RegisterSchoolPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  const RegisterSchoolPage({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: RegisterSchoolComponent(onRegister: onSuccess != null ? (_) => onSuccess!() : null),
      ),
    );
  }
}
