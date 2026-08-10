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
          _errorMessage = "Connection to notification server interrupted.";
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

  Widget _buildExecutiveHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  "Communications Hub",
                  style: TextStyle(
                    fontSize: isVerySmall ? 13 : 16, 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF4C3C32), 
                    letterSpacing: -0.2
                  ),
                ),
              ),
              IconButton(
                onPressed: _fetchNotifications,
                icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
                tooltip: "Sync Notifications",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              if (_notifications.any((n) => !(n['is_read'] ?? false)))
                IconButton(
                  onPressed: _markAllAsRead,
                  icon: Icon(Icons.done_all_rounded, color: kBrandOlive, size: 24),
                  tooltip: "Mark All Read",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabButton("ALL LOGS", 'all', isMobile),
                const SizedBox(width: 8),
                _tabButton("UNREAD", 'unread', isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(isMobile),
          if (!isMobile) _buildSummaryBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : _errorMessage != null
                ? _buildErrorState()
                : _buildNotificationContent(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToggles() {
    return Row(
      children: [
        _tabButton("ALL LOGS", 'all', false),
        const SizedBox(width: 8),
        _tabButton("UNREAD", 'unread', false),
        const SizedBox(width: 24),
        Container(width: 1, height: 32, color: Colors.grey.shade200),
        const SizedBox(width: 24),
        OutlinedButton.icon(
          onPressed: _fetchNotifications,
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: const Text("SYNC"),
          style: OutlinedButton.styleFrom(
            foregroundColor: kBrandOlive,
            side: BorderSide(color: kBrandOlive.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_notifications.any((n) => !(n['is_read'] ?? false))) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text("MARK ALL READ"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabButton(String label, String value, bool isMobile) {
    final bool isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kBrandBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, 
          style: TextStyle(
            fontSize: isMobile ? 10 : 11, 
            fontWeight: FontWeight.w900, 
            color: isSelected ? Colors.white : Colors.grey.shade600,
            letterSpacing: 1.0,
          )),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final unreadCount = _notifications.where((n) => !(n['is_read'] ?? false)).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _summaryItem(Icons.mark_as_unread_rounded, "$unreadCount Pending Alerts", kBrandOrange),
          const SizedBox(width: 32),
          _summaryItem(Icons.assessment_outlined, "${_notifications.length} Total Entries", kBrandBrown),
          const Spacer(),
          Text(
            "Last Synced: ${DateFormat('HH:mm:ss').format(DateTime.now())}",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kBrandBrown.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildNotificationContent(bool isMobile) {
    final visible = _filteredNotifications;
    if (visible.isEmpty) return _buildEmptyState();

    // Grouping by relative date
    final Map<String, List<dynamic>> grouped = {};
    for (var n in visible) {
      DateTime date = DateTime.now();
      try {
        final dateStr = n['createdAt'] ?? n['created_at'];
        if (dateStr != null) date = DateTime.parse(dateStr).toLocal();
      } catch (_) {}
      
      String dayKey;
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        dayKey = "TODAY";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        dayKey = "YESTERDAY";
      } else {
        dayKey = DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
      }
      
      grouped.putIfAbsent(dayKey, () => []).add(n);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 32, 8, isMobile ? 12 : 32, 40),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final items = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 4),
              child: Text(key, 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.5)),
            ),
            ...items.map((item) => _buildProfessionalTile(item, isMobile)),
          ],
        );
      },
    );
  }

  Widget _buildProfessionalTile(dynamic n, bool isMobile) {
    final bool isRead = n['isRead'] ?? n['is_read'] ?? false;
    final String type = n['type'] ?? 'info';
    final String id = (n['id'] ?? n['_id'] ?? '').toString();
    final String? actor = n['actorName'] ?? n['actor_name'];
    
    DateTime createdAt = DateTime.now();
    try {
      final dateStr = n['createdAt'] ?? n['created_at'];
      if (dateStr != null) createdAt = DateTime.parse(dateStr).toLocal();
    } catch (_) {}
    
    Color severityColor = kBrandOlive;
    IconData icon = Icons.info_outline_rounded;
    if (type == 'success') { severityColor = Colors.green.shade600; icon = Icons.verified_user_rounded; }
    if (type == 'warning') { severityColor = Colors.amber.shade800; icon = Icons.report_problem_rounded; }
    if (type == 'error') { severityColor = Colors.red.shade700; icon = Icons.gavel_rounded; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRead ? Colors.grey.shade100 : severityColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: isRead ? Colors.grey.shade200 : severityColor,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['message'] ?? '', 
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, 
                                color: kBrandBrown, 
                                fontSize: isMobile ? 13 : 15,
                                height: 1.4,
                              )),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (actor != null) ...[
                                  Text(isMobile ? actor : "BY $actor".toUpperCase(), 
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandBrown.withOpacity(0.4), letterSpacing: 0.5)),
                                  const SizedBox(width: 8),
                                  const Text("•", style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 8),
                                ],
                                Text(DateFormat('HH:mm').format(createdAt), 
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          if (!isRead)
                            _miniAction(Icons.check_circle_outline_rounded, "READ", severityColor, () => _markAsRead(id)),
                          if (!isRead) const SizedBox(height: 8),
                          _miniAction(Icons.delete_sweep_outlined, "PURGE", Colors.red.shade400, () => _deleteNotification(id)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color.withOpacity(0.6)),
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color.withOpacity(0.6))),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100, width: 4)),
            child: Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade200),
          ),
          const SizedBox(height: 24),
          Text(_filter == 'unread' ? "NO PENDING ALERTS" : "ACTIVITY LOG CLEAR", 
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text("All systems are operational and quiet.", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade200),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchNotifications, 
            style: ElevatedButton.styleFrom(backgroundColor: kBrandBrown),
            child: const Text("FORCE RECONNECT"),
          ),
        ],
      ),
    );
  }
}
