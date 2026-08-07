import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class FieldOperationsDashboard extends StatefulWidget {
  final Function(String)? onNavigate;
  const FieldOperationsDashboard({super.key, this.onNavigate});

  @override
  State<FieldOperationsDashboard> createState() => _FieldOperationsDashboardState();
}

class _FieldOperationsDashboardState extends State<FieldOperationsDashboard> {
  bool _isLoading = true;
  int _activeScholars = 0;
  int _pendingScholars = 0;
  int _totalScholars = 0;
  int _schoolCount = 0;
  double _retentionRate = 0;
  String _assignedDistrict = "Loading...";
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic>? _engagementData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    debugPrint("DASHBOARD: Starting data load...");

    try {
      // 1. Fetch Profile FIRST (Crucial for district context)
      try {
        final profileRes = await ApiService.getAccountProfile();
        if (profileRes.statusCode == 200 && mounted) {
          final userData = profileRes.data['data'];
          if (userData != null) {
            setState(() {
              _assignedDistrict = userData['assignedDistrict'] ?? "All Regions";
            });
            debugPrint("DASHBOARD: Profile loaded. District: $_assignedDistrict");
          }
        }
      } catch (e) {
        debugPrint("DASHBOARD: Profile fetch error: $e");
      }

      // 2. Fetch Stats and Activities in parallel with a timeout
      final responses = await Future.wait([
        ApiService.getDashboardStats().catchError((e) {
          debugPrint("DASHBOARD: Stats fetch error: $e");
          return Response(requestOptions: RequestOptions(path: ''), statusCode: 500);
        }),
        ApiService.getRecentActivities().catchError((e) {
          debugPrint("DASHBOARD: Activities fetch error: $e");
          return Response(requestOptions: RequestOptions(path: ''), statusCode: 500);
        }),
      ]).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("DASHBOARD: Data fetch timed out (10s)");
        return [];
      });

      if (responses.isNotEmpty && mounted) {
        final statsRes = responses[0];
        if (statsRes.statusCode == 200) {
          final data = statsRes.data['data'];
          if (data != null && mounted) {
            setState(() {
              if (data['summary'] is List && (data['summary'] as List).isNotEmpty) {
                final summary = data['summary'] as List;
                
                // Index 0 is now 'Total Scholars' per backend update
                _totalScholars = int.tryParse(summary[0]['value']?.toString() ?? '0') ?? 0;
                
                if (summary.length > 1) {
                  // Index 1 is 'Active Scholars'
                  _activeScholars = int.tryParse(summary[1]['value']?.toString() ?? '0') ?? 0;
                }

                if (summary.length > 5) {
                  final retStr = summary[5]['value']?.toString().replaceAll('%', '') ?? '0';
                  _retentionRate = double.tryParse(retStr) ?? 0;
                }
              }
              if (data['system'] is Map) {
                final system = data['system'] as Map;
                _schoolCount = int.tryParse(system['totalSchools']?.toString() ?? '0') ?? 0;
              }
              _pendingScholars = data['pendingScholarsCount'] ?? 0;
              _engagementData = data['engagementSeries'];
            });
            debugPrint("DASHBOARD: Stats processed. Total: $_totalScholars, Active: $_activeScholars");
          }
        }

        if (responses.length > 1) {
          final activitiesRes = responses[1];
          if (activitiesRes.statusCode == 200) {
            final List? data = activitiesRes.data['data'];
            if (data != null) {
              setState(() {
                _recentActivity = data.map((a) {
                  final String actor = a['actorName'] ?? 'SYSTEM';
                  return {
                    'title': actor.toUpperCase(),
                    'desc': a['message'] ?? '',
                    'time': _formatTime(a['createdAt'] ?? a['created_at']),
                  };
                }).toList();
              });
              debugPrint("DASHBOARD: Activities processed.");
            }
          }
        }
      }

    } catch (e) {
      debugPrint("DASHBOARD: Global fetch error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("DASHBOARD: Load complete. Final loading state: false");
      }
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "Just now";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return DateFormat('MMM dd').format(date);
    } catch (_) {
      return "Recently";
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("DASHBOARD BUILD: isLoading=$_isLoading");
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              _buildExecutiveHeader(isMobile),
              const SizedBox(height: 32),
            ],
            _buildKPISection(isMobile),
            const SizedBox(height: 32),
            if (isMobile)
              Column(
                children: [
                  _buildPerformanceChart(isMobile),
                  const SizedBox(height: 24),
                  _buildOperationalDistributionCard(isMobile),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildPerformanceChart(isMobile)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildOperationalDistributionCard(isMobile)),
                ],
              ),
            const SizedBox(height: 32),
            if (isMobile)
              Column(
                children: [
                  _buildRecentActivitySection(isMobile),
                  const SizedBox(height: 24),
                  _buildQuickActionsCard(isMobile),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildRecentActivitySection(isMobile)),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _buildQuickActionsCard(isMobile)),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalDistributionCard(bool isMobile) {
    final int total = _activeScholars + _pendingScholars;
    final double activePerc = total > 0 ? (_activeScholars / total * 100) : 100;
    final double pendingPerc = total > 0 ? (_pendingScholars / total * 100) : 0;

    return Container(
      height: isMobile ? null : 400,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SCHOLAR STATUS",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kBrandBrown)),
          const SizedBox(height: 4),
          const Text("Secondary scholars by current status",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: isMobile ? 32 : 48),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
                        if (v == 0) return const Text("ACT", style: style);
                        if (v == 1) return const Text("PEN", style: style);
                        return const Text("");
                      }
                    )
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: activePerc, color: kBrandOlive, width: isMobile ? 32 : 40, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: pendingPerc, color: kBrandOrange, width: isMobile ? 32 : 40, borderRadius: BorderRadius.circular(6))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _indicatorRow("Active Scholars", "${activePerc.toStringAsFixed(1)}%", kBrandOlive),
          const SizedBox(height: 12),
          _indicatorRow("Pending Approval", "${pendingPerc.toStringAsFixed(1)}%", kBrandOrange),
        ],
      ),
    );
  }

  Widget _indicatorRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandBrown)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF4C3C32).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Color(0xFF4C3C32), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "OPERATIONAL COMMAND",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9AB334),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$_assignedDistrict Overview",
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF4C3C32), 
                    letterSpacing: -0.5
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text("SYNC DATA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3C32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKPISection(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _kpiCard("Scholars", _totalScholars.toString(), Icons.groups_rounded, kBrandOlive, isMobile),
              const SizedBox(width: 12),
              _kpiCard("Schools", "$_schoolCount", Icons.location_city_rounded, kBrandBrown, isMobile),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiCard("Retention", "${_retentionRate.toStringAsFixed(1)}%", Icons.how_to_reg_rounded, kBrandOrange, isMobile),
              const SizedBox(width: 12),
              _kpiCard("District", _assignedDistrict, Icons.my_location_rounded, Colors.blue, isMobile),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        _kpiCard("Total Scholars", _totalScholars.toString(), Icons.groups_rounded, kBrandOlive, isMobile),
        const SizedBox(width: 20),
        _kpiCard("Program Reach", "$_schoolCount Schools", Icons.location_city_rounded, kBrandBrown, isMobile),
        const SizedBox(width: 20),
        _kpiCard("Retention Rate", "${_retentionRate.toStringAsFixed(1)}%", Icons.how_to_reg_rounded, kBrandOrange, isMobile),
        const SizedBox(width: 20),
        _kpiCard("Operational Focus", _assignedDistrict, Icons.my_location_rounded, Colors.blue, isMobile),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, bool isMobile) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value, 
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w900, 
                        color: Color(0xFF4C3C32), 
                        letterSpacing: -1
                      )
                    ),
                  ),
                  Text(
                    label.toUpperCase(), 
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.grey.shade400, 
                      letterSpacing: 1.0
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(bool isMobile) {
    final Map<String, dynamic> series = _engagementData ?? {};
    final levels = ["Frequent", "Moderate", "Rare"];
    final levelColors = {"Frequent": kBrandOlive, "Moderate": kBrandOrange, "Rare": Colors.red};

    return Container(
      height: isMobile ? null : 400,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PROGRAM ENGAGEMENT", 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kBrandBrown)),
                    const SizedBox(height: 4),
                    Text("Attendance density in $_assignedDistrict", 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("LIVE METRICS", style: TextStyle(color: kBrandOlive, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: kBrandBrown,
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem("${s.y.toInt()}%", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList(),
                  )
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))))),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: levels.where((l) => series[l] != null && (series[l] as List).isNotEmpty).map((l) {
                  final points = series[l] as List;
                  return LineChartBarData(
                    spots: points.map((p) => FlSpot(double.parse(p['year'].toString()), double.parse(p['score'].toString()))).toList(),
                    isCurved: true,
                    color: levelColors[l],
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: levelColors[l]!.withOpacity(0.05)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              _chartLegend("Frequent", kBrandOlive),
              _chartLegend("Moderate", kBrandOrange),
              _chartLegend("Rare", Colors.red),
            ],
          )
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandBrown)),
      ],
    );
  }

  Widget _buildQuickActionsCard(bool isMobile) {
    return Container(
      height: isMobile ? null : 400,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: kBrandBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("QUICK OPERATIONS",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 32),
          _actionButton("Take Attendance", Icons.how_to_reg_rounded, () => widget.onNavigate?.call("Scholar Attendance")),
          const SizedBox(height: 16),
          _actionButton("Enter Results", Icons.edit_note_rounded, () => widget.onNavigate?.call("Enter Results")),
          const SizedBox(height: 16),
          _actionButton("Performance", Icons.analytics_rounded, () => widget.onNavigate?.call("Performance Analysis")),
          const SizedBox(height: 16),
          _actionButton("Registry", Icons.people_outline_rounded, () => widget.onNavigate?.call("View Scholars")),
          if (isMobile) const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 16),
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("OPERATIONAL LOG",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivity.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = _recentActivity[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.flash_on_rounded, color: kBrandOlive, size: 14),
                ),
                title: Text(activity['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(activity['desc'], style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                trailing: Text(activity['time'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
              );
            },
          ),
        ),
      ],
    );
  }

}
