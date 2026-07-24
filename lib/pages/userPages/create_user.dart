import 'package:flutter/material.dart';
import '../../users/create_user.dart';

class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        centerTitle: false,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: CreateUserComponent(),
      ),
    );
  }
}
