import 'package:flutter/material.dart';
import '../../sponsors/register_sponsor.dart';

class RegisterSponsorPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  const RegisterSponsorPage({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RegisterSponsorComponent(onRegister: onSuccess != null ? (_) async => onSuccess!() : null),
    );
  }
}
