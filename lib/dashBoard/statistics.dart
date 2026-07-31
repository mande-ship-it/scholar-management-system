import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'districts_map.dart';

class StatisticsComponent extends StatefulWidget {
  final String level; // 'University' or 'Secondary'
  const StatisticsComponent({super.key, required this.level});

  @override
  State<StatisticsComponent> createState() => _StatisticsComponentState();
}

class _StatisticsComponentState extends State<StatisticsComponent> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _selectedRiskSchool;

  // Colors from Professional Prototype
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1C2B20);
  static const Color textSecondary = Color(0xFF6B7A6E);
  static const Color dividerColor = Color(0xFFE1E8E3);
  
  static const List<Color> chartColors = [
    Color(0xFF2E7D32), // Green
    Color(0xFF1976D2), // Blue
    Color(0xFFF9A825), // Amber
    Color(0xFF8E24AA), // Purple
    Color(0xFFD32F2F), // Red
  ];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(StatisticsComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDashboardStats(level: widget.level);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _data = response.data['data'];
          _selectedRiskSchool = (_data!['schools'] as List).isNotEmpty ? _data!['schools'][0]['name'] : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: primary)));
    }

    return Column(
      children: [
        _buildStatsGrid(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildCohortCard()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildRegionCard()),
          ],
        ),
        const SizedBox(height: 24),
        _buildPerformanceTrendCard(),
        const SizedBox(height: 24),
        _buildRiskIndicatorCard(),
        const SizedBox(height: 24),
        _buildEngagementImpactCard(),
      ],
    );
  }

  Widget _buildRegionCard() {
    final List regions = _data!['regions'] ?? [];
    
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/dashboard/map'),
      borderRadius: BorderRadius.circular(18),
      child: _DashboardCard(
        title: "Regional Impact",
        subtitle: "Scholars distribution across Malawi regions",
        child: Column(
          children: [
            if (regions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text("No regional data found.", style: TextStyle(color: Colors.grey, fontSize: 12))),
              )
            else
              ...regions.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.public_rounded, size: 16, color: kBrandBrown),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['region'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          Text("Region Impact Level", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text("${r['count']}", style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 18)),
                  ],
                ),
              )).toList(),
            const Divider(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("EXPLORE INTERACTIVE MAP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 0.8)),
                SizedBox(width: 10),
                Icon(Icons.map_outlined, size: 16, color: kBrandBrown),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final summary = _data!['summary'] as List;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Force all items into one line for the "horizontal dashboard strip" look
        int crossAxisCount = summary.length;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, 
          ),
          itemCount: summary.length,
          itemBuilder: (context, i) {
            final item = summary[i];
            final Color color = chartColors[i % chartColors.length];
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getIcon(item['icon']), color: Colors.white.withOpacity(0.9), size: 14),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("${item['value']}", 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  ),
                  Text(item['label'].toString().toUpperCase(), 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildCohortCard() {
    final cohorts = _data!['cohorts'] as List;
    final total = cohorts.fold(0, (sum, e) => sum + (e['count'] as int));

    return _DashboardCard(
      title: "Scholar Cohorts",
      subtitle: "Registered by intake year, cohort 1 = current year",
      child: Row(
        children: [
          SizedBox(
            width: 170, height: 170,
            child: PieChart(PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: cohorts.asMap().entries.map((e) => PieChartSectionData(
                color: chartColors[e.key % chartColors.length],
                value: (e.value['count'] as int).toDouble(),
                title: "", radius: 30,
              )).toList(),
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cohorts.asMap().entries.map((e) {
                final count = e.value['count'] as int;
                final perc = total > 0 ? (count / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: chartColors[e.key % chartColors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cohort ${e.value['cohort']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                            Text("$count scholars ($perc%)", style: const TextStyle(fontSize: 11.5, color: textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicatorCard() {
    final schools = _data!['schools'] as List;
    final school = schools.firstWhere((s) => s['name'] == _selectedRiskSchool, orElse: () => schools.isNotEmpty ? schools[0] : null);

    if (school == null) return const SizedBox();

    final Color rColor = _getRiskColor(school['level']);
    final String rLabel = school['level'].toString().toUpperCase() + " RISK";

    return _DashboardCard(
      title: "Risk Indicators",
      subtitle: "Institutional risk mapping and scholar flags",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: DropdownButton<String>(
              value: _selectedRiskSchool,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
              items: schools.map((s) {
                final name = s['name']?.toString() ?? 'Unassigned';
                return DropdownMenuItem<String>(value: name, child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
              }).toList(),
              onChanged: (val) => setState(() => _selectedRiskSchool = val),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: rColor.withOpacity(0.08), 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: rColor.withOpacity(0.25))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: rColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(rLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                    Text("${school['avg']}% avg", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: rColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(school['reason'], style: const TextStyle(fontSize: 12.5, height: 1.5, color: textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.report_problem_rounded, size: 16, color: rColor),
                    const SizedBox(width: 8),
                    Text("${school['atrisk']} scholars flagged", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrendCard() {
    final trends = _data!['performanceSeries'] as Map? ?? {};
    final List<String> schools = trends.keys.map((k) => k?.toString() ?? 'Unknown').toList();
    
    return _DashboardCard(
      title: "${widget.level} Performance Trend",
      subtitle: "Institutional average results aggregated by academic year",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartLegend(schools.asMap().entries.map((e) => (label: e.value, color: chartColors[e.key % chartColors.length])).toList()),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(LineChartData(
              lineTouchData: const LineTouchData(enabled: true),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: dividerColor, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, _) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textSecondary)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textSecondary))))),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: schools.asMap().entries.map((e) {
                final points = trends[e.value] as List;
                return LineChartBarData(
                  spots: points.map((p) => FlSpot(double.parse(p['year'].toString()), double.parse(p['marks'].toString()))).toList(),
                  isCurved: true, color: chartColors[e.key % chartColors.length], barWidth: 3.5, 
                  dotData: FlDotData(show: true, getDotPainter: (s, p, bd, i) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: chartColors[e.key % chartColors.length])),
                );
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementImpactCard() {
    final engData = _data!['engagementSeries'] as Map? ?? {};
    final levels = ["Frequent", "Moderate", "Rare"];
    final levelColors = {"Frequent": const Color(0xFF2E7D32), "Moderate": const Color(0xFFF9A825), "Rare": const Color(0xFFD32F2F)};

    return _DashboardCard(
      title: "Performance by CHATS Engagement",
      subtitle: "Longitudinal analysis of attendance density vs academic achievement",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartLegend(levels.map((l) => (label: "$l Attendance", color: levelColors[l]!)).toList()),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: dividerColor, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, _) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textSecondary)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textSecondary))))),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: levels.where((l) => engData[l] != null).map((l) {
                final points = engData[l] as List;
                return LineChartBarData(
                  spots: points.map((p) => FlSpot(double.parse(p['year'].toString()), double.parse(p['score'].toString()))).toList(),
                  isCurved: true, color: levelColors[l], barWidth: 4, 
                  dotData: FlDotData(show: true, getDotPainter: (s, p, bd, i) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2.5, strokeColor: levelColors[l]!)),
                );
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(List<({String label, Color color})> items) {
    return Wrap(
      spacing: 20, runSpacing: 10,
      children: items.map((i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 4, decoration: BoxDecoration(color: i.color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(i.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
        ],
      )).toList(),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'groups': return Icons.people_rounded;
      case 'award': return Icons.workspace_premium_rounded;
      case 'bank': return Icons.account_balance_rounded;
      case 'book': return Icons.auto_stories_rounded;
      case 'heart': return Icons.volunteer_activism_rounded;
      case 'trend': return Icons.insights_rounded;
      default: return Icons.bar_chart_rounded;
    }
  }

  Color _getRiskColor(String level) {
    if (level == 'low') return const Color(0xFF2E7D32);
    if (level == 'medium') return const Color(0xFFF9A825);
    return const Color(0xFFD32F2F);
  }
}

class _DashboardCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _DashboardCard({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: const Color(0xFFE1E8E3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C2B20), letterSpacing: -0.3)),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A6E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
