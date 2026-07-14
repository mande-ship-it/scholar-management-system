import 'package:flutter/material.dart';
import '../../users/createUser.dart';

class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: CreateUserComponent(),
      ),
    );
  }
}
