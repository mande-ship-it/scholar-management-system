import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'academics_utils.dart';
import '../services/api_service.dart';

class AcademicStatsComponent extends StatefulWidget {
  const AcademicStatsComponent({super.key});

  @override
  State<AcademicStatsComponent> createState() => _AcademicStatsComponentState();
}

class _AcademicStatsComponentState extends State<AcademicStatsComponent> {
  String _selectedYear = '2026';
  bool _isLoading = false;

  List<String> get _yearOptions => kResults.map((r) => r.year).toSet().toList()..sort((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getResultsByScholar('');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          kResults.clear();
          for (var item in data) {
            kResults.add(ResultRecord(
              studentId: item['scholar_id'].toString(),
              code: item['subject_code'] ?? 'N/A',
              subject: item['subject_name'] ?? 'N/A',
              marks: double.parse(item['marks'].toString()),
              gpa: item['gpa'] != null ? double.parse(item['gpa'].toString()) : null,
              points: item['points'] != null ? double.parse(item['points'].toString()) : null,
              year: item['academic_year'].toString(),
              term: item['term'],
              semester: item['semester'],
            ));
          }
          if (_yearOptions.isNotEmpty && !_yearOptions.contains(_selectedYear)) {
            _selectedYear = _yearOptions.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: kBrandOlive),
        ),
      );
    }
    final yearResults = kResults.where((r) => r.year == _selectedYear).toList();
    final passCount = yearResults.where((r) => r.marks >= 50).length;
    final passRate = yearResults.isEmpty ? 0.0 : (passCount / yearResults.length) * 100;
    final avgMarks = yearResults.isEmpty ? 0.0 : yearResults.map((r) => r.marks).reduce((a, b) => a + b) / yearResults.length;

    // Performance bands for Pie Chart
    final bands = [
      (label: "Distinction", count: yearResults.where((r) => r.marks >= 80).length, color: kBrandOlive),
      (label: "Credit", count: yearResults.where((r) => r.marks >= 60 && r.marks < 80).length, color: Colors.blue),
      (label: "Pass", count: yearResults.where((r) => r.marks >= 50 && r.marks < 60).length, color: kBrandOrange),
      (label: "Fail", count: yearResults.where((r) => r.marks < 50).length, color: Colors.red),
    ];

    // Yearly trend for Line Graph
    final yearlyAverages = _yearOptions.reversed.map((y) {
      final res = kResults.where((r) => r.year == y).toList();
      final avg = res.isEmpty ? 0.0 : res.map((r) => r.marks).reduce((a, b) => a + b) / res.length;
      return (year: y, value: avg);
    }).toList();

    // Identify at-risk scholars (average < 50)
    final scholarAverages = <String, List<double>>{};
    for (var r in yearResults) {
      scholarAverages.putIfAbsent(r.studentId, () => []).add(r.marks);
    }
    
    final atRiskScholars = scholarAverages.entries
        .map((e) => (id: e.key, avg: e.value.reduce((a, b) => a + b) / e.value.length))
        .where((e) => e.avg < 50)
        .toList();

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
            // ---------------- Header (No Banners) ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.query_stats_rounded, color: kBrandBrown, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Academic Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        SizedBox(height: 2),
                        Text('Interactive performance insights and yearly growth analysis.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.calendar_month, color: kBrandBrown, size: 18),
                      style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold),
                      items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Row
                  Row(
                    children: [
                      _SmartMetricTile(
                        label: "Passing Rate",
                        value: "${passRate.toStringAsFixed(1)}%",
                        icon: Icons.check_circle_outline,
                        color: kBrandOlive,
                        trend: "+2.4%",
                        isUp: true,
                      ),
                      const SizedBox(width: 16),
                      _SmartMetricTile(
                        label: "Avg. Marks",
                        value: "${avgMarks.toStringAsFixed(1)}%",
                        icon: Icons.bar_chart_rounded,
                        color: kBrandBrown,
                        trend: "-1.1%",
                        isUp: false,
                      ),
                      const SizedBox(width: 16),
                      _SmartMetricTile(
                        label: "At-Risk Scholars",
                        value: "${atRiskScholars.length}",
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                        trend: atRiskScholars.isEmpty ? "Healthy" : "Attention",
                        isUp: atRiskScholars.isEmpty,
                      ),
                    ],
                  ),

                  if (atRiskScholars.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _RiskAlertPanel(atRiskScholars: atRiskScholars),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pie Chart Section
                      Expanded(
                        flex: 1,
                        child: _StatCard(
                          title: "Performance Distribution",
                          subtitle: "Proportional view of scholar bands",
                          child: Column(
                            children: [
                              _SmartPieChart(data: bands),
                              const SizedBox(height: 20),
                              ...bands.map((b) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: b.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(b.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text("${b.count}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Line Graph Section
                      Expanded(
                        flex: 2,
                        child: _StatCard(
                          title: "Yearly Performance Growth",
                          subtitle: "Program-wide marks average trend",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SmartLineGraph(data: yearlyAverages),
                              const SizedBox(height: 24),
                              const Text("Program Insights", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
                              const SizedBox(height: 12),
                              _InsightItem(
                                icon: Icons.insights_rounded,
                                color: kBrandOlive,
                                text: "Scholar performance has improved by 15% since 2023.",
                              ),
                              const SizedBox(height: 10),
                              _InsightItem(
                                icon: Icons.priority_high_rounded,
                                color: kBrandOrange,
                                text: "Science subjects require additional support in Term 3.",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Level Comparison Bar
                  _StatCard(
                    title: "Level Breakdown",
                    subtitle: "Comparing Secondary vs University activity for $_selectedYear",
                    child: Row(
                      children: [
                        Expanded(
                          child: _BreakdownItem(
                            label: "Secondary", 
                            value: yearResults.where((r) => kStudents.firstWhere((s) => s.id == r.studentId).schoolType == SchoolType.secondary).length, 
                            color: kBrandBrown,
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 24)),
                        Expanded(
                          child: _BreakdownItem(
                            label: "University", 
                            value: yearResults.where((r) => kStudents.firstWhere((s) => s.id == r.studentId).schoolType == SchoolType.university).length, 
                            color: kBrandOlive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// RISK ALERT PANEL
// ---------------------------------------------------------------------
class _RiskAlertPanel extends StatelessWidget {
  const _RiskAlertPanel({required this.atRiskScholars});
  final List<({String id, double avg})> atRiskScholars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 10),
              Text(
                "Performance Risk Alerts",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "The following scholars have a combined average below 50% for the selected period and may require immediate academic intervention.",
            style: TextStyle(fontSize: 12, color: Colors.red.shade800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: atRiskScholars.map((risk) {
              final student = kStudents.firstWhere((s) => s.id == risk.id);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red.shade100,
                      child: Text(student.name[0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text("Avg: ${risk.avg.toStringAsFixed(1)}%", style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// PIE CHART COMPONENT
// ---------------------------------------------------------------------
class _SmartPieChart extends StatelessWidget {
  const _SmartPieChart({required this.data});
  final List<({String label, int count, Color color})> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: 140,
      child: CustomPaint(
        painter: _PieChartPainter(data),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter(this.data);
  final List<({String label, int count, Color color})> data;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<int>(0, (sum, e) => sum + e.count);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (final segment in data) {
      final sweepAngle = (segment.count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Draw hole for donut look
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------
// LINE GRAPH COMPONENT
// ---------------------------------------------------------------------
class _SmartLineGraph extends StatelessWidget {
  const _SmartLineGraph({required this.data});
  final List<({String year, double value})> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: kBrandBrown.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _LineGraphPainter(data),
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  _LineGraphPainter(this.data);
  final List<({String year, double value})> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = kBrandOlive
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [kBrandOlive.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double xStep = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      // Value is percentage (0-100), map to height
      final double y = size.height - (data[i].value / 100 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points and labels
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double y = size.height - (data[i].value / 100 * size.height);
      
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = kBrandBrown);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);

      // Text labels
      final textPainter = TextPainter(
        text: TextSpan(text: data[i].year, style: const TextStyle(color: kBrandBrown, fontSize: 10, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------
// UI HELPER WIDGETS
// ---------------------------------------------------------------------

class _SmartMetricTile extends StatelessWidget {
  const _SmartMetricTile({required this.label, required this.value, required this.icon, required this.color, required this.trend, required this.isUp});
  final String label, value, trend;
  final IconData icon;
  final Color color;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 12, color: isUp ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUp ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Text("$value", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
      ],
    );
  }
}

class _InsightItem extends StatelessWidget {
  const _InsightItem({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
      ],
    );
  }
}
