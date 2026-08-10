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
      return const SizedBox.shrink();
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPortalHeader(isMobile),
            const SizedBox(height: 32),
            if (isMobile)
              Column(
                children: [
                  _statTile("GENERAL SCORE AVERAGE", "${_stats['avgScore'] ?? 0}%", Icons.analytics_rounded, const Color(0xFF9AB334), true),
                  const SizedBox(height: 16),
                  _statTile("SCHOLARS IN PASSING", "${_stats['onTrack'] ?? 0}", Icons.verified_user_rounded, const Color(0xFFE05B1C), true),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _statTile("GENERAL SCORE AVERAGE", "${_stats['avgScore'] ?? 0}%", Icons.analytics_rounded, const Color(0xFF9AB334), false)),
                  const SizedBox(width: 24),
                  Expanded(child: _statTile("SCHOLARS IN PASSING", "${_stats['onTrack'] ?? 0}", Icons.verified_user_rounded, const Color(0xFFE05B1C), false)),
                ],
              ),
            const SizedBox(height: 32),
            _buildDetailedAnalyticsMatrix(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              "Academic Achievement",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          IconButton(
            onPressed: _fetchStats,
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Refresh",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, bool isFullWidth) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: const TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  color: Color(0xFF4C3C32), 
                  letterSpacing: -1
                )
              ),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 9, 
                  color: Colors.grey.shade400, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.2
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalyticsMatrix(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("DISTRIBUTION ANALYSIS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          SizedBox(height: 100, child: Center(child: Text("Detailed achievement matrices loading...", style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
}
