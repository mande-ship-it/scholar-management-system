import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';

class AttendanceReportsComponent extends StatefulWidget {
  const AttendanceReportsComponent({super.key});

  @override
  State<AttendanceReportsComponent> createState() => _AttendanceReportsComponentState();
}

class _AttendanceReportsComponentState extends State<AttendanceReportsComponent> {
  String _selectedMonth = 'July 2026';

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
              _metricCard("Average Attendance", "92.4%", kBrandOlive, Icons.rule_rounded),
              const SizedBox(width: 16),
              _metricCard("Perfect Attendance", "84 Scholars", kBrandBrown, Icons.verified_rounded),
              const SizedBox(width: 16),
              _metricCard("Critical Lows", "5", Colors.red, Icons.warning_amber_rounded),
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
                  child: _buildTrendsChart(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "Absence Reasons",
                  child: _buildReasonBreakdown(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. Attendance Detail Preview
          _reportSection(
            title: "Scholar Attendance Summary",
            child: _buildAttendanceTable(),
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
          _dropdownControl("Select Month", _selectedMonth, ['May 2026', 'June 2026', 'July 2026'], (v) => setState(() => _selectedMonth = v!)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
            label: const Text("Advanced Filters"),
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

  Widget _buildTrendsChart() {
    return Column(
      children: [
        _chartBar("Week 1", 0.95, kBrandOlive),
        _chartBar("Week 2", 0.92, kBrandOlive),
        _chartBar("Week 3", 0.88, kBrandBrown),
        _chartBar("Week 4", 0.94, kBrandOlive),
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

  Widget _buildReasonBreakdown() {
    final reasons = [
      ("Illness", 45, Colors.blue),
      ("Family Obligations", 30, kBrandOrange),
      ("Financial/Transport", 15, kBrandBrown),
      ("Other", 10, Colors.grey),
    ];
    return Column(
      children: reasons.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Text("${r.$2}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAttendanceTable() {
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
        ...kStudents.take(5).map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("19", style: TextStyle(fontSize: 13))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("1", style: TextStyle(fontSize: 13, color: Colors.red))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("95%", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive))),
          ],
        )),
      ],
    );
  }
}
