import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';

class NotificationsComponent extends StatefulWidget {
  const NotificationsComponent({super.key});

  @override
  State<NotificationsComponent> createState() => _NotificationsComponentState();
}

class _NotificationsComponentState extends State<NotificationsComponent> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all | unread
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await ApiService.getNotifications();
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _notifications = response.data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Synchronisation interrupted. Retrying...";
        });
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final response = await ApiService.markNotificationRead(id);
      if (response.statusCode == 200) _fetchNotifications();
    } catch (e) {
      debugPrint('Read error: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final response = await ApiService.deleteNotification(id);
      if (response.statusCode == 200) _fetchNotifications();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await ApiService.markAllNotificationsRead();
      if (response.statusCode == 200) _fetchNotifications();
    } catch (e) {
      debugPrint('Read all error: $e');
    }
  }

  List<dynamic> get _filteredNotifications {
    if (_filter == 'unread') {
      return _notifications.where((n) => !(n['is_read'] ?? false)).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfessionalHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : _errorMessage != null
                ? _buildErrorState()
                : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.history_toggle_off_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("System Activity Log", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text("Real-time telemetry and administrative audit trails.", 
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _filterToggle("All Activity", 'all'),
        const SizedBox(width: 12),
        _filterToggle("Action Required", 'unread'),
        const SizedBox(width: 24),
        const VerticalDivider(width: 1, indent: 10, endIndent: 10),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _fetchNotifications,
          icon: const Icon(Icons.refresh_rounded, color: kBrandOlive),
          tooltip: "Refresh Audit",
        ),
        if (_notifications.any((n) => !(n['is_read'] ?? false)))
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, color: kBrandOlive),
            tooltip: "Mark all as read",
          ),
      ],
    );
  }

  Widget _filterToggle(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBrandBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kBrandBrown : Colors.grey.shade200),
        ),
        child: Text(label.toUpperCase(), 
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildNotificationList() {
    final visible = _filteredNotifications;
    if (visible.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: kBrandOlive,
      child: ListView.builder(
        padding: const EdgeInsets.all(32),
        itemCount: visible.length,
        itemBuilder: (context, index) => _buildAuditTile(visible[index]),
      ),
    );
  }

  Widget _buildAuditTile(dynamic n) {
    final bool isRead = n['is_read'] ?? false;
    final String type = n['type'] ?? 'info';
    final String id = n['id'].toString();
    final String? actor = n['actor_name'];
    final DateTime createdAt = DateTime.parse(n['created_at']).toLocal();
    
    Color accentColor = kBrandOlive;
    IconData icon = Icons.info_outline_rounded;
    if (type == 'success') { accentColor = Colors.green; icon = Icons.check_circle_outline_rounded; }
    if (type == 'warning') { accentColor = kBrandOrange; icon = Icons.warning_amber_rounded; }
    if (type == 'error') { accentColor = Colors.red; icon = Icons.error_outline_rounded; }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : accentColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? Colors.grey.shade100 : accentColor.withOpacity(0.15)),
        boxShadow: isRead ? [] : [BoxShadow(color: accentColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        title: Text(n['message'] ?? '', 
          style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w900, color: kBrandBrown, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              if (actor != null) ...[
                Text(actor.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 0.5)),
                const SizedBox(width: 12),
                const Text("•", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
              ],
              Text(DateFormat('dd MMM yyyy, HH:mm:ss').format(createdAt), 
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead)
              IconButton(icon: const Icon(Icons.mark_chat_read_outlined, size: 20), onPressed: () => _markAsRead(id), tooltip: "Mark as read"),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), onPressed: () => _deleteNotification(id), tooltip: "Delete log"),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey.shade100),
          const SizedBox(height: 24),
          Text(_filter == 'unread' ? "Zero pending actions" : "Activity log clear", 
            style: TextStyle(color: Colors.grey.shade300, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchNotifications, child: const Text("Reconnect")),
        ],
      ),
    );
  }
}
