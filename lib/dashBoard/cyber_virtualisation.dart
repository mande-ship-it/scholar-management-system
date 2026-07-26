import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Shared Dashboard Brand Colors
const Color kVBrown = Color(0xFF4C3C32);
const Color kVOlive = Color(0xFF9AB334);
const Color kVOrange = Color(0xFFE05B1C);
const Color kVGold = Color(0xFFD4AF37);
const Color kVCyan = Color(0xFF00ACC1);
const Color kVPurple = Color(0xFF8E24AA);

class CyberVirtualisationComponent extends StatefulWidget {
  const CyberVirtualisationComponent({super.key});

  @override
  State<CyberVirtualisationComponent> createState() => _CyberVirtualisationComponentState();
}

class _CyberVirtualisationComponentState extends State<CyberVirtualisationComponent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;
  List<dynamic> _cohortDensity = [];
  double _overallSuccess = 0.0;
  List<dynamic> _milestones = [];
  List<dynamic> _performanceComparison = [];
  List<dynamic> _districtDistribution = [];

  final Map<String, LatLng> _districtCoords = {
    'Lilongwe': const LatLng(-13.9626, 33.7741),
    'Blantyre': const LatLng(-15.7861, 35.0058),
    'Mzimba': const LatLng(-11.9000, 33.6000),
    'Zomba': const LatLng(-15.3875, 35.3181),
    'Mangochi': const LatLng(-14.4781, 35.2641),
    'Dowa': const LatLng(-13.6522, 33.9375),
    'Dedza': const LatLng(-14.3731, 34.3323),
    'Nkhotakota': const LatLng(-12.9272, 34.2828),
    'Salima': const LatLng(-13.7808, 34.4587),
    'Ntcheu': const LatLng(-14.8203, 34.6358),
    'Machinga': const LatLng(-15.1764, 35.3000),
    'Chikwawa': const LatLng(-16.0333, 34.8000),
    'Nsanje': const LatLng(-16.9200, 35.2600),
    'Mulanje': const LatLng(-16.0264, 35.5072),
    'Thyolo': const LatLng(-16.0667, 35.1333),
    'Mwanza': const LatLng(-15.6111, 34.5222),
    'Neno': const LatLng(-15.4000, 34.6500),
    'Balaka': const LatLng(-14.9856, 34.9547),
    'Chiradzulu': const LatLng(-15.6722, 35.1417),
    'Phalombe': const LatLng(-15.8064, 35.6514),
    'Nkhata Bay': const LatLng(-11.6067, 34.2917),
    'Rumphi': const LatLng(-11.0186, 33.8575),
    'Karonga': const LatLng(-9.9333, 33.9333),
    'Chitipa': const LatLng(-9.7000, 33.2667),
    'Likoma': const LatLng(-12.0667, 34.7333),
    'Kasungu': const LatLng(-13.0333, 33.4833),
    'Ntchisi': const LatLng(-13.3556, 34.0042),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final statsRes = await ApiService.getDashboardStats();
      final predRes = await ApiService.getDashboardPredictions();

      if (mounted) {
        setState(() {
          if (statsRes.statusCode == 200) {
            final stats = statsRes.data['data'];
            _cohortDensity = stats['cohortDensity'] ?? [];
            _overallSuccess = double.tryParse(stats['pulse']['successRate']?.toString() ?? '0.0') ?? 0.0;
            _performanceComparison = stats['performanceComparison'] ?? [];
            _districtDistribution = stats['districtDistribution'] ?? [];
          }
          if (predRes.statusCode == 200) {
            _milestones = predRes.data['data']['milestoneCohorts'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cyber virtualisation data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: kVOlive),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTopRow(),
          const SizedBox(height: 24),
          _buildMiddleRow(),
          const SizedBox(height: 24),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.hub_rounded, color: kVOlive, size: 28),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("System Intelligence", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kVBrown)),
            Text("Real-time data visualization from database", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        )
      ],
    );
  }

  Widget _buildTopRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildVerticalBars()),
          const SizedBox(width: 24),
          Expanded(child: _buildMainGauge()),
          const SizedBox(width: 24),
          Expanded(child: _buildSmallGauges()),
        ],
      ),
    );
  }

  Widget _buildVerticalBars() {
    int maxVal = 1;
    if (_cohortDensity.isNotEmpty) {
      maxVal = _cohortDensity.map((e) => e['value'] as int).reduce(math.max);
    }

    return _CyberCard(
      title: "COHORT DENSITY",
      child: SizedBox(
        height: 180,
        child: _cohortDensity.isEmpty 
          ? const Center(child: Text("No data", style: TextStyle(fontSize: 10, color: Colors.grey)))
          : Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _cohortDensity.take(4).map((e) {
            double percent = (e['value'] as int) / (maxVal == 0 ? 1 : maxVal);
            return _verticalBar(e['label'].toString(), percent, e['value'] as int, kVOrange);
          }).toList(),
        ),
      ),
    );
  }

  Widget _verticalBar(String label, double percent, int count, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("$count", style: const TextStyle(color: kVBrown, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 120 * math.max(0.1, percent),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  Widget _buildMainGauge() {
    return _CyberCard(
      title: "OVERALL SUCCESS",
      child: Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            children: [
              Center(
                child: CustomPaint(
                  size: const Size(140, 140),
                  painter: CyberRadialPainter(percent: _overallSuccess / 100, color: kVOlive),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${_overallSuccess.toStringAsFixed(1)}%", style: const TextStyle(color: kVBrown, fontSize: 24, fontWeight: FontWeight.w900)),
                    const Text("PASS RATE", style: TextStyle(color: kVOlive, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallGauges() {
    return _CyberCard(
      title: "MILESTONE TRACKING",
      child: SizedBox(
        height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_milestones.isEmpty)
              const Center(child: Text("No data", style: TextStyle(fontSize: 10, color: Colors.grey)))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _milestones.take(4).map((m) {
                  return _smallGauge(m['student_count'].toString(), "COHORT ${m['cohort']}", kVCyan);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallGauge(String val, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            color: color.withOpacity(0.05),
          ),
          child: Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: kVBrown.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMiddleRow() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildWaveChart()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildProgressBars()),
        ],
      ),
    );
  }

  Widget _buildWaveChart() {
    return _CyberCard(
      title: "PROGRAM PERFORMANCE TRENDS",
      child: SizedBox(
        height: 200,
        child: _performanceComparison.isEmpty 
          ? const Center(child: Text("No performance data available", style: TextStyle(fontSize: 12, color: Colors.grey)))
          : LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < _performanceComparison.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_performanceComparison[index]['year'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      );
                    }
                    return const Text("");
                  }
                )
              )
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              _waveBarData(
                _performanceComparison.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['CHATs'] ?? 0).toDouble())).toList(),
                kVOlive,
                "CHATs"
              ),
              _waveBarData(
                _performanceComparison.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['Study Circle'] ?? 0).toDouble())).toList(),
                kVOrange,
                "Study Circles"
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _waveBarData(List<FlSpot> spots, Color color, String label) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildProgressBars() {
    return _CyberCard(
      title: "METRIC LIST",
      child: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _cyberProgressBar("01", "Cohort", 0.9, kVOrange),
            _cyberProgressBar("02", "Impact", 0.7, kVCyan),
            _cyberProgressBar("03", "Reach", 0.5, kVGold),
            _cyberProgressBar("04", "Growth", 0.8, kVBrown),
            _cyberProgressBar("05", "Retention", 0.4, kVPurple),
          ],
        ),
      ),
    );
  }

  Widget _cyberProgressBar(String num, String label, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(num, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
              Text(label, style: TextStyle(color: kVBrown.withOpacity(0.7), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildMalawiMap()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildBigGauge()),
          const SizedBox(width: 14),
          Expanded(flex: 1, child: _buildStylizedPie()),
        ],
      ),
    );
  }

  Widget _buildMalawiMap() {
    return _CyberCard(
      title: "MALAWI IMPACT REACH",
      child: SizedBox(
        height: 220,
        child: _districtDistribution.isEmpty 
          ? const Center(child: Text("Loading map data...", style: TextStyle(fontSize: 10, color: Colors.grey)))
          : FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-13.2543, 34.3015), // Center of Malawi
            initialZoom: 6.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ageafrica.sms',
            ),
            MarkerLayer(
              markers: _districtDistribution.map((district) {
                String name = district['district'];
                int count = district['count'];
                LatLng? pos = _districtCoords[name];
                
                if (pos == null) return null;

                return Marker(
                  point: pos,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$name: $count registered scholars"),
                          backgroundColor: kVOlive,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: kVOlive, width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                          ),
                          child: Text("$count", style: const TextStyle(color: kVOlive, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.location_on, color: kVOlive, size: 24),
                      ],
                    ),
                  ),
                );
              }).whereType<Marker>().toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigGauge() {
    return _CyberCard(
      title: "COHORT RETENTION",
      child: SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("68%", style: TextStyle(color: kVBrown, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              CustomPaint(
                size: const Size(120, 60),
                painter: CyberHalfGaugePainter(percent: 0.68, color: kVOrange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylizedPie() {
    return _CyberCard(
      title: "RESOURCE ALLOCATION",
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("32%", style: TextStyle(color: kVBrown, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 0,
                  sections: [
                    PieChartSectionData(color: kVBrown, value: 32, radius: 55, title: ""),
                    PieChartSectionData(color: Colors.grey.shade100, value: 68, radius: 50, title: ""),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CyberCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _CyberCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class CyberRadialPainter extends CustomPainter {
  final double percent;
  final Color color;
  final double thickness;
  CyberRadialPainter({required this.percent, required this.color, this.thickness = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - thickness / 2;

    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * percent, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CyberRadialPainter oldDelegate) => true;
}

class CyberHalfGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  CyberHalfGaugePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [color, kVOlive, color.withOpacity(0.1)],
        stops: [0.0, percent, 0.5],
        startAngle: math.pi,
        endAngle: 2 * math.pi,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, Paint()..color = Colors.grey.shade100..style = PaintingStyle.stroke..strokeWidth = 15);
    canvas.drawArc(rect, math.pi, math.pi * percent, false, paint);
  }

  @override
  bool shouldRepaint(covariant CyberHalfGaugePainter oldDelegate) => true;
}
