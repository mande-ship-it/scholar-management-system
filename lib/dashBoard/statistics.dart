import 'package:flutter/material.dart';
import 'dart:math' as math;

class StatisticsComponent extends StatelessWidget {
  const StatisticsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);
    const Color brandGold = Color(0xFFD4AF37);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: brandOlive, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Live Data Feed • Last updated: Just now",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _actionButton(Icons.calendar_today_rounded, "Academic Year 2026"),
                const SizedBox(width: 12),
                _actionButton(Icons.filter_list_rounded, "Global Filters"),
              ],
            ),
          ],
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
            int crossAxisCount = width > 1200 ? 4 : (width > 800 ? 2 : 1);
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 2.2,
              children: [
                _buildKpiCard("Total Scholars", "1,248", "+14.2%", Icons.people_alt_rounded, brandOlive, true),
                _buildKpiCard("Retention Rate", "96.4%", "+2.1%", Icons.verified_user_rounded, brandOrange, true),
                _buildKpiCard("Partner Schools", "42", "Steady", Icons.account_balance_rounded, brandBrown, false),
                _buildKpiCard("Avg. Academic Score", "74.8%", "+3.4%", Icons.auto_stories_rounded, brandGold, true),
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

  Widget _actionButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4C3C32)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4C3C32))),
        ],
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
                  children: [
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32))),
                    const SizedBox(width: 8),
                    if (trend != "Steady")
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
      title: "Academic Growth Trend",
      subtitle: "Term-over-term performance aggregated across schools",
      child: Container(
        height: 300,
        padding: const EdgeInsets.only(top: 20),
        child: CustomPaint(
          painter: _LineChartPainter(primary),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildProgramPieChart(Color olive, Color orange, Color gold, Color brown) {
    final List<_PieData> data = [
      _PieData("Stem Focus", 45, olive),
      _PieData("Liberal Arts", 25, orange),
      _PieData("Medical/Health", 20, gold),
      _PieData("Vocational", 10, brown),
    ];

    return _GlassContainer(
      title: "Field Specialization",
      subtitle: "Tertiary level concentration",
      child: Column(
        children: [
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _DonutChartPainter(data),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("88.4%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: brown)),
                    const Text("Attendance", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                Expanded(child: Text(d.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                Text("${d.value}%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRegionalHeatmap(Color brown, Color olive) {
    return _GlassContainer(
      title: "Program Density by District",
      subtitle: "Relative participation intensity (Normalized)",
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildDensityRow("Central Region (Zomba, Lilongwe)", 0.85, olive),
          _buildDensityRow("Northern Region (Mzuzu, Karonga)", 0.62, Colors.blueAccent),
          _buildDensityRow("Southern Region (Blantyre, Thyolo)", 0.94, brown),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBudgetPulse(Color orange, Color gold, Color brown) {
    return _GlassContainer(
      title: "Financial Resource pulse",
      subtitle: "Budget utilization for current term",
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _circleProgress(0.82, "Tuition", orange),
              _circleProgress(0.55, "Materials", gold),
              _circleProgress(0.88, "Allowances", brown),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDensityRow(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text("${(val * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: val,
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
              CircularProgressIndicator(value: val, strokeWidth: 8, backgroundColor: Colors.grey.shade100, color: color, strokeCap: StrokeCap.round),
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

class _LineChartPainter extends CustomPainter {
  final Color color;
  _LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // More "meaningful" data points representing academic cycle peaks and dips
    final points = [0.65, 0.72, 0.68, 0.81, 0.78, 0.85, 0.82, 0.92, 0.88, 0.95];
    final stepX = size.width / (points.length - 1);

    path.moveTo(0, size.height * (1 - points[0]));
    for (int i = 1; i < points.length; i++) {
      path.lineTo(i * stepX, size.height * (1 - points[i]));
    }

    // Gradient fill
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
    
    // Draw points
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokeDot = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(i * stepX, size.height * (1 - points[i])), 5, dotPaint);
      canvas.drawCircle(Offset(i * stepX, size.height * (1 - points[i])), 5, strokeDot);
      
      // Add labels for "Terms" at key points
      if (i % 3 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(text: "Term ${(i/3 + 1).toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(i * stepX - 15, size.height * (1 - points[i]) - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    double startAngle = -math.pi / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 28..strokeCap = StrokeCap.round;

    for (var item in data) {
      final sweepAngle = (item.value / 100) * 2 * math.pi;
      paint.color = item.color;
      // Drawing small gaps between segments
      canvas.drawArc(rect.deflate(2), startAngle + 0.05, sweepAngle - 0.1, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
