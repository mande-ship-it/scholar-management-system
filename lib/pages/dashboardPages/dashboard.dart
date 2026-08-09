import 'package:flutter/material.dart';
import '../../dashBoard/dashboard.dart';
import '../../academics/academics_utils.dart';

class DashboardPage extends StatelessWidget {
  final Function(String)? onNavigate;
  final String? userRole;
  const DashboardPage({super.key, this.onNavigate, this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Program Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: DashboardComponent(onNavigate: onNavigate, userRole: userRole),
    );
  }
}
