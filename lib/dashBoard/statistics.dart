import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

class StatisticsComponent extends StatefulWidget {
  const StatisticsComponent({super.key});

  @override
  State<StatisticsComponent> createState() => _StatisticsComponentState();
}

class _StatisticsComponentState extends State<StatisticsComponent> {
  bool _isLoading = true;
  int _totalScholars = 0;
  int _partnerSchools = 0;
  double _avgAcademicScore = 0.0;
  double _retentionRate = 0.0;
  double _attendanceRate = 0.0;

  List<dynamic> _academicTrends = [];
  List<dynamic> _schoolDistribution = [];

  Map<String, int> _regionalCounts = {
    'Northern Region': 0,
    'Central Region': 0,
    'Southern Region': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDashboardStats();
      final schoolsRes = await ApiService.getAllSchools();

      if (response.statusCode == 200 && schoolsRes.statusCode == 200) {
        final stats = response.data['data'];
        final List<dynamic> schools = schoolsRes.data['data'] ?? [];

        Map<String, int> regions = {
          'Northern Region': 0,
          'Central Region': 0,
          'Southern Region': 0,
        };

        for (var school in schools) {
          final reg = school['region']?.toString() ?? '';
          if (regions.containsKey(reg)) {
            regions[reg] = regions[reg]! + 1;
          }
        }

        if (mounted) {
          setState(() {
            _totalScholars = stats['scholars'] ?? 0;
            _partnerSchools = stats['schools'] ?? 0;
            _academicTrends = stats['academicTrends'] ?? [];
            _schoolDistribution = stats['schoolDistribution'] ?? [];
            _regionalCounts = regions;

            final pulse = stats['pulse'] ?? {};
            _retentionRate = double.parse(pulse['retention']?.toString() ?? '0.0');
            _avgAcademicScore = double.parse(pulse['avgScore']?.toString() ?? '0.0');
            _attendanceRate = double.parse(pulse['attendance']?.toString() ?? '0.0');
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);
    const Color brandGold = Color(0xFFD4AF37);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(color: brandOlive),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section ---
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 950;
            
            final titleWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "System Intelligence Overview",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: brandBrown,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: brandOlive, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Live Data Feed • Last updated: Just now",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            );

            final actionsWidget = Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton(Icons.calendar_today_rounded, "Academic Year 2026", () {}),
                _actionButton(Icons.refresh_rounded, "Refresh Data", _fetchStats),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 20),
                  actionsWidget,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleWidget),
                const SizedBox(width: 24),
                actionsWidget,
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // --- 1. Main Analytics Grid (GRAPHS ON TOP) ---
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1100) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildScholarGrowthChart(brandOlive, brandBrown)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildProgramPieChart(brandOlive, brandOrange, brandGold, brandBrown)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildScholarGrowthChart(brandOlive, brandBrown),
                  const SizedBox(height: 24),
                  _buildProgramPieChart(brandOlive, brandOrange, brandGold, brandBrown),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 32),

        // --- 2. KPI Dashboard Cards (BELOW GRAPHS) ---
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            int crossAxisCount = 1;
            if (width > 1200) {
              crossAxisCount = 4;
            } else if (width > 800) {
              crossAxisCount = 2;
            }
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: (width / crossAxisCount) > 400 ? 2.8 : 2.2,
              children: [
                _buildKpiCard("Total Scholars", "$_totalScholars", "Live", Icons.people_alt_rounded, brandOlive, true),
                _buildKpiCard("Retention Rate", "${_retentionRate.toStringAsFixed(1)}%", "High", Icons.verified_user_rounded, brandOrange, true),
                _buildKpiCard("Partner Schools", "$_partnerSchools", "Total", Icons.account_balance_rounded, brandBrown, false),
                _buildKpiCard("Avg. Academic Score", "${_avgAcademicScore.toStringAsFixed(1)}%", "Mean", Icons.auto_stories_rounded, brandGold, true),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),

