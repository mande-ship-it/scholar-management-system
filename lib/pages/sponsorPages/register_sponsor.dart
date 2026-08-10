import 'package:flutter/material.dart';
import '../../sponsors/register_sponsor.dart';
import '../../academics/academics_utils.dart';

class RegisterSponsorPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  const RegisterSponsorPage({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return RegisterSponsorComponent(onRegister: onSuccess != null ? (_) async => onSuccess!() : null);
  }
}
