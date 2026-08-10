import 'package:flutter/material.dart';
import '../../users/user_profile.dart';
import '../../academics/academics_utils.dart';

class UserProfilePage extends StatelessWidget {
  final VoidCallback? onBack;
  const UserProfilePage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return UserProfileComponent(onBack: onBack);
  }
}
