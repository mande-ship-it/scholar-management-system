import 'package:flutter/material.dart';
import '../../dashboard/dashboard.dart';

class DashboardPage extends StatelessWidget {
  final Function(String)? onNavigate;
  final String? userRole;
  const DashboardPage({super.key, this.onNavigate, this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashboardComponent(onNavigate: onNavigate, userRole: userRole),
    );
  }
}
