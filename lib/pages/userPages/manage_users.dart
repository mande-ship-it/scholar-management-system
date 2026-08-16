import 'package:flutter/material.dart';
import '../../users/manage_users.dart';
import '../../academics/academics_utils.dart';

class ManageUsersPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onAddUser;
  final VoidCallback? onViewRoles;
  final VoidCallback? onViewPermissions;
  final VoidCallback? onViewDepartments;
  final VoidCallback? onViewProfile;
  final bool showBackButton;

  const ManageUsersPage({
    super.key,
    this.onBack,
    this.onAddUser,
    this.onViewRoles,
    this.onViewPermissions,
    this.onViewDepartments,
    this.onViewProfile,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ManageUsersComponent(
      onBack: onBack,
      onAddUser: onAddUser,
      onViewRoles: onViewRoles,
      onViewPermissions: onViewPermissions,
      onViewDepartments: onViewDepartments,
      onViewProfile: onViewProfile,
      showBackButton: showBackButton,
    );
  }
}
