import 'package:flutter/material.dart';
import '../../users/user_roles.dart';
import '../../academics/academics_utils.dart';

class UserRolesPage extends StatelessWidget {
  final VoidCallback? onBack;
  const UserRolesPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return UserRolesComponent(onBack: onBack);
  }
}
