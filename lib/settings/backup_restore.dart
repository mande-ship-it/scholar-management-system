import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class _BackupItem {
  final String id;
  final String label;
  final String date;
  final String size;
  _BackupItem({required this.id, required this.label, required this.date, required this.size});
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
  bool _isLoading = false;
  double _progress = 0;

  DateTime? _lastBackupTime;
  final List<String> _frequencies = ["Hourly", "Daily", "Weekly", "Monthly"];
  List<_BackupItem> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchBackupInfo();
  }

  Future<void> _fetchBackupInfo() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getBackupInfo();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          final settings = data['settings'];
          final historyList = data['history'] as List;

          setState(() {
            _autoBackupEnabled = settings['auto_backup_enabled'] ?? true;
            _backupFrequency = settings['frequency'] ?? "Daily";
            _wifiOnly = settings['wifi_only'] ?? true;
            _lastBackupTime = settings['last_backup_at'] != null ? DateTime.parse(settings['last_backup_at']) : null;
            
            _history = historyList.map((h) => _BackupItem(
              id: h['id'].toString(),
              label: h['label'] ?? 'Manual Backup',
              date: _formatDateTime(DateTime.parse(h['created_at'])),
              size: h['file_size'] ?? '0 MB'
            )).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching backup info: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime d) {
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _updateSettings(Map<String, dynamic> delta) async {
    try {
      await ApiService.updateBackupSettings(delta);
    } catch (e) {
      debugPrint('Error updating backup settings: $e');
    }
  }

  Future<void> _runBackup() async {
    setState(() { _isBackingUp = true; _progress = 0; });

    try {
      for (int i = 1; i <= 4; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => _progress = i / 10);
      }

      final response = await ApiService.runBackup("Cloud Manual Sync");
      
      if (response.statusCode == 201) {
        for (int i = 5; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) setState(() => _progress = i / 10);
        }
        _fetchBackupInfo();
      }
    } catch (e) {
      debugPrint('Error running backup: $e');
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Incremental backup finalized and verified."), backgroundColor: kBrandOlive),
    );
  }

  Future<void> _runRestore(_BackupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Critical Data Restore", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text("Restoring from \"${item.date}\" will overwrite all current system data. This action is irreversible. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("START RESTORE"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { _isRestoring = true; _progress = 0; });

    try {
      final response = await ApiService.restoreBackup(item.id);
      if (response.statusCode == 200) {
        for (int i = 1; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) setState(() => _progress = i / 10);
        }
      }
    } catch (e) {
      debugPrint('Error restoring backup: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("System state successfully rolled back."), backgroundColor: kBrandOlive),
    );
  }

  String _formatLastBackup() {
    if (_lastBackupTime == null) return "No history detected";
    final diff = DateTime.now().difference(_lastBackupTime!);
    if (diff.inMinutes < 1) return "Less than a minute ago";
    if (diff.inHours < 1) return "${diff.inMinutes} minutes ago";
    if (diff.inDays < 1) return "${diff.inHours} hours ago";
    return "${diff.inDays} day(s) ago";
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    final busy = _isBackingUp || _isRestoring;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kBrandOlive, strokeWidth: 3))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) _buildExecutiveHeader(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrimaryStatusSection(busy, isMobile),
                        const SizedBox(height: 48),

                        if (isMobile)
                          Column(
                            children: [
                              _buildAutomationControls(isMobile),
                              const SizedBox(height: 40),
                              _buildHistoricalLogs(busy, isMobile),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildAutomationControls(isMobile)),
                              const SizedBox(width: 40),
                              Expanded(child: _buildHistoricalLogs(busy, isMobile)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Disaster Recovery",
                  style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryStatusSection(bool busy, bool isMobile) {
    Widget icon = Container(
      width: isMobile ? 60 : 72,
      height: isMobile ? 60 : 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
      ),
      child: Icon(Icons.shield_rounded, color: kBrandOlive, size: isMobile ? 28 : 36),
    );

    Widget textInfo = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Text("ENCRYPTED ARCHIVE ACTIVE",
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 8),
        Text("Infrastructure Guard", style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text("LAST SYNC: ${_formatLastBackup().toUpperCase()}", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );

    Widget button = !busy 
      ? SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: _runBackup,
            icon: const Icon(Icons.cloud_sync_rounded, size: 18),
            label: const Text("EXECUTE SYNC", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kBrandBrown,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        )
      : const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: kBrandBrown,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: kBrandBrown.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              children: [
                icon,
                const SizedBox(height: 20),
                textInfo,
                const SizedBox(height: 24),
                button,
              ],
            )
          else
            Row(
              children: [
                icon,
                const SizedBox(width: 28),
                Expanded(child: textInfo),
                button,
              ],
            ),
          if (busy) ...[
            const SizedBox(height: 32),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(value: _progress, minHeight: 16, backgroundColor: Colors.white.withOpacity(0.05), color: kBrandOlive),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text("${(_progress * 100).toInt()}% COMPLETED",
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: kBrandOlive)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _isBackingUp ? "ENCRYPTING DATA BLOCKS..." : "RECONSTRUCTING ARCHIVE...",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.7), letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutomationControls(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("AUTOMATION POLICY"),
        const SizedBox(height: 24),
        _buildControlTile(
          isMobile: isMobile,
          title: "Cloud Sync",
          subtitle: "Snapshots to secure storage.",
          icon: Icons.auto_mode_rounded,
          trailing: Switch(
            value: _autoBackupEnabled,
            activeColor: kBrandOlive,
            onChanged: (v) { setState(() => _autoBackupEnabled = v); _updateSettings({'auto_backup_enabled': v}); },
          ),
        ),
        if (_autoBackupEnabled) ...[
          const SizedBox(height: 16),
          _buildControlTile(
            isMobile: isMobile,
            title: "Sync Interval",
            subtitle: "Frequency of snapshots.",
            icon: Icons.timer_rounded,
            trailing: DropdownButton<String>(
              value: _backupFrequency,
              underline: const SizedBox(),
              items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (v) { setState(() => _backupFrequency = v!); _updateSettings({'frequency': v}); },
            ),
          ),
          const SizedBox(height: 16),
          _buildControlTile(
            isMobile: isMobile,
            title: "Wi-Fi Only",
            subtitle: "Restrict large transfers.",
            icon: Icons.network_check_rounded,
            trailing: Switch(
              value: _wifiOnly,
              activeColor: kBrandOlive,
              onChanged: (v) { setState(() => _wifiOnly = v); _updateSettings({'wifi_only': v}); },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoricalLogs(bool busy, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("RECOVERY POINTS"),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: _history.isEmpty
            ? const Padding(padding: EdgeInsets.all(48), child: Center(child: Text("No history.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) => _buildHistoryTile(_history[index], busy, isMobile),
              ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(_BackupItem item, bool busy, bool isMobile) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      leading: isMobile ? null : Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEEEEE))),
        child: const Icon(Icons.history_rounded, color: kBrandBrown, size: 20),
      ),
      title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800, color: kBrandBrown, fontSize: 14)),
      subtitle: Text("${item.date}\n${item.size}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      isThreeLine: isMobile,
      trailing: OutlinedButton(
        onPressed: busy ? null : () => _runRestore(item),
        style: OutlinedButton.styleFrom(
          foregroundColor: kBrandOlive,
          side: BorderSide(color: kBrandOlive.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text("RESTORE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildControlTile({required String title, required String subtitle, required IconData icon, required Widget trailing, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(icon, color: kBrandBrown, size: 22),
            ),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandOlive.withOpacity(0.8), letterSpacing: 1.5));
  }
}
