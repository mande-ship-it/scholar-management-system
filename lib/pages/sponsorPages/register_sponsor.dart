import 'package:flutter/material.dart';
import '../../sponsors/register_sponsor.dart';
import '../../academics/academics_utils.dart';

class RegisterSponsorPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  const RegisterSponsorPage({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Register Partner", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: RegisterSponsorComponent(onRegister: onSuccess != null ? (_) async => onSuccess!() : null),
    );
  }
}
