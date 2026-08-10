import 'package:flutter/material.dart';
import '../../sponsors/register_sponsor.dart';
import '../../academics/academics_utils.dart';

class RegisterSponsorPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBack;
  const RegisterSponsorPage({super.key, this.onSuccess, this.onBack});

  @override
  Widget build(BuildContext context) {
    return RegisterSponsorComponent(
      onBack: onBack,
      onRegister: onSuccess != null ? (_) async => onSuccess!() : null
    );
  }
}
