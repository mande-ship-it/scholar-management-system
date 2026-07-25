import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../events/events_utils.dart';
import 'package:intl/intl.dart';

class RecentActivitiesComponent extends StatefulWidget {
  const RecentActivitiesComponent({super.key});

  @override
  State<RecentActivitiesComponent> createState() => _RecentActivitiesComponentState();
}

class _RecentActivitiesComponentState extends State<RecentActivitiesComponent> {
  bool _isLoading = true;
  List<OrganisationEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllEvents();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final allEvents = data.map((json) => OrganisationEvent.fromJson(json)).toList();

        // Filter: Keep upcoming events and very recent history (last 7 days)
        final now = DateTime.now();
        final filtered = allEvents.where((e) {
          return e.fullDateTime.isAfter(now.subtract(const Duration(days: 7)));
        }).toList();

        // Sort: Upcoming first, closest to now first
        filtered.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));

        if (mounted) {
          setState(() {
            _events = filtered.take(5).toList(); // Show top 5 relevant activities
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching recent activities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandCreamDark = Color(0xFFF3E7C4);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

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
                const Icon(Icons.event_note, color: brandOrange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  "Recent & Upcoming Activities",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: brandBrown),
                    onPressed: _fetchEvents,
                    tooltip: "Refresh Activities",
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Track key activities, cohort syncs, and administrative deadlines scheduled for AGE Africa scholars.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 30),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: brandOlive),
                ),
              )
            else if (_events.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFEEECE5)),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  final month = DateFormat('MMM').format(event.date).toUpperCase();
                  final day = DateFormat('dd').format(event.date);

                  return InkWell(
                    onTap: () => _showEventDetails(context, event),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Badge Widget
                          Container(
                            width: 55,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: brandCreamDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: event.isUpcoming ? brandOrange : Colors.grey,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      month,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: brandCream,
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: brandBrown,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Event info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: brandBrown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: brandOlive.withOpacity(0.8)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Venue: ${event.location}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: brandOlive.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No recent or upcoming activities found.",
              style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, OrganisationEvent event) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    final fullDate = DateFormat('dd MMMM yyyy').format(event.date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: brandBrown,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Icon(event.category.icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.calendar_today, "Date", fullDate, brandOrange),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, "Time", event.time.format(context), brandBrown),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, "Venue", event.location, brandOlive),
            const SizedBox(height: 24),
            const Text(
              "Event Description",
              style: TextStyle(fontWeight: FontWeight.bold, color: brandBrown, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: brandBrown, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4C3C32))),
          ],
        ),
      ],
    );
  }
}
