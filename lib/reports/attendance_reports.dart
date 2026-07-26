import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

class AttendanceReportsComponent extends StatefulWidget {
  const AttendanceReportsComponent({super.key});

  @override
  State<AttendanceReportsComponent> createState() => _AttendanceReportsComponentState();
}

class _AttendanceReportsComponentState extends State<AttendanceReportsComponent> {
  String _selectedMonth = 'July 2026';
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAttendanceReport(month: _selectedMonth);
      if (response.statusCode == 200) {
        setState(() {
          _data = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance report: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final metrics = _data?['metrics'] ?? {};
    final trends = _data?['trends'] as List? ?? [];
    final reasons = _data?['reasons'] as List? ?? [];
    final scholars = _data?['scholars'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clean Header
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // 2. Control Row
          _buildControls(),
          
          const SizedBox(height: 24),
          
          // 3. Key Metrics
          Row(
            children: [
              _metricCard("Average Attendance", "${metrics['avg_rate'] ?? 0}%", kBrandOlive, Icons.rule_rounded),
              const SizedBox(width: 16),
              _metricCard("Perfect Attendance", "${metrics['perfect_attendance'] ?? 0} Scholars", kBrandBrown, Icons.verified_rounded),
              const SizedBox(width: 16),
              _metricCard("Critical Lows", "${metrics['critical_lows'] ?? 0}", Colors.red, Icons.warning_amber_rounded),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 4. Main Report Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _reportSection(
                  title: "Monthly Attendance Trends",
                  child: _buildTrendsChart(trends),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "Absence Reasons",
                  child: _buildReasonBreakdown(reasons),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. Attendance Detail Preview
          _reportSection(
            title: "Scholar Attendance Summary",
            child: _buildAttendanceTable(scholars),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBrandOlive.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.event_available_rounded, color: kBrandOlive, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Reports', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SizedBox(height: 4),
              Text('Monitor program engagement, punctuality, and retention metrics.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.summarize_outlined, size: 18),
          label: const Text("Export Summary"),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _dropdownControl("Select Month", _selectedMonth, ['May 2026', 'June 2026', 'July 2026'], (v) {
            setState(() => _selectedMonth = v!);
            _fetchReport();
          }),
          const Spacer(),
          TextButton.icon(
            onPressed: _fetchReport,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _dropdownControl(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isDense: true,
          underline: const SizedBox(),
          style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandBrown)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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

  Widget _buildTrendsChart(List trends) {
    if (trends.isEmpty) return const Center(child: Text("No trend data available"));
    return Column(
      children: trends.map((t) => _chartBar(
        "Week ${t['week']}",
        (double.parse(t['rate'].toString()) / 100),
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
            child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonBreakdown(List reasons) {
    if (reasons.isEmpty) return const Center(child: Text("No absence data"));
    final List<Color> colors = [Colors.blue, kBrandOrange, kBrandBrown, Colors.grey];
    return Column(
      children: reasons.asMap().entries.map((entry) {
        final r = entry.value;
        final color = colors[entry.key % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(r['reason'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Text("${r['percentage']}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceTable(List scholars) {
    if (scholars.isEmpty) return const Center(child: Text("No scholars data"));
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Scholar Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Present", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Absent", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          ],
        ),
        ...scholars.map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['full_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['present']?.toString() ?? '0', style: const TextStyle(fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['absent']?.toString() ?? '0', style: const TextStyle(fontSize: 13, color: Colors.red))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("${s['rate'] ?? 0}%", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive))),
          ],
        )),
      ],
    );
  }
}
