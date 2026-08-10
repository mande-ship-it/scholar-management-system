import 'package:flutter/material.dart';
import '../../scholars/register_scholar.dart';
import '../../academics/academics_utils.dart';

class RegisterScholarPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  final String? forcedSchoolType;
  const RegisterScholarPage({super.key, this.onSuccess, this.forcedSchoolType});

  @override
  Widget build(BuildContext context) {
    return RegisterScholarComponent(
      onRegister: onSuccess != null ? (_) async => onSuccess!() : null,
      forcedSchoolType: forcedSchoolType,
    );
  }
}
