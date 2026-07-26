import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../events/events_utils.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class RecentActivitiesComponent extends StatefulWidget {
  const RecentActivitiesComponent({super.key});

  @override
  State<RecentActivitiesComponent> createState() => _RecentActivitiesComponentState();
}

class _RecentActivitiesComponentState extends State<RecentActivitiesComponent> {
  bool _isLoading = true;
  List<OrganisationEvent> _events = [];
  IO.Socket? _socket;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _initSocket();
    // Auto-remove overdue items by refreshing the filter every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _filterOverdueLocally());
  }

  void _initSocket() {
    try {
      _socket = IO.io('http://localhost:5000', IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build());

      _socket!.connect();
      _socket!.on('notification', (data) {
        // Refresh events if anything related to events or approvals happens
        final msg = (data['message'] ?? '').toString().toLowerCase();
        if (msg.contains('event') || msg.contains('approved') || msg.contains('deleted')) {
          _fetchEvents();
        }
      });
    } catch (e) {
      debugPrint('Socket error in RecentActivities: $e');
    }
  }

  void _filterOverdueLocally() {
    if (!mounted || _events.isEmpty) return;
    setState(() {
      final now = DateTime.now();
      _events.removeWhere((e) => e.fullDateTime.isBefore(now));
    });
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllEvents();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final allEvents = data.map((json) => OrganisationEvent.fromJson(json)).toList();
        final now = DateTime.now();
        
        // Filter: Approved AND in the future
        final filtered = allEvents.where((e) {
          final isApproved = e.status != 'Pending';
          final isFuture = e.fullDateTime.isAfter(now);
          return isApproved && isFuture;
        }).toList();

        filtered.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));

        if (mounted) {
          setState(() {
            _events = filtered.take(5).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching recent activities: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.event_note_rounded, color: brandOrange, size: 22),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Upcoming Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brandBrown, letterSpacing: -0.5)),
                    Text("Key deadlines and programs", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: brandOlive)))
            else if (_events.isEmpty)
              const Center(child: Text("No upcoming activities", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      onTap: () => _showEventPopup(context, event),
                      leading: CircleAvatar(
                        backgroundColor: brandOrange.withOpacity(0.1),
                        child: Text(
                          DateFormat('dd').format(event.date),
                          style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: brandBrown),
                      ),
                      subtitle: Text(
                        event.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEventPopup(BuildContext context, OrganisationEvent event) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: event.category.color.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Row(
            children: [
              Icon(event.category.icon, color: event.category.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(color: brandBrown, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.calendar_today_rounded, "Date", DateFormat('dd MMMM yyyy').format(event.date), brandOrange),
            const SizedBox(height: 16),
            _detailRow(Icons.access_time_rounded, "Time", event.time.format(context), brandBrown),
            const SizedBox(height: 16),
            _detailRow(Icons.place_rounded, "Location", event.location, brandOlive),
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 15, height: 1.5, color: brandBrown),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4C3C32))),
          ],
        ),
      ],
    );
  }
}
