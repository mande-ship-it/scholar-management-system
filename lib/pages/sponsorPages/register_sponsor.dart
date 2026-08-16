import 'package:flutter/material.dart';
import '../../sponsors/register_sponsor.dart';
import '../../academics/academics_utils.dart';

class RegisterSponsorPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBack;
  final bool showBackButton;
  const RegisterSponsorPage({super.key, this.onSuccess, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return RegisterSponsorComponent(
      onBack: onBack,
      showBackButton: showBackButton,
      onRegister: onSuccess != null ? (_) async => onSuccess!() : null
    );
  }
}
