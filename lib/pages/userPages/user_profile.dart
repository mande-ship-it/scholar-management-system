import 'package:flutter/material.dart';
import '../../users/user_profile.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: UserProfileComponent(),
      ),
    );
  }
}
