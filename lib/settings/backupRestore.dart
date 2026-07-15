// backup_restore.dart
import 'package:flutter/material.dart';

class BackupRestoreComponent extends StatefulWidget {
  const BackupRestoreComponent({super.key});

  @override
  State<BackupRestoreComponent> createState() => _BackupRestoreComponentState();
}

class _BackupItem {
  final String label;
  final String date;
  final String size;

  _BackupItem({required this.label, required this.date, required this.size});
}

class _BackupRestoreComponentState extends State<BackupRestoreComponent> {
  bool _autoBackupEnabled = true;
  String _backupFrequency = "Daily";
  bool _wifiOnly = true;

  bool _isBackingUp = false;
  bool _isRestoring = false;
  double _progress = 0;

  DateTime? _lastBackupTime = DateTime.now().subtract(const Duration(hours: 6));

  final List<String> _frequencies = ["Hourly", "Daily", "Weekly", "Monthly"];

  final List<_BackupItem> _history = [
    _BackupItem(label: "Full Backup", date: "Today, 06:12 AM", size: "84 MB"),
    _BackupItem(label: "Full Backup", date: "Yesterday, 06:10 AM", size: "82 MB"),
    _BackupItem(label: "Full Backup", date: "Jul 12, 06:08 AM", size: "79 MB"),
  ];

  Future<void> _runBackup() async {
    setState(() {
      _isBackingUp = true;
      _progress = 0;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }

    setState(() {
      _isBackingUp = false;
      _lastBackupTime = DateTime.now();
      _history.insert(
        0,
        _BackupItem(label: "Full Backup", date: "Just now", size: "85 MB"),
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Backup completed successfully"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runRestore(_BackupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Restore Backup"),
        content: Text(
          "Restore data from \"${item.date}\"? Current data will be replaced.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Restore"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
      _progress = 0;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }

    setState(() => _isRestoring = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Restore completed successfully"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatLastBackup() {
    if (_lastBackupTime == null) return "Never";
    final diff = DateTime.now().difference(_lastBackupTime!);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inDays < 1) return "${diff.inHours} hr ago";
    return "${diff.inDays} day(s) ago";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _isBackingUp || _isRestoring;

    return ListView(
      shrinkWrap: true,
      children: [
        Text(
          "Backup & Restore",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ) ??
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Protect your data with backups and restore when needed.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        _buildStatsRow(),
        const SizedBox(height: 16),

        // ---- Status / progress ----
        _sectionCard(
          title: "Backup Status",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: Colors.green.shade600, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Last Backup", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          _formatLastBackup(),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (busy) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isBackingUp
                      ? "Backing up... ${(_progress * 100).toInt()}%"
                      : "Restoring... ${(_progress * 100).toInt()}%",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _runBackup,
                      icon: const Icon(Icons.backup_outlined, size: 18),
                      label: const Text("Back Up Now"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (busy || _history.isEmpty) ? null : () => _runRestore(_history.first),
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text("Restore Latest"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---- Auto backup settings ----
        _sectionCard(
          title: "Automatic Backup",
          child: Column(
            children: [
              _buildSwitchTile(
                title: "Auto Backup",
                subtitle: "Automatically back up your data",
                icon: Icons.autorenew,
                value: _autoBackupEnabled,
                onChanged: (v) => setState(() => _autoBackupEnabled = v),
              ),
              if (_autoBackupEnabled) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 22),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text("Frequency", style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    DropdownButton<String>(
                      value: _backupFrequency,
                      underline: const SizedBox(),
                      items: _frequencies
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) => setState(() => _backupFrequency = v!),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildSwitchTile(
                  title: "Wi-Fi Only",
                  subtitle: "Only back up when connected to Wi-Fi",
                  icon: Icons.wifi,
                  value: _wifiOnly,
                  onChanged: (v) => setState(() => _wifiOnly = v),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---- History ----
        _sectionCard(
          title: "Backup History",
          child: _history.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "No backups yet",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
              : Column(
            children: List.generate(_history.length, (index) {
              final item = _history[index];
              return Column(
                children: [
                  _buildHistoryTile(item, busy),
                  if (index != _history.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ---------- Sub-widgets ----------

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: "Total Backups",
            value: "${_history.length}",
            color: Colors.green.shade50,
            valueColor: Colors.green.shade800,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            label: "Storage Used",
            value: "246 MB",
            color: Colors.orange.shade50,
            valueColor: Colors.orange.shade800,
            icon: Icons.sd_storage_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: valueColor, size: 20),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildHistoryTile(_BackupItem item, bool busy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.history, size: 18, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  "${item.date} · ${item.size}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : () => _runRestore(item),
            child: const Text("Restore"),
          ),
        ],
      ),
    );
  }
}