import 'package:flutter/material.dart';
import '../../academics/enter_results.dart';
import '../../academics/academics_utils.dart';

class EnterResultsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final Function(String)? onPush;
  final SchoolType? forcedSchoolType;
  const EnterResultsPage({super.key, this.onBack, this.onPush, this.forcedSchoolType});

  @override
  Widget build(BuildContext context) {
    return AcademicsManagementComponent(onBack: onBack, onPush: onPush, forcedSchoolType: forcedSchoolType);
  }
}
