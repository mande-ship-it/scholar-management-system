import 'package:flutter/material.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class _BackupItem {
  final String label;
  final String date;
  final String size;
  _BackupItem({required this.label, required this.date, required this.size});
}

class BackupRestoreComponent extends StatefulWidget {
  const BackupRestoreComponent({super.key});

  @override
  State<BackupRestoreComponent> createState() => _BackupRestoreComponentState();
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
    _BackupItem(label: "Cloud Backup", date: "Today, 06:12 AM", size: "84 MB"),
    _BackupItem(label: "Cloud Backup", date: "Yesterday, 06:10 AM", size: "82 MB"),
    _BackupItem(label: "Local Backup", date: "Jul 12, 06:08 AM", size: "79 MB"),
  ];

  Future<void> _runBackup() async {
    setState(() {
      _isBackingUp = true;
      _progress = 0;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }

    setState(() {
      _isBackingUp = false;
      _lastBackupTime = DateTime.now();
      _history.insert(0, _BackupItem(label: "Manual Backup", date: "Just now", size: "85 MB"));
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cloud backup completed successfully."), backgroundColor: kBrandOlive),
    );
  }

  Future<void> _runRestore(_BackupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Restore"),
        content: Text("Restore all data from \"${item.date}\"? Current session data will be overwritten."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Start Restore"),
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
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }

    setState(() => _isRestoring = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("System data restored successfully."), backgroundColor: kBrandOlive),
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
    final busy = _isBackingUp || _isRestoring;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kBrandBrown, kBrandOlive]),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backup & Restore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Secure your program data with automated cloud backups.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Row
                  _buildStatusCard(busy),
                  const SizedBox(height: 32),

                  const Text("Automatic Backup Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  _buildSwitchTile(
                    title: "Cloud Sync",
                    subtitle: "Automatically sync data to secure cloud storage",
                    icon: Icons.sync_rounded,
                    value: _autoBackupEnabled,
                    onChanged: (v) => setState(() => _autoBackupEnabled = v),
                  ),
                  if (_autoBackupEnabled) ...[
                    const SizedBox(height: 12),
                    _buildDropdownTile(
                      title: "Frequency",
                      value: _backupFrequency,
                      icon: Icons.schedule_rounded,
                      options: _frequencies,
                      onChanged: (v) => setState(() => _backupFrequency = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: "Wi-Fi Only",
                      subtitle: "Only upload data over Wi-Fi networks",
                      icon: Icons.wifi_rounded,
                      value: _wifiOnly,
                      onChanged: (v) => setState(() => _wifiOnly = v),
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Text("Backup History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: _history.map((item) => _buildHistoryItem(item, busy)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool busy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBrandCream.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrandCream),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.cloud_done_rounded, color: kBrandOlive, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Last successful backup", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(_formatLastBackup(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  ],
                ),
              ),
              if (!busy)
                ElevatedButton.icon(
                  onPressed: _runBackup,
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text("Sync Now"),
                  style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
                ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _progress, minHeight: 8, backgroundColor: Colors.white, color: kBrandOlive),
            ),
            const SizedBox(height: 8),
            Text(
              _isBackingUp ? "Uploading data to secure storage... ${(_progress * 100).toInt()}%" : "Restoring system data... ${(_progress * 100).toInt()}%",
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kBrandBrown),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        secondary: Icon(icon, color: kBrandBrown, size: 22),
        value: value,
        activeColor: kBrandOlive.withValues(alpha: 0.8),
        activeTrackColor: kBrandOlive.withValues(alpha: 0.3),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: kBrandBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14))),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(_BackupItem item, bool busy) {
    return ListTile(
      leading: const Icon(Icons.history_rounded, color: Colors.grey, size: 20),
      title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("${item.date} • ${item.size}", style: const TextStyle(fontSize: 12)),
      trailing: TextButton(
        onPressed: busy ? null : () => _runRestore(item),
        child: const Text("Restore", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive)),
      ),
    );
  }
}
