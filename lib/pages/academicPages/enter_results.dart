import 'package:flutter/material.dart';
import '../../academics/enter_results.dart';
import '../../academics/academics_utils.dart';

class EnterResultsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final Function(String)? onPush;
  const EnterResultsPage({super.key, this.onBack, this.onPush});

  @override
  Widget build(BuildContext context) {
    return AcademicsManagementComponent(onBack: onBack, onPush: onPush);
  }
}
