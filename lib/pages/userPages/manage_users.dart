import 'package:flutter/material.dart';
import '../../users/manage_users.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Administration"),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ManageUsersComponent(
          onAddUser: () => Navigator.pushNamed(context, '/users/create'),
        ),
      ),
    );
  }
}
