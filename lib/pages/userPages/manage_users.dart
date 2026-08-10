import 'package:flutter/material.dart';
import '../../users/manage_users.dart';
import '../../academics/academics_utils.dart';

class ManageUsersPage extends StatelessWidget {
  final VoidCallback? onAddUser;
  final VoidCallback? onViewRoles;
  final VoidCallback? onViewPermissions;
  final VoidCallback? onViewDepartments;
  final VoidCallback? onViewProfile;

  const ManageUsersPage({
    super.key,
    this.onAddUser,
    this.onViewRoles,
    this.onViewPermissions,
    this.onViewDepartments,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return ManageUsersComponent(
      onAddUser: onAddUser,
      onViewRoles: onViewRoles,
      onViewPermissions: onViewPermissions,
      onViewDepartments: onViewDepartments,
      onViewProfile: onViewProfile,
    );
  }
}
