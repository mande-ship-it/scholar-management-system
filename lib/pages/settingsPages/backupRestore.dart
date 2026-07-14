import 'package:flutter/material.dart';
import '../../settings/backupRestore.dart';

class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: BackupRestoreComponent(),
      ),
    );
  }
}
