import 'package:flutter/material.dart';
import '../../users/user_roles.dart';
import '../../academics/academics_utils.dart';

class UserRolesPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const UserRolesPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return UserRolesComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
