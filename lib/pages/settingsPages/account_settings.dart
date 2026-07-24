import 'package:flutter/material.dart';
import '../../settings/account_settings.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: AccountSettingsComponent(),
      ),
    );
  }
}
