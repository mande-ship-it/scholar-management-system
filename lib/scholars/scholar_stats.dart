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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9AB334)));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortalHeader(isMobile),
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              children: [
                _statTile("TOTAL SCHOLARS", _stats['total']?.toString() ?? '0', Icons.groups_rounded, const Color(0xFF9AB334), true),
                const SizedBox(height: 16),
                _statTile("ACTIVE REGISTRY", _stats['active']?.toString() ?? '0', Icons.check_circle_outline_rounded, Colors.blue, true),
                const SizedBox(height: 16),
                _statTile("PENDING APPROVAL", _stats['pending']?.toString() ?? '0', Icons.pending_actions_rounded, const Color(0xFFE05B1C), true),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _statTile("TOTAL SCHOLARS", _stats['total']?.toString() ?? '0', Icons.groups_rounded, const Color(0xFF9AB334), false)),
                const SizedBox(width: 24),
                Expanded(child: _statTile("ACTIVE REGISTRY", _stats['active']?.toString() ?? '0', Icons.check_circle_outline_rounded, Colors.blue, false)),
                const SizedBox(width: 24),
                Expanded(child: _statTile("PENDING APPROVAL", _stats['pending']?.toString() ?? '0', Icons.pending_actions_rounded, const Color(0xFFE05B1C), false)),
              ],
            ),
          const SizedBox(height: 32),
          _buildDataAnalysisSections(isMobile),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "COHORT ANALYTICS",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF9AB334),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Scholar Statistics",
          style: TextStyle(
            fontSize: isMobile ? 22 : 28, 
            fontWeight: FontWeight.w900, 
            color: const Color(0xFF4C3C32), 
            letterSpacing: -0.5
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Longitudinal data analysis for program cohorts and institutional performance.",
          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: isMobile ? 24 : 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDataAnalysisSections(bool isMobile) {
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
          SizedBox(height: 100, child: Center(child: Text("Detailed distribution charts loading...", style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }

}
