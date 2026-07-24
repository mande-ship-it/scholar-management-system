import 'package:flutter/material.dart';
import '../../sponsors/register_sponsor.dart';

class RegisterSponsorPage extends StatelessWidget {
  const RegisterSponsorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: RegisterSponsorComponent(),
      ),
    );
  }
}
