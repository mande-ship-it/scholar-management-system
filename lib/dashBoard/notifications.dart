import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/file_download_service.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class NotificationsComponent extends StatefulWidget {
  const NotificationsComponent({super.key});

  @override
  State<NotificationsComponent> createState() => _NotificationsComponentState();
}

class _NotificationsComponentState extends State<NotificationsComponent> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _isExporting = false;

  final Color brandBrown = const Color(0xFF4C3C32);
  final Color brandCream = const Color(0xFFFAF2DB);
  final Color brandOlive = const Color(0xFF9AB334);
  final Color brandOrange = const Color(0xFFE05B1C);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getNotifications();
      if (response.statusCode == 200) {
        setState(() {
          _notifications = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService.markNotificationRead(id);
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final response = await ApiService.deleteNotification(id);
      if (response.statusCode == 200) {
        _fetchNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notification deleted"), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.exportToExcel(['Scholar Master List']);
      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        await FileDownloadService.downloadFile(
          bytes: bytes,
          fileName: "Dashboard_Scholar_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx",
        );
        _showSuccessSnack("Excel export downloaded.");
      }
    } catch (e) {
      _showErrorSnack("Export failed. Please check connection.");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportPdf() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.exportToPDF(['Scholar Profiles & Summaries']);
      if (response.statusCode == 200) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        await Printing.sharePdf(
          bytes: bytes,
          filename: "Dashboard_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
        );
        _showSuccessSnack("PDF report generated.");
      }
    } catch (e) {
      _showErrorSnack("PDF generation failed.");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.runBackup("Manual Dashboard Backup");
      if (response.statusCode == 200) {
        _showSuccessSnack("Database backup completed successfully.");
      }
    } catch (e) {
      _showErrorSnack("Backup process failed.");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: brandOlive, behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF9AB334)))
        : SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 950) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildActivityCard(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildQuickActionsCard(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildActivityCard(),
                      const SizedBox(height: 24),
                      _buildQuickActionsCard(),
                    ],
                  );
                }
              },
            ),
          );
  }

  Widget _buildActivityCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_toggle_off, color: brandBrown, size: 28),
                const SizedBox(width: 12),
                Text(
                  "Recent System Activity Log",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _fetchNotifications,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Refresh"),
                )
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Audit logs showing updates and inputs made by different department roles.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 30),
            if (_notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No recent activities found."),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notifications.length > 8 ? 8 : _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 20, color: Color(0xFFF7F5EE)),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final bool isRead = notification['is_read'] ?? false;
                  final String type = notification['type'] ?? 'info';
                  final String id = notification['id'].toString();

                  IconData icon = Icons.info_outline;
                  Color color = brandOlive;
                  if (type == 'success') { icon = Icons.check_circle_outline; color = Colors.green; }
                  if (type == 'warning') { icon = Icons.warning_amber_rounded; color = brandOrange; }
                  if (type == 'error') { icon = Icons.error_outline; color = Colors.red; }

                  return Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isRead ? null : () => _markAsRead(id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: color.withOpacity(0.12),
                                  child: Icon(icon, color: color, size: 16),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['message'],
                                        style: TextStyle(
                                          color: isRead ? Colors.grey : Colors.black87,
                                          fontSize: 13,
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(notification['created_at']),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _deleteNotification(id),
                        tooltip: "Delete Log",
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "Unknown time";
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} minutes ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Operations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: brandBrown,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Execute critical system processes and generate real-time reports.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 30),
            _buildActionRow(
              icon: Icons.table_view,
              label: "Export Scholar Excel",
              btnColor: brandOlive,
              isLoading: _isExporting,
              onPressed: _handleExportExcel,
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              icon: Icons.picture_as_pdf,
              label: "Generate System PDF",
              btnColor: brandOrange,
              isLoading: _isExporting,
              onPressed: _handleExportPdf,
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              icon: Icons.backup_outlined,
              label: "Run Database Backup",
              btnColor: brandBrown,
              isLoading: _isExporting,
              onPressed: _handleBackup,
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              icon: Icons.notifications_active_outlined,
              label: "Refresh Notification Feed",
              btnColor: Colors.blueGrey,
              isLoading: _isLoading,
              onPressed: _fetchNotifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required Color btnColor,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isLoading
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 16, color: Colors.white),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
