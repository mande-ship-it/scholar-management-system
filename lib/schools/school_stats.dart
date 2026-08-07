import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

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
      return Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F2F5), // Facebook-style background
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 1)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Institutional Statistics",
                    style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: kBrandBrown),
                  ),
                  const SizedBox(height: 8),
                  const Text("Analysis of partner schools and reach metrics.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isMobile)
              Column(
                children: [
                  _statTile("Total Schools", _stats['total']?.toString() ?? '0', Icons.apartment_rounded, kBrandBrown, true),
                  const SizedBox(height: 12),
                  _statTile("Active Partnerships", _stats['active']?.toString() ?? '0', Icons.check_circle_outline_rounded, kBrandOlive, true),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _statTile("Total Schools", _stats['total']?.toString() ?? '0', Icons.apartment_rounded, kBrandBrown, false)),
                  const SizedBox(width: 20),
                  Expanded(child: _statTile("Active Partnerships", _stats['active']?.toString() ?? '0', Icons.check_circle_outline_rounded, kBrandOlive, false)),
                ],
              ),
          ],
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
