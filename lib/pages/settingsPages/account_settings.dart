import 'package:flutter/material.dart';
import '../../settings/account_settings.dart';
import '../../academics/academics_utils.dart';

class AccountSettingsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const AccountSettingsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AccountSettingsComponent(onBack: onBack);
  }
}
