import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';

class AcademicStatsComponent extends StatefulWidget {
  const AcademicStatsComponent({super.key});

  @override
  State<AcademicStatsComponent> createState() => _AcademicStatsComponentState();
}

class _AcademicStatsComponentState extends State<AcademicStatsComponent> {
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
      // Endpoint might vary, using a plausible one based on common patterns
      final response = await ApiService.getDashboardStats();
      if (response.statusCode == 200) {
        setState(() {
          _stats = response.data['data'] ?? {};
        });
      }
    } catch (e) {
      debugPrint('Error fetching academic stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Academic Statistics",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text("Average Marks: ${_stats['avgScore'] ?? 0}%"),
      ],
    );
  }
}
