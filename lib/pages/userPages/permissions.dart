import 'package:flutter/material.dart';
import '../../users/permissions.dart';
import '../../academics/academics_utils.dart';

class PermissionsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const PermissionsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PermissionsComponent(onBack: onBack);
  }
}
