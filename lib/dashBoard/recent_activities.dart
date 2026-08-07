import 'package:flutter/material.dart';
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: kBrandOlive.withOpacity(0.1),
                child: Icon(Icons.flash_on_rounded, color: kBrandOlive, size: 18),
              ),
              title: Text(
                message, 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
              ),
              subtitle: Text(
                "By $actor • ${activity['created_at'] ?? ''}",
                style: const TextStyle(fontSize: 11)
              ),
            );
          },
        ),
      ],
    );
  }
}
