import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';

class SchoolStatsComponent extends StatefulWidget {
  const SchoolStatsComponent({super.key});

  @override
  State<SchoolStatsComponent> createState() => _SchoolStatsComponentState();
}

class _SchoolStatsComponentState extends State<SchoolStatsComponent> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, you might have a specific endpoint for school stats
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        final List schools = response.data['data'] ?? [];
        setState(() {
          _stats = {
            'total': schools.length,
            'active': schools.where((s) => s['status'] == 'Active').length,
          };
        });
      }
    } catch (e) {
      debugPrint('Error fetching school stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School Statistics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text("Total Schools: ${_stats['total'] ?? 0}"),
          Text("Active Schools: ${_stats['active'] ?? 0}"),
        ],
      ),
    );
  }
}
