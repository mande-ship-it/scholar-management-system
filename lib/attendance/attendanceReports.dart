import 'package:flutter/material.dart';
import 'scholarAttendance.dart';

class AttendanceReportsComponent extends StatefulWidget {
  const AttendanceReportsComponent({super.key});

  @override
  State<AttendanceReportsComponent> createState() => _AttendanceReportsComponentState();
}

class _AttendanceReportsComponentState extends State<AttendanceReportsComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Gradient Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kBrandBrown, kBrandOlive]),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Program-wide attendance metrics and trend analysis.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      _ReportStatCard(
                        label: "Overall Rate",
                        value: "88.4%",
                        icon: Icons.speed_rounded,
                        color: kBrandOlive,
                      ),
                      const SizedBox(width: 16),
                      _ReportStatCard(
                        label: "CHATs Sessions",
                        value: "42",
                        icon: Icons.forum_rounded,
                        color: kBrandOrange,
                      ),
                      const SizedBox(width: 16),
                      _ReportStatCard(
                        label: "Study Circles",
                        value: "15",
                        icon: Icons.groups_rounded,
                        color: kBrandBrown,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text("Attendance Trends by Session Type", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Mock Chart
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kBrandBrown.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          const Text("Data Visualization (Monthly Trends)", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Low Attendance Alerts", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14)),
                  const SizedBox(height: 12),
                  
                  // Alerts List
                  _AlertItem(title: "Providence High School", subtitle: "Average attendance dropped to 65% this week.", color: Colors.red),
                  _AlertItem(title: "Sarah Kambewa (s22)", subtitle: "Missed 3 consecutive CHATs sessions.", color: Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.title, required this.subtitle, required this.color});
  final String title, subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
