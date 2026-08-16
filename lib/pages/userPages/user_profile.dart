import 'package:flutter/material.dart';
import '../../users/user_profile.dart';
import '../../academics/academics_utils.dart';

class UserProfilePage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const UserProfilePage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return UserProfileComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
