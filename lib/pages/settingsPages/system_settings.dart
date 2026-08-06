import 'package:flutter/material.dart';
import '../../settings/system_settings.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const SystemSettingsComponent(),
      ),
    );
  }
}
