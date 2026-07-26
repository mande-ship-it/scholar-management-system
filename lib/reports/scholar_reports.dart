import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

class ScholarReportsComponent extends StatefulWidget {
  const ScholarReportsComponent({super.key});

  @override
  State<ScholarReportsComponent> createState() => _ScholarReportsComponentState();
}

class _ScholarReportsComponentState extends State<ScholarReportsComponent> {
  String _selectedPeriod = 'Annual (2026)';
  String _reportType = 'Performance Summary';
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
      final response = await ApiService.getScholarReport(
        period: _selectedPeriod,
        type: _reportType,
      );
      if (response.statusCode == 200) {
        setState(() {
          _data = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching scholar report: $e');
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
    final distribution = _data?['distribution'] as List? ?? [];
    final regional = _data?['regional'] as List? ?? [];
    final scholars = _data?['scholars'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Fixed Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: _buildHeader(),
        ),

        const Divider(height: 1),

        // 2. Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Control Row
                _buildControls(),

                const SizedBox(height: 24),

                // Key Metrics
                Row(
                  children: [
                    _metricCard("Total Active", "${metrics['total_active'] ?? 0}", kBrandOlive, Icons.people_outline_rounded),
                    const SizedBox(width: 16),
                    _metricCard("Average Performance", "${metrics['avg_performance'] ?? 0}%", kBrandBrown, Icons.auto_graph_rounded),
                    const SizedBox(width: 16),
                    _metricCard("Scholarship Disbursed", "MWK ${metrics['total_disbursed'] ?? 0}", kBrandOrange, Icons.payments_outlined),
                  ],
                ),

                const SizedBox(height: 24),

                // Main Report Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _reportSection(
                        title: "Performance Distribution",
                        child: _buildPerformanceChart(distribution),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _reportSection(
                        title: "Regional Summary",
                        child: _buildRegionalBreakdown(regional),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Detailed Table Preview
                _reportSection(
                  title: "Detailed Scholar Performance Preview",
                  child: _buildScholarTable(scholars),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBrandBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description_rounded, color: kBrandBrown, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scholar Reports', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SizedBox(height: 4),
              Text('Comprehensive data visualization and scholar progress reports.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text("Generate PDF"),
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
          _dropdownControl("Report Type", _reportType, ['Performance Summary', 'Financial Support', 'Demographics'], (v) {
            setState(() => _reportType = v!);
            _fetchReport();
          }),
          const SizedBox(width: 20),
          _dropdownControl("Time Period", _selectedPeriod, ['Term 1 2026', 'Term 2 2026', 'Annual (2026)'], (v) {
            setState(() => _selectedPeriod = v!);
            _fetchReport();
          }),
          const Spacer(),
          TextButton.icon(
            onPressed: _fetchReport,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Refresh Data"),
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

  Widget _buildPerformanceChart(List distribution) {
    if (distribution.isEmpty) return const Center(child: Text("No distribution data"));
    return Column(
      children: distribution.map((d) {
        Color color = kBrandOlive;
        if (d['label'].toString().contains('Exceeding')) color = Colors.green;
        if (d['label'].toString().contains('Approaching')) color = kBrandOrange;
        if (d['label'].toString().contains('Needs')) color = Colors.red;

        return _chartBar(d['label'], (double.parse(d['percentage'].toString()) / 100), color);
      }).toList(),
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

  Widget _buildRegionalBreakdown(List regional) {
    if (regional.isEmpty) return const Center(child: Text("No regional data"));
    final List<Color> colors = [kBrandBrown, kBrandOlive, kBrandOrange, Colors.blue, Colors.teal];
    return Column(
      children: regional.asMap().entries.map((entry) {
        final r = entry.value;
        final color = colors[entry.key % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(r['region'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Text(r['count'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScholarTable(List scholars) {
    if (scholars.isEmpty) return const Center(child: Text("No scholars data"));
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Scholar Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Institution", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Avg Mark", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          ],
        ),
        ...scholars.map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['institution'] ?? 'N/A', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("${s['avg_mark'] ?? 0}%", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _badge(s['status'] ?? 'Active',
              s['status'] == 'Active' ? Colors.green.shade50 : Colors.white,
              s['status'] == 'Active' ? Colors.green.shade700 : Colors.grey.shade700)),
          ],
        )),
      ],
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