        // --- 3. Bottom Insights Row ---
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1100) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRegionalHeatmap(brandBrown, brandOlive)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildBudgetPulse(brandOrange, brandGold, brandBrown)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildRegionalHeatmap(brandBrown, brandOlive),
                  const SizedBox(height: 24),
                  _buildBudgetPulse(brandOrange, brandGold, brandBrown),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4C3C32)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4C3C32))),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String trend, IconData icon, Color color, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarGrowthChart(Color primary, Color text) {
    return _GlassContainer(
      title: "Academic Trends (Mean Performance)",
      subtitle: "Historical average marks across all scholars",
      child: Container(
        height: 300,
        padding: const EdgeInsets.only(top: 20),
        child: _academicTrends.isEmpty
          ? const Center(child: Text("No academic trend data available", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
          : CustomPaint(
              painter: _TrendChartPainter(primary, _academicTrends),
              child: Container(),
            ),
      ),
    );
  }

  Widget _buildProgramPieChart(Color olive, Color orange, Color gold, Color brown) {
    final List<Color> palette = [olive, orange, gold, brown, Colors.teal, Colors.indigo, Colors.pink];

    final List<_PieData> data = [];
    int i = 0;
    int otherCount = 0;

    // Show top 4 schools, group others
    for (var school in _schoolDistribution) {
      if (i < 4) {
        data.add(_PieData(school['school_name'] ?? 'Unknown', school['student_count'].toDouble(), palette[i % palette.length]));
      } else {
        otherCount += (school['student_count'] as int);
      }
      i++;
    }

    if (otherCount > 0) {
      data.add(_PieData("Other Schools", otherCount.toDouble(), Colors.grey.shade400));
    }

    double totalStudents = _schoolDistribution.fold(0, (sum, item) => sum + item['student_count']);

    return _GlassContainer(
      title: "Scholar Distribution",
      subtitle: "Enrolment per partner institution",
      child: Column(
        children: [
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: data.isEmpty
              ? const Center(child: Text("No distribution data", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
              : CustomPaint(
                  painter: _DonutChartPainter(data),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${totalStudents.toInt()}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32))),
                        const Text("Scholars", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 30),
          ...data.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(d.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                Text("${d.value.toInt()}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRegionalHeatmap(Color brown, Color olive) {
    int maxCount = _regionalCounts.values.fold(1, (prev, element) => element > prev ? element : prev);

    return _GlassContainer(
      title: "Program Density by Region",
      subtitle: "Geographic concentration of partner schools",
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildDensityRow("Central Region", (_regionalCounts['Central Region'] ?? 0) / maxCount, olive, _regionalCounts['Central Region'] ?? 0),
          _buildDensityRow("Northern Region", (_regionalCounts['Northern Region'] ?? 0) / maxCount, Colors.blueAccent, _regionalCounts['Northern Region'] ?? 0),
          _buildDensityRow("Southern Region", (_regionalCounts['Southern Region'] ?? 0) / maxCount, brown, _regionalCounts['Southern Region'] ?? 0),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBudgetPulse(Color orange, Color gold, Color brown) {
    return _GlassContainer(
      title: "Academic Pulse",
      subtitle: "General student standing overview",
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _circleProgress(_retentionRate / 100, "Retention", orange),
              _circleProgress(_avgAcademicScore / 100, "Avg Score", gold),
              _circleProgress(_attendanceRate / 100, "Attendance", brown),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDensityRow(String label, double val, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text("$count Schools", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: val.isNaN || val.isInfinite ? 0 : val,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleProgress(double val, String label, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              CircularProgressIndicator(value: val.isNaN || val.isInfinite ? 0 : val, strokeWidth: 8, backgroundColor: Colors.grey.shade100, color: color, strokeCap: StrokeCap.round),
              Center(child: Text("${(val * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _GlassContainer({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          child,
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final Color color;
  final List<dynamic> trends;
  _TrendChartPainter(this.color, this.trends);

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = trends.map((t) => double.parse(t['average_marks'].toString()) / 100).toList();
    final stepX = size.width / (math.max(1, points.length - 1));

    path.moveTo(0, size.height * (1 - points[0]));
    for (int i = 1; i < points.length; i++) {
      path.lineTo(i * stepX, size.height * (1 - points[i]));
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokeDot = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - points[i]);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, strokeDot);
      
      final trend = trends[i];
      final label = trend['term'] ?? trend['semester'] ?? trend['year'].toString();

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, y - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData(this.label, this.value, this.color);
}

class _DonutChartPainter extends CustomPainter {
  final List<_PieData> data;
  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    double total = data.fold(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 28..strokeCap = StrokeCap.round;

    for (var item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;
      paint.color = item.color;
      canvas.drawArc(rect.deflate(2), startAngle + 0.05, sweepAngle - 0.1, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
