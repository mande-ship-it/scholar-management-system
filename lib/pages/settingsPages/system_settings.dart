import 'package:flutter/material.dart';
import '../../settings/system_settings.dart';
import '../../academics/academics_utils.dart';

class SystemSettingsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const SystemSettingsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SystemSettingsComponent(onBack: onBack);
  }
}
