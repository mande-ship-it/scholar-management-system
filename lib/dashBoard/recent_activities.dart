import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class RecentActivitiesComponent extends StatefulWidget {
  const RecentActivitiesComponent({super.key});

  @override
  State<RecentActivitiesComponent> createState() => _RecentActivitiesComponentState();
}

class _RecentActivitiesComponentState extends State<RecentActivitiesComponent> {
  bool _isLoading = true;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getRecentActivities();
      if (response.statusCode == 200) {
        setState(() {
          _activities = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent activities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    if (_activities.isEmpty) {
      return const Center(child: Text("No recent activities found."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activities",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activities.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final activity = _activities[index];
            final String actor = activity['actorName'] ?? 'System';
            final String message = activity['message'] ?? 'No description';
            final String timeStr = _formatTime(activity['created_at'] ?? activity['createdAt']);
            
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.flash_on_rounded, color: kBrandOlive, size: 18),
              ),
              title: Text(
                message, 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)
              ),
              subtitle: Text(
                "By $actor • $timeStr",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "Recently";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return DateFormat('dd MMM, HH:mm').format(date);
    } catch (_) {
      return "Recently";
    }
  }
}
