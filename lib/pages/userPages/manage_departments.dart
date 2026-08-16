import 'package:flutter/material.dart';
import '../../users/manage_departments.dart';
import '../../academics/academics_utils.dart';

class ManageDepartmentsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const ManageDepartmentsPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return ManageDepartmentsComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
