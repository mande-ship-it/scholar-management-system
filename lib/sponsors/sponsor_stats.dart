import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';

class SponsorStatsComponent extends StatefulWidget {
  const SponsorStatsComponent({super.key});

  @override
  State<SponsorStatsComponent> createState() => _SponsorStatsComponentState();
}

class _SponsorStatsComponentState extends State<SponsorStatsComponent> {
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
      final response = await ApiService.getSponsorStats();
      if (response.statusCode == 200) {
        setState(() {
          _stats = response.data['data'] ?? {};
        });
      }
    } catch (e) {
      debugPrint('Error fetching sponsor stats: $e');
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
          "Sponsor Statistics",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text("Total Sponsors: ${_stats['total'] ?? 0}"),
      ],
    );
  }
}
