import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

// PREDICTIONS LOCAL PALETTE
const Color kP_Brown = Color(0xFF4C3C32);
const Color kP_Olive = Color(0xFF9AB334);
const Color kP_Orange = Color(0xFFE05B1C);
const Color kP_Gold = Color(0xFFD4AF37);

class VirtualisationPredictionsComponent extends StatefulWidget {
  const VirtualisationPredictionsComponent({super.key});

  @override
  State<VirtualisationPredictionsComponent> createState() => _VirtualisationPredictionsComponentState();
}

class _VirtualisationPredictionsComponentState extends State<VirtualisationPredictionsComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  socket_io.Socket? _socket;
  bool _isLoading = true;

  final List<LiveEvent> _liveEvents = [];
  final ScrollController _scrollController = ScrollController();

  double _baseGraduationProb = 88.5;
  int _baseActiveScholars = 120;
  int _baseAtRiskCount = 8;
  double _baseCohortScore = 74.2;
  double _baseBudget = 18000000.0;
  double _averageCostPerScholar = 150000.0;

  double _sliderMentorship = 10.0;
  double _sliderTutorCoverage = 20.0;
  double _sliderExtraFunding = 0.0;

  final List<MapParticle> _particles = [];
  final List<FlSpot> _heartbeatSpots = [];
  double _heartbeatTimer = 0;
  Timer? _mockDataTimer;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      _heartbeatSpots.add(FlSpot(i.toDouble(), 30 + math.Random().nextDouble() * 20));
      _heartbeatTimer = i.toDouble();
    }
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..addListener(() {
        _updateParticles();
        _updateHeartbeat();
        if (mounted) setState(() {});
    })..repeat();
    _fetchPredictions();
    _connectSocket();
    _startMockTicker();
  }

  void _updateHeartbeat() {
    _heartbeatTimer += 0.1;
    if (_heartbeatTimer % 1.0 < 0.1) {
       _heartbeatSpots.add(FlSpot(_heartbeatTimer, 30 + math.Random().nextDouble() * 20));
       if (_heartbeatSpots.length > 30) _heartbeatSpots.removeAt(0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose(); _socket?.disconnect(); _socket?.dispose(); _mockDataTimer?.cancel(); _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPredictions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDashboardPredictions();
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        setState(() {
          _baseGraduationProb = double.parse(data['graduationProbability']?.toString() ?? '88.5');
          _baseActiveScholars = int.parse(data['activeScholars']?.toString() ?? '120');
          _baseAtRiskCount = int.parse(data['atRiskCount']?.toString() ?? '8');
          _baseCohortScore = double.parse(data['predictedCohortScore']?.toString() ?? '74.2');
          _baseBudget = double.parse(data['projectedBudgetRequired']?.toString() ?? '18000000');
          _averageCostPerScholar = double.parse(data['averageCostPerScholar']?.toString() ?? '150000');
        });
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _connectSocket() {
    try {
      _socket = socket_io.io('http://localhost:5000', socket_io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build());
      _socket!.connect();
      _socket!.on('notification', (data) {
        final msg = data['message'] ?? 'Notification received';
        _addLiveEvent(LiveEvent(message: msg, timestamp: DateTime.now(), type: LiveEventType.system));
      });
    } catch (e) {}
  }

  void _startMockTicker() {
    _mockDataTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      final rand = math.Random();
      final type = LiveEventType.values[rand.nextInt(LiveEventType.values.length)];
      LiveEvent event;
      switch (type) {
        case LiveEventType.funding:
          event = LiveEvent(message: "MWK received from sponsor.", timestamp: DateTime.now(), type: type);
          _spawnParticle(ParticleSource.sponsor, ParticleDest.hub, kP_Gold); break;
        case LiveEventType.attendance:
          event = LiveEvent(message: "Live check-in: 95% attendance.", timestamp: DateTime.now(), type: type);
          _spawnParticle(ParticleSource.school, ParticleDest.hub, Colors.blue); break;
        case LiveEventType.grade:
          event = LiveEvent(message: "Academic record added.", timestamp: DateTime.now(), type: type);
          _spawnParticle(ParticleSource.school, ParticleDest.hub, kP_Olive); break;
        case LiveEventType.disbursement:
          event = LiveEvent(message: "Tuition support sent.", timestamp: DateTime.now(), type: type);
          _spawnParticle(ParticleSource.hub, ParticleDest.scholar, kP_Orange); break;
        case LiveEventType.system:
          event = LiveEvent(message: "System sync verified.", timestamp: DateTime.now(), type: type); break;
      }
      _addLiveEvent(event);
    });
  }

  void _addLiveEvent(LiveEvent event) {
    if (!mounted) return;
    setState(() { _liveEvents.insert(0, event); if (_liveEvents.length > 50) _liveEvents.removeLast(); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _spawnParticle(ParticleSource src, ParticleDest dest, Color color) {
    setState(() { _particles.add(MapParticle(progress: 0.0, color: color, speed: 0.02 + (math.Random().nextDouble() * 0.015), source: src, dest: dest)); });
  }

  void _updateParticles() {
    for (int i = _particles.length - 1; i >= 0; i--) { _particles[i].progress += _particles[i].speed; if (_particles[i].progress >= 1.0) _particles.removeAt(i); }
  }

  double get _simulatedGraduationProb { return math.min(99.9, _baseGraduationProb + (_sliderMentorship * 0.22) + ((_sliderTutorCoverage - 20) * 0.05)); }
  double get _simulatedCohortScore { return math.min(100.0, _baseCohortScore + ((_sliderMentorship - 10) * 0.15) + ((_sliderTutorCoverage - 20) * 0.12)); }
  int get _simulatedAtRiskCount { return math.max(0, _baseAtRiskCount - (((_sliderTutorCoverage - 20) * 0.15) + ((_sliderMentorship - 10) * 0.1)).round()); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: kP_Olive)));
    final bool isWide = MediaQuery.of(context).size.width > 1150;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Project Virtualisation & Predictions", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kP_Brown, letterSpacing: -0.5)),
      const Text("Relationship flows and predictive outcome simulation.", style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 20),
      if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _buildVirtualisationCard()), const SizedBox(width: 20), Expanded(flex: 2, child: _buildSimulationPanel())])
      else Column(children: [_buildVirtualisationCard(), const SizedBox(height: 20), _buildSimulationPanel()]),
    ]);
  }

  Widget _buildVirtualisationCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(28), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Relationship Virtual Map", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kP_Brown)), Text("Transaction flows and logs", style: TextStyle(fontSize: 11, color: Colors.grey))]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: kP_Olive.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: kP_Olive, shape: BoxShape.circle)), const SizedBox(width: 8), const Text("Live Feed connected", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kP_Olive))])),
        ])),
        Container(height: 280, width: double.infinity, color: Colors.grey.shade50.withOpacity(0.5), child: CustomPaint(painter: ProjectVirtualMapPainter(particles: _particles), child: Stack(children: [
          Positioned(left: 20, top: 100, child: _nodeIndicator(Icons.volunteer_activism_rounded, "Sponsors", kP_Gold)),
          Positioned(left: 170, top: 100, child: _nodeIndicator(Icons.location_city_rounded, "Hub", kP_Brown, isCenter: true)),
          Positioned(right: 20, top: 25, child: _nodeIndicator(Icons.school_rounded, "Schools", Colors.blue)),
          Positioned(right: 20, bottom: 25, child: _nodeIndicator(Icons.people_rounded, "Scholars", kP_Orange)),
        ]))),
        Container(height: 140, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))), child: Row(children: [
          Expanded(flex: 3, child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(24), itemCount: _liveEvents.length, itemBuilder: (context, index) => Text("${_liveEvents[index].message}", style: const TextStyle(fontSize: 11, color: Colors.grey)))),
          Container(width: 1, height: 100, color: Colors.grey.shade100),
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(16), child: LineChart(LineChartData(gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: _heartbeatSpots, isCurved: true, color: kP_Olive, barWidth: 2, dotData: const FlDotData(show: false))])))),
        ])),
      ]),
    );
  }

  Widget _nodeIndicator(IconData icon, String label, Color color, {bool isCenter = false}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isCenter ? color : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: isCenter ? Colors.white : color), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCenter ? Colors.white : kP_Brown))]));
  }

  Widget _buildSimulationPanel() {
    return Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Predictive Simulator", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kP_Brown)),
      const SizedBox(height: 24),
      _buildSimIndicator("Graduation Probability", "${_simulatedGraduationProb.toStringAsFixed(1)}%", kP_Olive),
      const SizedBox(height: 16),
      _buildSimIndicator("Avg Cohort Score", "${_simulatedCohortScore.toStringAsFixed(1)}%", kP_Gold),
      const SizedBox(height: 16),
      _buildSimIndicator("At-Risk Scholars", "$_simulatedAtRiskCount", kP_Orange),
      const SizedBox(height: 24),
      const Divider(),
      _buildSliderItem("Mentorship", _sliderMentorship, 0, 40, (v) => setState(() => _sliderMentorship = v), kP_Olive),
      _buildSliderItem("Tutoring", _sliderTutorCoverage, 0, 100, (v) => setState(() => _sliderTutorCoverage = v), kP_Gold),
    ]));
  }

  Widget _buildSimIndicator(String title, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kP_Brown))]);
  }

  Widget _buildSliderItem(String title, double current, double min, double max, ValueChanged<double> onChanged, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kP_Brown)), Slider(value: current, min: min, max: max, onChanged: onChanged, activeColor: color)]);
  }
}

