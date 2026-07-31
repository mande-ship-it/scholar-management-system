import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return const Center(child: Text("No recent activities found."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Activities",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activities.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.history)),
              title: Text(activity['description'] ?? 'No description'),
              subtitle: Text(activity['created_at'] ?? ''),
            );
          },
        ),
      ],
    );
  }
}
