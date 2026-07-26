import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    return _CyberCard(
      title: "COHORT DENSITY",
      child: SizedBox(
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _verticalBar("01", 0.53, kVOrange),
            _verticalBar("02", 0.75, kVPurple),
            _verticalBar("03", 0.24, kVCyan),
          ],
        ),
      ),
    );
  }

  Widget _verticalBar(String label, double percent, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("${(percent * 100).toInt()}%", style: const TextStyle(color: kVBrown, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 120 * percent,
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
                  painter: CyberRadialPainter(percent: 0.82, color: kVOrange),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("82%", style: TextStyle(color: kVBrown, fontSize: 28, fontWeight: FontWeight.w900)),
                    Text("STEP 1", style: TextStyle(color: kVOrange, fontSize: 10, fontWeight: FontWeight.bold)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _smallGauge("37%", "STEP 2", kVCyan),
                _smallGauge("58%", "STEP 3", kVGold),
                _smallGauge("18%", "STEP 4", kVOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallGauge(String val, String label, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              Center(
                child: CustomPaint(
                  size: const Size(50, 50),
                  painter: CyberRadialPainter(percent: double.parse(val.replaceAll('%', '')) / 100, color: color, thickness: 4),
                ),
              ),
              Center(child: Text(val, style: const TextStyle(color: kVBrown, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
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
      title: "PERFORMANCE BEZIER WAVES",
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              _waveBarData([const FlSpot(0, 3), const FlSpot(2, 5), const FlSpot(4, 4), const FlSpot(6, 8), const FlSpot(8, 6)], kVGold),
              _waveBarData([const FlSpot(0, 2), const FlSpot(2, 4), const FlSpot(4, 6), const FlSpot(6, 5), const FlSpot(8, 7)], kVOrange),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _waveBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.05),
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
          Expanded(flex: 2, child: _buildCyberWorldMap()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildBigGauge()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildStylizedPie()),
        ],
      ),
    );
  }

  Widget _buildCyberWorldMap() {
    return _CyberCard(
      title: "GLOBAL IMPACT REACH",
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  size: const Size(400, 200),
                  painter: CyberWorldMapPainter(),
                ),
              ),
            ),
            _mapMarker(100, 50, "82%", kVOlive),
            _mapMarker(250, 120, "64%", kVOrange),
            _mapMarker(50, 150, "47%", kVGold),
            _mapMarker(180, 40, "10%", kVBrown),
          ],
        ),
      ),
    );
  }

  Widget _mapMarker(double x, double y, String label, Color color) {
    return Positioned(
      left: x,
      top: y,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: color, width: 0.5)),
            child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          Container(width: 2, height: 10, color: color.withOpacity(0.5)),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6)])),
        ],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CyberWorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kVOlive
      ..style = PaintingStyle.fill;

    final rand = math.Random(42); // Fixed seed for consistent dots
    for (int i = 0; i < 400; i++) {
      double x = rand.nextDouble() * size.width;
      double y = rand.nextDouble() * size.height;
      
      // Basic world map shape logic (extremely simplified)
      bool inMap = false;
      // Americas
      if (x < size.width * 0.3 && y > size.height * 0.2 && y < size.height * 0.8) inMap = true;
      // Eurasia + Africa
      if (x > size.width * 0.4 && x < size.width * 0.9 && y > size.height * 0.1 && y < size.height * 0.7) inMap = true;
      // Australia
      if (x > size.width * 0.8 && y > size.height * 0.6 && y < size.height * 0.9) inMap = true;

      if (inMap) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
