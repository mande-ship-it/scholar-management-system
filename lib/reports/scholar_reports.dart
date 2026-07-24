import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';

class ScholarReportsComponent extends StatefulWidget {
  const ScholarReportsComponent({super.key});

  @override
  State<ScholarReportsComponent> createState() => _ScholarReportsComponentState();
}

class _ScholarReportsComponentState extends State<ScholarReportsComponent> {
  String _selectedPeriod = 'Annual (2026)';
  String _reportType = 'Performance Summary';

  @override
  Widget build(BuildContext context) {
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
              _metricCard("Total Active", "148", kBrandOlive, Icons.people_outline_rounded),
              const SizedBox(width: 16),
              _metricCard("Average Performance", "74.2%", kBrandBrown, Icons.auto_graph_rounded),
              const SizedBox(width: 16),
              _metricCard("Scholarship Disbursed", "MWK 12.4M", kBrandOrange, Icons.payments_outlined),
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
                  title: "Performance Distribution",
                  child: _buildPerformanceChart(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "Regional Summary",
                  child: _buildRegionalBreakdown(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. Recent Report Log / Detailed Table Preview
          _reportSection(
            title: "Detailed Scholar Performance Preview",
            child: _buildScholarTable(),
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
          _dropdownControl("Report Type", _reportType, ['Performance Summary', 'Financial Support', 'Demographics'], (v) => setState(() => _reportType = v!)),
          const SizedBox(width: 20),
          _dropdownControl("Time Period", _selectedPeriod, ['Term 1 2026', 'Term 2 2026', 'Annual (2026)'], (v) => setState(() => _selectedPeriod = v!)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
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

  Widget _buildPerformanceChart() {
    return Column(
      children: [
        _chartBar("Exceeding Expectations (80%+)", 0.35, Colors.green),
        _chartBar("Meeting Expectations (65-79%)", 0.48, kBrandOlive),
        _chartBar("Approaching Expectations (50-64%)", 0.12, kBrandOrange),
        _chartBar("Needs Support (<50%)", 0.05, Colors.red),
      ],
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

  Widget _buildRegionalBreakdown() {
    final regions = [
      ("Southern Region", 64, kBrandBrown),
      ("Central Region", 52, kBrandOlive),
      ("Northern Region", 32, kBrandOrange),
    ];
    return Column(
      children: regions.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Text(r.$2.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildScholarTable() {
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
        ...kStudents.take(5).map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.schoolName, style: const TextStyle(fontSize: 12))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("78%", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _badge("Active", Colors.green.shade50, Colors.green.shade700)),
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
