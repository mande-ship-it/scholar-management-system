import 'package:flutter/material.dart';
import '../../scholars/register_scholar.dart';
import '../../academics/academics_utils.dart';

class RegisterScholarPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBack;
  final String? forcedSchoolType;
  const RegisterScholarPage({super.key, this.onSuccess, this.onBack, this.forcedSchoolType});

  @override
  Widget build(BuildContext context) {
    return RegisterScholarComponent(
      onRegister: onSuccess != null ? (_) async => onSuccess!() : null,
      onBack: onBack,
      forcedSchoolType: forcedSchoolType,
    );
  }
}
