import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class ScholarStatsComponent extends StatefulWidget {
  const ScholarStatsComponent({super.key});

  @override
  State<ScholarStatsComponent> createState() => _ScholarStatsComponentState();
}

class _ScholarStatsComponentState extends State<ScholarStatsComponent> {
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
      final response = await ApiService.getScholarStats();
      if (response.statusCode == 200) {
        setState(() {
          _stats = response.data['data'] ?? {};
        });
      }
    } catch (e) {
      debugPrint('Error fetching scholar stats: $e');
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
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Scholar Statistics",
            style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: kBrandBrown),
          ),
          const SizedBox(height: 8),
          Text("Centralized data analysis for program cohorts.", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              children: [
                _statTile("Total Scholars", _stats['total']?.toString() ?? '0', Icons.groups_rounded, kBrandOlive, true),
                const SizedBox(height: 12),
                _statTile("Active Registry", _stats['active']?.toString() ?? '0', Icons.check_circle_outline_rounded, Colors.blue, true),
                const SizedBox(height: 12),
                _statTile("Pending Approval", _stats['pending']?.toString() ?? '0', Icons.pending_actions_rounded, kBrandOrange, true),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _statTile("Total Scholars", _stats['total']?.toString() ?? '0', Icons.groups_rounded, kBrandOlive, false)),
                const SizedBox(width: 16),
                Expanded(child: _statTile("Active Registry", _stats['active']?.toString() ?? '0', Icons.check_circle_outline_rounded, Colors.blue, false)),
                const SizedBox(width: 16),
                Expanded(child: _statTile("Pending Approval", _stats['pending']?.toString() ?? '0', Icons.pending_actions_rounded, kBrandOrange, false)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, bool isFullWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
