import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

// STATISTICS LOCAL PALETTE
const Color kS_Brown = Color(0xFF4C3C32);
const Color kS_Olive = Color(0xFF9AB334);
const Color kS_Orange = Color(0xFFE05B1C);
const Color kS_Gold = Color(0xFFD4AF37);

class StatisticsComponent extends StatefulWidget {
  const StatisticsComponent({super.key});

  @override
  State<StatisticsComponent> createState() => _StatisticsComponentState();
}

class _StatisticsComponentState extends State<StatisticsComponent> {
  bool _isLoading = true;

  int _totalScholars = 0;
  int _partnerSchools = 0;
  int _totalSponsors = 0;
  int _graduatedCount = 0;
  int _atRiskCount = 0;

  double _avgAcademicScore = 0.0;
  double _retentionRate = 0.0;
  double _attendanceRate = 0.0;

  List<dynamic> _academicTrends = [];
  List<dynamic> _sponsorDistribution = [];

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDashboardStats();
      if (response.statusCode == 200) {
        final stats = response.data['data'] ?? {};
        setState(() {
          _totalScholars = stats['scholars'] ?? 0;
          _partnerSchools = stats['schools'] ?? 0;
          _totalSponsors = stats['sponsors'] ?? 0;
          _graduatedCount = stats['graduated'] ?? 0;
          _atRiskCount = stats['atRisk'] ?? 0;
          _academicTrends = stats['academicTrends'] ?? [];
          _sponsorDistribution = stats['sponsorDistribution'] ?? [];
          final pulse = stats['pulse'] ?? {};
          _retentionRate = double.parse(pulse['retention']?.toString() ?? '0.0');
          _avgAcademicScore = double.parse(pulse['avgScore']?.toString() ?? '0.0');
          _attendanceRate = double.parse(pulse['attendance']?.toString() ?? '0.0');
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: CircularProgressIndicator(color: kS_Olive),
        ),
      );
    }

    final bool isWide = MediaQuery.of(context).size.width > 1150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 5 : (constraints.maxWidth > 800 ? 3 : 2);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildKpiCard("Total Scholars", "$_totalScholars", "Active", Icons.people_alt_rounded, kS_Olive),
                _buildKpiCard("Partner Schools", "$_partnerSchools", "Total", Icons.account_balance_rounded, kS_Brown),
                _buildKpiCard("Active Sponsors", "$_totalSponsors", "Gold/Silver", Icons.volunteer_activism_rounded, kS_Gold),
                _buildKpiCard("Graduated", "$_graduatedCount", "Completed", Icons.school_rounded, Colors.green),
                _buildKpiCard("At-Risk Scholars", "$_atRiskCount", "Action Required", Icons.warning_amber_rounded, kS_Orange),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildAcademicBezierCard()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildRadialPulseCard()),
            ],
          )
        else
          Column(
            children: [
              _buildAcademicBezierCard(),
              const SizedBox(height: 20),
              _buildRadialPulseCard(),
            ],
          ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: color.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kS_Brown)),
                Text(sub, style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicBezierCard() {
    return _DashboardCardFrame(
      title: "Academic Cohort Performance Trends",
      subtitle: "Bezier progression average marks across all active scholars",
      child: Container(
        height: 280,
        padding: const EdgeInsets.only(top: 32, bottom: 8, right: 24, left: 0),
        child: _academicTrends.isEmpty
            ? const Center(child: Text("No academic trend records available", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
            : LineChart(LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _academicTrends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), double.parse(e.value['average_marks'].toString()))).toList(),
                    isCurved: true, color: kS_Olive, barWidth: 4, isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [kS_Olive.withOpacity(0.2), kS_Olive.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ],
              )),
      ),
    );
  }

  Widget _buildRadialPulseCard() {
    return _DashboardCardFrame(
      title: "Core Operations Pulse",
      subtitle: "Aggregated status rates and retention targets",
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(height: 180, child: CustomPaint(painter: ConcentricPulseRingsPainter(retention: _retentionRate / 100, attendance: _attendanceRate / 100, score: _avgAcademicScore / 100))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ringLegendItem("Retention", "${_retentionRate.toStringAsFixed(1)}%", kS_Orange),
              _ringLegendItem("Avg Score", "${_avgAcademicScore.toStringAsFixed(1)}%", kS_Gold),
              _ringLegendItem("Attendance", "${_attendanceRate.toStringAsFixed(1)}%", kS_Olive),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ringLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kS_Brown))]),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildSponsorTiersCard() {
    double totalSponsors = _sponsorDistribution.fold(0.0, (sum, item) => sum + (item['count'] as num).toDouble());
    return _DashboardCardFrame(
      title: "Sponsorship Tier Spread",
      subtitle: "Partner categorization and count breakdown",
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: _sponsorDistribution.isEmpty ? const Center(child: Text("No sponsor data", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))) : Stack(children: [
              PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 35, sections: _sponsorDistribution.map((d) {
                Color c = kS_Gold; String t = d['tier']?.toString().toLowerCase() ?? '';
                if (t.contains('platinum')) c = kS_Brown; else if (t.contains('gold')) c = kS_Gold; else if (t.contains('silver')) c = kS_Olive; else if (t.contains('bronze')) c = kS_Orange; else c = Colors.teal;
                return PieChartSectionData(color: c, value: (d['count'] as num).toDouble(), title: "${d['count']}", radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white));
              }).toList())),
              Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("${totalSponsors.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kS_Brown)), const Text("TOTAL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))])),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalDensityCard() {
    return _DashboardCardFrame(
      title: "Regional Density Index",
      subtitle: "Geographic concentrations of partner schools",
      child: Column(
        children: [
          const SizedBox(height: 16),
          _densityRow("Central Region", (_regionalCounts['Central Region'] ?? 0) / 10.0, kS_Olive, _regionalCounts['Central Region'] ?? 0),
          _densityRow("Northern Region", (_regionalCounts['Northern Region'] ?? 0) / 10.0, Colors.blueAccent, _regionalCounts['Northern Region'] ?? 0),
          _densityRow("Southern Region", (_regionalCounts['Southern Region'] ?? 0) / 10.0, kS_Brown, _regionalCounts['Southern Region'] ?? 0),
        ],
      ),
    );
  }

  Widget _densityRow(String label, double val, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kS_Brown)), Text("$count Schools", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))]),
        const SizedBox(height: 6),
        Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: val.clamp(0, 1), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.6), color]), borderRadius: BorderRadius.circular(4))))),
      ]),
    );
  }
}

class ConcentricPulseRingsPainter extends CustomPainter {
  final double retention, attendance, score;
  ConcentricPulseRingsPainter({required this.retention, required this.attendance, required this.score});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = math.min(size.width, size.height) / 2 - 8;
    _drawRing(canvas, center, maxRadius, retention, kS_Orange, 12);
    _drawRing(canvas, center, maxRadius - 17, score, kS_Gold, 12);
    _drawRing(canvas, center, maxRadius - 34, attendance, kS_Olive, 12);
  }
  void _drawRing(Canvas canvas, Offset center, double radius, double value, Color color, double thickness) {
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, 2 * math.pi, false, Paint()..color = Colors.grey.shade100..strokeWidth = thickness..style = PaintingStyle.stroke);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, value.clamp(0, 1) * 2 * math.pi, false, Paint()..color = color..strokeWidth = thickness..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant ConcentricPulseRingsPainter old) => true;
}

class _DashboardCardFrame extends StatelessWidget {
  final String title, subtitle; final Widget child;
  const _DashboardCardFrame({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kS_Brown, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        child,
      ]),
    );
  }
}
