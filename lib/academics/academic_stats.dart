import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';

import '../academics/academics_utils.dart';

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
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academic Performance Analytics",
            style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: kBrandBrown),
          ),
          const SizedBox(height: 8),
          const Text("Detailed breakdown of scholarly achievements.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              children: [
                _statTile("General Average", "${_stats['avgScore'] ?? 0}%", Icons.analytics_rounded, kBrandOlive, true),
                const SizedBox(height: 16),
                _statTile("Passing Scholars", "${_stats['onTrack'] ?? 0}", Icons.verified_user_rounded, kBrandOrange, true),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _statTile("General Average", "${_stats['avgScore'] ?? 0}%", Icons.analytics_rounded, kBrandOlive, false)),
                const SizedBox(width: 24),
                Expanded(child: _statTile("Passing Scholars", "${_stats['onTrack'] ?? 0}", Icons.verified_user_rounded, kBrandOrange, false)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, bool isFullWidth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
            ],
          ),
        ],
      ),
    );
  }
}
