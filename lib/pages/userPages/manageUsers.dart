import 'package:flutter/material.dart';
import '../../users/manageUsers.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ManageUsersComponent(),
      ),
    );
  }
}
