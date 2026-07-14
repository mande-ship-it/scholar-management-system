import 'package:flutter/material.dart';
import '../../settings/systemSettings.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SystemSettingsComponent(),
      ),
    );
  }
}
