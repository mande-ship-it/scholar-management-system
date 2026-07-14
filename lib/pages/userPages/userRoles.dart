import 'package:flutter/material.dart';
import '../../users/userRoles.dart';

class UserRolesPage extends StatelessWidget {
  const UserRolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: UserRolesComponent(),
      ),
    );
  }
}
