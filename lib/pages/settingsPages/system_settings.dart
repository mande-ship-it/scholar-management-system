import 'package:flutter/material.dart';
import '../../settings/system_settings.dart';
import '../../academics/academics_utils.dart';

class SystemSettingsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const SystemSettingsPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return SystemSettingsComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
