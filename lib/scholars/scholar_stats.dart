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
              "Cohort Analytics",
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
            tooltip: "Refresh Stats",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          _buildPortalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                ),
              ),
            ),
          ),
        ],
      ),
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
