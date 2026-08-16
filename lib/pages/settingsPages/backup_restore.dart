import 'package:flutter/material.dart';
import '../../settings/backup_restore.dart';
import '../../academics/academics_utils.dart';

class BackupRestorePage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const BackupRestorePage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return BackupRestoreComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
