import 'package:flutter/material.dart';
import '../../scholars/register_scholar.dart';
import '../../academics/academics_utils.dart';

class RegisterScholarPage extends StatelessWidget {
  final VoidCallback? onSuccess;
  final String? forcedSchoolType;
  const RegisterScholarPage({super.key, this.onSuccess, this.forcedSchoolType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Register Scholar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: RegisterScholarComponent(
        onRegister: onSuccess != null ? (_) async => onSuccess!() : null,
        forcedSchoolType: forcedSchoolType,
      ),
    );
  }
}
