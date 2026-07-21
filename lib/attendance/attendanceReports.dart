import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

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
          // 1. Clean Header (No Banners)
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // 2. Control Row
          _buildControls(),

          // ---------------- Stats (Banners Removed) ----------------

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
                  title: "Attendance Alerts",
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attendance Analytics',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kBrandBrown)),
                SizedBox(height: 4),
                Text('Program-wide attendance metrics and trend analysis.',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
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
            icon: const Icon(Icons.tune_rounded),
            label: const Text("Detailed Filters"),
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

  Widget _buildAlertsList() {
    return Column(
      children: [
        _alertItem("Low Enrollment Participation", "Providence High dropped to 65%", Colors.red),
        _alertItem("Consistency Issue", "Sarah Kambewa missed 3 sessions", Colors.orange),
        _alertItem("High Performance", "Kamuzu Academy reached 100% rate", kBrandOlive),
      ],
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
        ...[
          ("Kamuzu Academy", 42, 38, 92.4),
          ("UNIMA", 128, 115, 89.8),
          ("Chichiri Secondary", 24, 18, 75.0),
        ].map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.$2.toString(), style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.$3.toString(), style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("${s.$4}%", style: TextStyle(fontWeight: FontWeight.bold, color: s.$4 >= 85 ? kBrandOlive : kBrandOrange))),
          ],
        )).toList(),
      ],
    );
  }
}
