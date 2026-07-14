import 'package:flutter/material.dart';
import '../../scholars/registerScholar.dart';

class RegisterScholarPage extends StatelessWidget {
  const RegisterScholarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: RegisterScholarComponent(),
      ),
    );
  }
}