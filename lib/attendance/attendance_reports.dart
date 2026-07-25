import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

class AttendanceReportsComponent extends StatefulWidget {
  const AttendanceReportsComponent({super.key});

  @override
  State<AttendanceReportsComponent> createState() => _AttendanceReportsComponentState();
}

class _AttendanceReportsComponentState extends State<AttendanceReportsComponent> {
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAttendanceAnalytics();
      if (response.statusCode == 200) {
        setState(() {
          _analytics = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance analytics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(80), child: CircularProgressIndicator(color: kBrandOlive)));
    }

    if (_analytics == null) {
      return const Center(child: Text("Failed to load attendance analytics."));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clean Header (No Banners)
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // 2. Control Row
          _buildControls(),

          const SizedBox(height: 24),
          
          // 4. Main Report Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _reportSection(
                  title: "Attendance Growth Trends",
                  child: _buildTrendsChart(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "Critical Alerts",
                  child: _buildAlertsList(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. Regional Summary
          _reportSection(
            title: "School-wise Attendance Summary",
            child: _buildAttendanceTable(),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandOlive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assessment_rounded,
                color: kBrandOlive, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Analytics',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kBrandBrown)),
                const SizedBox(height: 4),
                Text('Program-wide attendance metrics and trend analysis.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text("Export Data"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final stats = _analytics!['stats'] ?? {};
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statSummary("Total Logs", stats['total']?.toString() ?? '0', kBrandBrown),
          _statSummary("Present", stats['present']?.toString() ?? '0', kBrandOlive),
          _statSummary("Absent", stats['absent']?.toString() ?? '0', Colors.red),
          _statSummary("Late", stats['late']?.toString() ?? '0', Colors.orange),
        ],
      ),
    );
  }

  Widget _statSummary(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _reportSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    final trends = (_analytics!['trends'] as List? ?? []);
    if (trends.isEmpty) return const Center(child: Text("Insufficient data for trends.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));

    return Column(
      children: trends.map((t) => _chartBar(
        "Week of ${t['week_start']}",
        (t['attendance_rate'] as num).toDouble() / 100,
        kBrandOlive
      )).toList(),
    );
  }

  Widget _chartBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: Colors.grey.shade50),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    final alerts = (_analytics!['alerts'] as List? ?? []);
    if (alerts.isEmpty) return const Center(child: Text("No active alerts.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));

    return Column(
      children: alerts.map((a) {
        Color color = kBrandOlive;
        if (a['type'] == 'danger') color = Colors.red;
        if (a['type'] == 'warning') color = Colors.orange;
        return _alertItem(a['title'] ?? '', a['subtitle'] ?? '', color);
      }).toList(),
    );
  }

  Widget _alertItem(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    final summary = (_analytics!['summary'] as List? ?? []);
    if (summary.isEmpty) return const Center(child: Text("No school data available.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.2),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("School Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Present", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Avg Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          ],
        ),
        ...summary.map((s) {
          final rate = double.parse(s['avg_rate']?.toString() ?? '0');
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['school_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['active_scholars']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['present_logs']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("$rate%", style: TextStyle(fontWeight: FontWeight.bold, color: rate >= 85 ? kBrandOlive : kBrandOrange))),
            ],
          );
        }),
      ],
    );
  }
}
