import 'package:flutter/material.dart';
import '../../scholars/register_scholar.dart';
import '../../academics/academics_utils.dart';

class RegisterScholarPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBack;
  final String? forcedSchoolType;
  final bool showBackButton;
  const RegisterScholarPage({super.key, this.onSuccess, this.onBack, this.forcedSchoolType, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return RegisterScholarComponent(
      onRegister: onSuccess != null ? (_) async => onSuccess!() : null,
      onBack: onBack,
      forcedSchoolType: forcedSchoolType,
      showBackButton: showBackButton,
    );
  }
}
