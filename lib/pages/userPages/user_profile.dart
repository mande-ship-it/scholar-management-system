import 'package:flutter/material.dart';
import '../../users/user_profile.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const UserProfileComponent(),
      ),
    );
  }
}
