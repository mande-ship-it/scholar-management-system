import 'package:flutter/material.dart';
import '../../settings/account_settings.dart';
import '../../academics/academics_utils.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Account Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const AccountSettingsComponent(),
      ),
    );
  }
}
