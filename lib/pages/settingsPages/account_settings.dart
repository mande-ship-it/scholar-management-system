import 'package:flutter/material.dart';
import '../../settings/account_settings.dart';
import '../../academics/academics_utils.dart';

class AccountSettingsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const AccountSettingsPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return AccountSettingsComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
