import 'package:flutter/material.dart';
import '../../dashBoard/dashboard.dart';
import '../../academics/academics_utils.dart';

class DashboardPage extends StatelessWidget {
  final Function(String)? onNavigate;
  final String? userRole;
  final VoidCallback? onBack;
  const DashboardPage({super.key, this.onNavigate, this.userRole, this.onBack});

  @override
  Widget build(BuildContext context) {
    return DashboardComponent(onNavigate: onNavigate, userRole: userRole, onBack: onBack);
  }
}
