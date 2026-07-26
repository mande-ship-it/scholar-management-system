import 'package:flutter/material.dart';
import '../../scholars/register_scholar.dart';

class RegisterScholarPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  const RegisterScholarPage({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: RegisterScholarComponent(onRegister: onSuccess != null ? (_) async => onSuccess!() : null),
      ),
    );
  }
}
