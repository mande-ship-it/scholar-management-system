import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'academics_utils.dart';

class PerformanceAnalysisComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  const PerformanceAnalysisComponent({super.key, this.forcedSchoolType});

  @override
  State<PerformanceAnalysisComponent> createState() => _PerformanceAnalysisComponentState();
}

class _PerformanceAnalysisComponentState extends State<PerformanceAnalysisComponent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  late String _selectedType; // Secondary or University
  
  // Data for views
  dynamic _cohortData;
  List<dynamic> _subjectData = [];
  List<dynamic> _riskData = [];
  Map<String, dynamic>? _individualData;
  Student? _selectedScholar;
  String _aiNarrative = "";
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.forcedSchoolType == SchoolType.university ? 'University' : 'Secondary';
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _fetchCurrentTabData();
    });
    _fetchCurrentTabData();
  }

  Future<void> _fetchCurrentTabData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      switch (_tabController.index) {
        case 0: // Scholar Trend
          if (_selectedScholar != null) await _fetchIndividualTrend(_selectedScholar!.id);
          break;
        case 1: // Cohort Analytics
          final res = await ApiService.getCohortAnalytics(_selectedType);
          _cohortData = res.data['data'];
          break;
        case 2: // Subject Intelligence
          final res = await ApiService.getSubjectInsights(_selectedType);
          _subjectData = res.data['data'];
          break;
        case 3: // Risk Indicators
          final res = await ApiService.getEarlyWarningRisk();
          _riskData = res.data['data'];
          break;
      }
    } catch (e) {
      debugPrint('Error fetching performance data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchIndividualTrend(String scholarId) async {
    final res = await ApiService.getScholarTrend(scholarId);
    setState(() {
      _individualData = res.data['data'];
      _aiNarrative = ""; // Clear old narrative
    });
  }

  Future<void> _generateAINarrative() async {
    if (_individualData == null) return;
    setState(() => _isGeneratingAI = true);
    try {
      final info = _individualData!['scholarInfo'];
      final timeline = _individualData!['timeline'] as List;
      
      final prompt = "Analyze this student's academic performance. Name: ${info['fullName']}, Level: ${info['schoolType']}, "
          "Current: ${info['currentRelativeYear']}, Remaining: ${info['yearsRemaining']}. "
          "Historical Scores: ${timeline.map((t) => '${t['period']}: ${t['average']}%').join(', ')}. "
          "Explain trends, identify weak areas, and suggest interventions.";

      final res = await ApiService.chatWithAI(prompt, currentPage: 'Performance Analysis');
      if (mounted) {
        setState(() {
          _aiNarrative = res.data['data']['reply'] ?? "AI analysis unavailable.";
        });
      }
    } catch (e) {
      debugPrint('AI Narrative Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildExecutiveHeader(),
          _buildMainTabBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIndividualView(),
                    _buildCohortView(),
                    _buildSubjectView(),
                    _buildRiskView(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.analytics_rounded, color: kBrandOlive, size: 28),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Performance Intelligence Hub", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.8)),
                Text("Longitudinal trends, risk forecasting, and subject-level support mapping.", 
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildTypeToggle(),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Secondary', label: Text("SECONDARY"), icon: Icon(Icons.school_outlined)),
        ButtonSegment(value: 'University', label: Text("UNIVERSITY"), icon: Icon(Icons.account_balance_outlined)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (val) {
        setState(() => _selectedType = val.first);
        _fetchCurrentTabData();
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kBrandBrown,
        selectedForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  Widget _buildMainTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: TabBar(
        controller: _tabController,
        labelColor: kBrandOlive,
        unselectedLabelColor: Colors.grey,
        indicatorColor: kBrandOlive,
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(vertical: 16),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        tabs: const [
          Tab(text: "SCHOLAR TREND"),
          Tab(text: "COHORT ANALYTICS"),
          Tab(text: "SUBJECT INTELLIGENCE"),
          Tab(text: "RISK INDICATORS"),
        ],
      ),
    );
  }

  // --- VIEW 1: INDIVIDUAL ---
  Widget _buildIndividualView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScholarPicker(),
          const SizedBox(height: 32),
          if (_individualData != null) ...[
            _buildIndividualInsightsSummary(),
            const SizedBox(height: 32),
            if (_aiNarrative.isNotEmpty) _buildAINarrativeBox(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildScoreTrendLine()),
                const SizedBox(width: 32),
                Expanded(flex: 2, child: _buildFlagHistory()),
              ],
            ),
            const SizedBox(height: 32),
            _buildPeriodBreakdownTable(),
          ] else
            _buildEmptyIndividualState(),
        ],
      ),
    );
  }

  Widget _buildScholarPicker() {
    return Autocomplete<Student>(
      displayStringForOption: (s) => s.name,
      optionsBuilder: (val) {
        if (val.text.isEmpty) return const Iterable<Student>.empty();
        return kStudents.where((s) => s.name.toLowerCase().contains(val.text.toLowerCase()));
      },
      onSelected: (s) {
        setState(() => _selectedScholar = s);
        _fetchIndividualTrend(s.id);
      },
      fieldViewBuilder: (ctx, ctrl, focus, onSubmitted) {
        return TextField(
          controller: ctrl,
          focusNode: focus,
          decoration: InputDecoration(
            hintText: "Search scholar for detailed mapping...",
            prefixIcon: const Icon(Icons.person_search_rounded, color: kBrandOlive),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        );
      },
    );
  }

  Widget _buildAINarrativeBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBrandOlive.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrandOlive.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: kBrandOlive, size: 20),
              SizedBox(width: 12),
              Text("AI ANALYST INSIGHT", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 11, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_aiNarrative, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildScoreTrendLine() {
    final timeline = _individualData!['timeline'] as List;
    if (timeline.isEmpty) return const SizedBox();

    return _AnalysisCard(
      title: "Academic Trajectory",
      subtitle: "Term/Semester average scores over time",
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                if (v.toInt() < timeline.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(timeline[v.toInt()]['period'].toString().replaceAll('-', '\n'), 
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox();
              })),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: timeline.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['average'].toDouble())).toList(),
                isCurved: true,
                color: kBrandOlive,
                barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: kBrandOlive.withOpacity(0.05)),
              ),
            ],
            minY: 0, maxY: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildFlagHistory() {
    final history = _individualData!['flagHistory'] as List;
    return _AnalysisCard(
      title: "Persistence Audit",
      subtitle: "Chronological flags and promotion outcomes",
      child: Column(
        children: [
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("No progression flags on record.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            ...history.map((h) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.flag_rounded, color: h['result'].toString().contains('Fail') ? Colors.red : kBrandOlive),
              title: Text("${h['year']} | ${h['result']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Avg: ${h['average']}% | ${h['from_class']} → ${h['to_class']}"),
            )),
        ],
      ),
    );
  }

  Widget _buildPeriodBreakdownTable() {
    final timeline = _individualData!['timeline'] as List;
    return _AnalysisCard(
      title: "Granular Period Analysis",
      subtitle: "Detailed performance and distance-to-threshold mapping",
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 0,
        columns: const [
          DataColumn(label: Text("ACADEMIC PERIOD")),
          DataColumn(label: Text("AVG SCORE")),
          DataColumn(label: Text("GAP TO PASS")),
          DataColumn(label: Text("BEST SUBJECT")),
        ],
        rows: timeline.map((t) {
          final dist = t['distanceToThreshold'] as double;
          final best6 = t['best6'] as List;
          return DataRow(cells: [
            DataCell(Text(t['period'], style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text("${t['average']}%")),
            DataCell(Text("${dist > 0 ? '+' : ''}$dist%", 
              style: TextStyle(color: dist >= 0 ? kBrandOlive : Colors.red, fontWeight: FontWeight.w900))),
            DataCell(Text(best6.isNotEmpty ? best6[0]['subject'] : 'N/A')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildIndividualInsightsSummary() {
    final info = _individualData!['scholarInfo'];
    return Row(
      children: [
        _MetricIndicator(label: "CURRENT YEAR", value: "Year ${info['currentRelativeYear']} of ${info['programDurationYears']}", icon: Icons.timeline),
        const SizedBox(width: 24),
        _MetricIndicator(label: "YEARS REMAINING", value: "${info['yearsRemaining']} Years", icon: Icons.hourglass_empty_rounded),
        const SizedBox(width: 24),
        _MetricIndicator(
          label: "RISK LEVEL", 
          value: info['academicFlag'] ?? "Stable", 
          icon: Icons.shield_rounded, 
          color: info['academicFlag'] == null ? kBrandOlive : Colors.orange
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _isGeneratingAI ? null : _generateAINarrative,
          icon: _isGeneratingAI 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome_rounded),
          label: const Text("ASK AI ANALYST"),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandOlive,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- VIEW 2: COHORT ---
  Widget _buildCohortView() {
    if (_cohortData == null) return const SizedBox();
    final groups = _cohortData['classGroups'] as Map? ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Row(
            children: [
              _MetricIndicator(label: "ON-TRACK SCHOLARS", value: "${_cohortData['summary']['onTrack']}", icon: Icons.check_circle_rounded, color: kBrandOlive),
              const SizedBox(width: 24),
              _MetricIndicator(label: "DELAYED (REPEATS)", value: "${_cohortData['summary']['atRisk']}", icon: Icons.warning_rounded, color: Colors.orange),
              const SizedBox(width: 24),
              _MetricIndicator(label: "TOTAL COHORT", value: "${_cohortData['summary']['totalScholars']}", icon: Icons.groups_rounded),
            ],
          ),
          const SizedBox(height: 32),
          _AnalysisCard(
            title: "Performance Distribution by Class",
            subtitle: "Analysis of pass rates and academic flags per Form/Year",
            child: DataTable(
              columns: const [
                DataColumn(label: Text("CLASS / FORM")),
                DataColumn(label: Text("TOTAL")),
                DataColumn(label: Text("SUPPLEMENTARY")),
                DataColumn(label: Text("REPEAT")),
                DataColumn(label: Text("SUCCESS RATE")),
              ],
              rows: groups.entries.map((e) {
                final val = e.value;
                final double success = (val['total'] - val['repeat'] - val['supplementary']) / (val['total'] == 0 ? 1 : val['total']) * 100;
                return DataRow(cells: [
                  DataCell(Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text("${val['total']}")),
                  DataCell(Text("${val['supplementary']}", style: TextStyle(color: val['supplementary'] > 0 ? Colors.orange : null))),
                  DataCell(Text("${val['repeat']}", style: TextStyle(color: val['repeat'] > 0 ? Colors.red : null))),
                  DataCell(Text("${success.toStringAsFixed(1)}%")),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 3: SUBJECT ---
  Widget _buildSubjectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          _AnalysisCard(
            title: "Institutional Subject Audit",
            subtitle: "Mapping failure density and average scores across curriculum",
            child: DataTable(
              columns: const [
                DataColumn(label: Text("SUBJECT / COURSE")),
                DataColumn(label: Text("AVERAGE MARK")),
                DataColumn(label: Text("FAIL COUNT")),
                DataColumn(label: Text("TOTAL ENTRIES")),
              ],
              rows: _subjectData.map((s) {
                final double avg = s['avgMark']?.toDouble() ?? 0.0;
                return DataRow(cells: [
                  DataCell(Text(s['_id'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text("${avg.toStringAsFixed(1)}%")),
                  DataCell(Text("${s['failCount']}", style: TextStyle(color: s['failCount'] > 0 ? Colors.red : null))),
                  DataCell(Text("${s['totalCount']}")),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 4: RISK ---
  Widget _buildRiskView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          _AnalysisCard(
            title: "Early Warning Matrix",
            subtitle: "Scholars within critical distance (-10% to +5%) of pass threshold",
            child: DataTable(
              columns: const [
                DataColumn(label: Text("SCHOLAR NAME")),
                DataColumn(label: Text("INSTITUTION TYPE")),
                DataColumn(label: Text("AVG SCORE")),
                DataColumn(label: Text("GAP TO PASS")),
                DataColumn(label: Text("ACTION")),
              ],
              rows: _riskData.map((r) {
                final double dist = r['distance']?.toDouble() ?? 0.0;
                return DataRow(cells: [
                  DataCell(Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(r['schoolType'])),
                  DataCell(Text("${r['average'].toStringAsFixed(1)}%")),
                  DataCell(Text("${dist > 0 ? '+' : ''}${dist.toStringAsFixed(1)}%", 
                    style: TextStyle(color: dist >= 0 ? Colors.orange : Colors.red, fontWeight: FontWeight.w900))),
                  DataCell(TextButton(onPressed: () {}, child: const Text("NOTIFY COORDINATOR"))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIndividualState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade100),
            const SizedBox(height: 20),
            const Text("Please select a scholar to generate a performance mapping.", 
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _MetricIndicator extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  const _MetricIndicator({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (color ?? kBrandBrown).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color ?? kBrandBrown, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color ?? kBrandBrown)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _AnalysisCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}
