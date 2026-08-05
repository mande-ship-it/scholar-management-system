import 'package:flutter/material.dart';
import '../../dashboard/field_operations_dashboard.dart';

class FieldOperationsPage extends StatelessWidget {
  final Function(String)? onNavigate;
  const FieldOperationsPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldOperationsDashboard(onNavigate: onNavigate),
    );
  }
}