enum LiveEventType { funding, attendance, grade, disbursement, system }
class LiveEvent { final String message; final DateTime timestamp; final LiveEventType type; LiveEvent({required this.message, required this.timestamp, required this.type}); }
enum ParticleSource { sponsor, school, hub }
enum ParticleDest { hub, scholar }
class MapParticle { double progress; final Color color; final double speed; final ParticleSource source; final ParticleDest dest; MapParticle({required this.progress, required this.color, required this.speed, required this.source, required this.dest}); }

class ProjectVirtualMapPainter extends CustomPainter {
  final List<MapParticle> particles;
  ProjectVirtualMapPainter({required this.particles});
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.grey.shade200..strokeWidth = 2..style = PaintingStyle.stroke;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final sponsorNode = Offset(size.width * 0.15, size.height * 0.50), hubNode = Offset(size.width * 0.50, size.height * 0.50), schoolNode = Offset(size.width * 0.85, size.height * 0.25), scholarNode = Offset(size.width * 0.85, size.height * 0.75);
    canvas.drawLine(sponsorNode, hubNode, linePaint); canvas.drawLine(schoolNode, hubNode, linePaint); canvas.drawLine(hubNode, scholarNode, linePaint);
    canvas.drawCircle(sponsorNode, 6, dotPaint..color = kP_Gold); canvas.drawCircle(hubNode, 8, dotPaint..color = kP_Brown); canvas.drawCircle(schoolNode, 6, dotPaint..color = Colors.blue); canvas.drawCircle(scholarNode, 6, dotPaint..color = kP_Orange);
    for (var particle in particles) {
      Offset start = Offset.zero, end = Offset.zero;
      if (particle.source == ParticleSource.sponsor && particle.dest == ParticleDest.hub) { start = sponsorNode; end = hubNode; }
      else if (particle.source == ParticleSource.school && particle.dest == ParticleDest.hub) { start = schoolNode; end = hubNode; }
      else if (particle.source == ParticleSource.hub && particle.dest == ParticleDest.scholar) { start = hubNode; end = scholarNode; }
      if (start != Offset.zero && end != Offset.zero) { canvas.drawCircle(Offset.lerp(start, end, particle.progress)!, 5.0, Paint()..color = particle.color); }
    }
  }
  @override
  bool shouldRepaint(covariant ProjectVirtualMapPainter oldDelegate) => true;
}
