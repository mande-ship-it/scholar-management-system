import 'package:flutter/material.dart';
import '../../users/permissions.dart';
import '../../academics/academics_utils.dart';

class PermissionsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const PermissionsPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return PermissionsComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
