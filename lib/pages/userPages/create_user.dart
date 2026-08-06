import 'package:flutter/material.dart';
import '../../users/create_user.dart';

class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      appBar: isMobile ? null : AppBar(
        title: const Text("User Management"),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const CreateUserComponent(),
      ),
    );
  }
}
