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
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("System Users Directory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: ManageUsersComponent(
        onAddUser: onAddUser,
        onViewRoles: onViewRoles,
        onViewPermissions: onViewPermissions,
        onViewDepartments: onViewDepartments,
        onViewProfile: onViewProfile,
      ),
    );
  }
}
