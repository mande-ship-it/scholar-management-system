import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

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

  final Color brandBrown = const Color(0xFF4C3C32);
  final Color brandOlive = const Color(0xFF9AB334);
  final Color brandOrange = const Color(0xFFE05B1C);

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
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Could not load notifications. Please check your connection.";
        });
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final response = await ApiService.markNotificationRead(id);
      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final response = await ApiService.deleteNotification(id);
      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await ApiService.markAllNotificationsRead();
      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9AB334)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchNotifications,
              style: ElevatedButton.styleFrom(backgroundColor: brandOlive, foregroundColor: Colors.white),
              child: const Text("Retry"),
            )
          ],
        ),
      );
    }

    final visible = _filteredNotifications;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_toggle_off, color: brandBrown, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Activity & Notifications",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandBrown),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildFilterChip("All", 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip("Unread", 'unread'),
                  const SizedBox(width: 12),
                  if (_notifications.any((n) => !(n['is_read'] ?? false)))
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text("MARK ALL READ"),
                      style: TextButton.styleFrom(foregroundColor: brandOlive, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  IconButton(
                    onPressed: _fetchNotifications,
                    icon: const Icon(Icons.refresh),
                    tooltip: "Refresh Feed",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: brandOlive,
              child: visible.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: visible.length,
                      itemBuilder: (context, index) => _buildNotificationTile(visible[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _filter = value);
      },
      selectedColor: brandOlive.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? brandOlive : Colors.grey,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _filter == 'unread' ? "No unread notifications" : "Your activity log is empty",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(dynamic n) {
    final bool isRead = n['is_read'] ?? false;
    final String type = n['type'] ?? 'info';
    final String id = n['id'].toString();
    final String? actor = n['actor_name'];
    
    IconData icon = Icons.info_outline;
    Color color = brandOlive;
    if (type == 'success') { icon = Icons.check_circle_outline; color = Colors.green; }
    if (type == 'warning') { icon = Icons.warning_amber_rounded; color = brandOrange; }
    if (type == 'error') { icon = Icons.error_outline; color = Colors.red; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? Colors.grey.shade100 : color.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          n['message'] ?? '',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? Colors.black87 : brandBrown,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (actor != null)
                Text(
                  actor.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              Text(
                _formatTime(n['created_at']),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead)
              IconButton(
                icon: const Icon(Icons.mark_email_read_outlined, size: 20, color: Colors.blueGrey),
                onPressed: () => _markAsRead(id),
                tooltip: "Mark as read",
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: () => _deleteNotification(id),
              tooltip: "Remove",
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "Unknown time";
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays == 1) return "Yesterday at ${DateFormat('HH:mm').format(date)}";
      if (diff.inDays < 7) return "${diff.inDays} days ago";

      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }
}
