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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (!isMobile) _buildExecutiveHeader(isMobile),
          if (isMobile) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTypeToggle(true),
            ),
          ],
          _buildMainTabBar(isMobile),
          Expanded(
            child: _isLoading 
              ? const SizedBox.shrink()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIndividualView(isMobile),
                    _buildCohortView(isMobile),
                    _buildSubjectView(isMobile),
                    _buildRiskView(isMobile),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Performance Analysis Portal",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16, 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF4C3C32), 
                    letterSpacing: -0.2
                  ),
                ),
              ],
            ),
          ),
          _buildTypeToggle(isMobile),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : null,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Secondary', label: Text("SEC"), icon: Icon(Icons.school_outlined, size: 16)),
          ButtonSegment(value: 'University', label: Text("UNI"), icon: Icon(Icons.account_balance_outlined, size: 16)),
        ],
        selected: {_selectedType},
        onSelectionChanged: (val) {
          setState(() => _selectedType = val.first);
          _fetchCurrentTabData();
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: kBrandBrown,
          selectedForegroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainTabBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: const BoxDecoration(
        color: Colors.white, 
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF9AB334),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF9AB334),
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
        tabs: const [
          Tab(text: "INDIVIDUAL TREND"),
          Tab(text: "COHORT ANALYTICS"),
          Tab(text: "SUBJECT INTELLIGENCE"),
          Tab(text: "RISK INDICATORS"),
        ],
      ),
    );
  }

  // --- VIEW 1: INDIVIDUAL ---
  Widget _buildIndividualView(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScholarPicker(),
          const SizedBox(height: 32),
          if (_individualData != null) ...[
            _buildIndividualInsightsSummary(isMobile),
            const SizedBox(height: 32),
            if (_selectedType == 'Secondary') ...[
              _buildMSCEForecastingCard(isMobile),
              const SizedBox(height: 32),
            ],
            if (_aiNarrative.isNotEmpty) _buildAINarrativeBox(),
            const SizedBox(height: 32),
            if (isMobile)
              Column(
                children: [
                  _buildScoreTrendLine(isMobile),
                  const SizedBox(height: 24),
                  _buildFlagHistory(isMobile),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildScoreTrendLine(false)),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildFlagHistory(false)),
                ],
              ),
            const SizedBox(height: 32),
            _buildPeriodBreakdownTable(isMobile),
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

  Widget _buildScoreTrendLine(bool isMobile) {
    final timeline = _individualData!['timeline'] as List;
    if (timeline.isEmpty) return const SizedBox();

    return _AnalysisCard(
      isMobile: isMobile,
      title: "Score Trajectory",
      subtitle: "Performance over time",
      child: SizedBox(
        height: isMobile ? 220 : 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: isMobile ? 32 : 40, getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 10)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                if (v.toInt() < timeline.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(timeline[v.toInt()]['period'].toString().replaceAll('-', '\n'), 
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
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

  Widget _buildFlagHistory(bool isMobile) {
    final history = _individualData!['flagHistory'] as List;
    return _AnalysisCard(
      isMobile: isMobile,
      title: "Audit Log",
      subtitle: "Promotion outcomes",
      child: Column(
        children: [
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("No flags found.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            ...history.map((h) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.flag_rounded, color: h['result'].toString().contains('Fail') ? Colors.red : kBrandOlive),
              title: Text("${h['year']} | ${h['result']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text("Avg: ${h['average']}% | ${h['from_class']} → ${h['to_class']}", style: const TextStyle(fontSize: 11)),
            )),
        ],
      ),
    );
  }

  Widget _buildPeriodBreakdownTable(bool isMobile) {
    final timeline = _individualData!['timeline'] as List;
    return _AnalysisCard(
      isMobile: isMobile,
      title: "Granular Breakdown",
      subtitle: "Threshold mapping",
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: isMobile ? 24 : 32,
          horizontalMargin: 0,
          columns: const [
            DataColumn(label: Text("PERIOD")),
            DataColumn(label: Text("AVG")),
            DataColumn(label: Text("AGG")),
            DataColumn(label: Text("BEST")),
          ],
          rows: timeline.map((t) {
            final best6 = t['best6'] as List;
            final agg = _calculateAggregatePoints(best6);
            return DataRow(cells: [
              DataCell(Text(t['period'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataCell(Text("${t['average']}%", style: const TextStyle(fontSize: 12))),
              DataCell(Text("${agg.toInt()} pts", 
                style: TextStyle(color: agg <= 36 ? kBrandOlive : Colors.red, fontWeight: FontWeight.w900, fontSize: 12))),
              DataCell(Text(best6.isNotEmpty ? best6[0]['subject'] : 'N/A', style: const TextStyle(fontSize: 11))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  double _calculateAggregatePoints(List<dynamic> best6) {
    double total = 0;
    for (var item in best6) {
      final marks = double.tryParse(item['marks'].toString()) ?? 0.0;
      final grade = gradeFromMarks(marks, isUniversity: false);
      total += grade.point;
    }
    if (best6.isEmpty) return 54.0;
    if (best6.length < 6) {
      total += (6 - best6.length) * 9.0;
    }
    return total;
  }

  Widget _buildMSCEForecastingCard(bool isMobile) {
    final timeline = _individualData!['timeline'] as List;
    if (timeline.isEmpty) return const SizedBox();
    
    final latestBest6 = timeline.last['best6'] as List;
    final double currentPoints = _calculateAggregatePoints(latestBest6);
    
    double forecastedPoints = currentPoints;
    if (timeline.length >= 2) {
      final prevBest6 = timeline[timeline.length - 2]['best6'] as List;
      final double prevPoints = _calculateAggregatePoints(prevBest6);
      final double improvement = prevPoints - currentPoints; // Positive if points decreased (improved)
      forecastedPoints = currentPoints - (improvement * 0.5); // conservative projection
    }
    
    forecastedPoints = forecastedPoints.clamp(6.0, 54.0);
    
    final Color forecastColor = forecastedPoints <= 18 ? Colors.green : (forecastedPoints <= 36 ? Colors.orange : Colors.red);
    final String division = forecastedPoints <= 17 ? Translator.translate("Division 1 (Excellent)") : (forecastedPoints <= 30 ? Translator.translate("Division 2") : Translator.translate("Division 3 / Fail"));

    return _AnalysisCard(
      isMobile: isMobile,
      title: Translator.translate("MSCE Trend Forecasting"),
      subtitle: Translator.translate("Aggregate point projection (Best Six)"),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _forecastMetric(Translator.translate("Current Aggregate"), currentPoints.toInt().toString(), "pts", kBrandBrown),
              const Icon(Icons.auto_graph_rounded, color: Colors.grey, size: 32),
              _forecastMetric(Translator.translate("Forecasted MSCE"), forecastedPoints.toInt().toString(), "pts", forecastColor),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: forecastColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: forecastColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: forecastColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.psychology_outlined, color: forecastColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Translator.translate("PROJECTED OUTCOME"), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: forecastColor, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(division, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: forecastColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastMetric(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
              TextSpan(text: " $unit", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withOpacity(0.5))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualInsightsSummary(bool isMobile) {
    final info = _individualData!['scholarInfo'];
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _MetricIndicator(label: "CURRENT YEAR", value: "Year ${info['currentRelativeYear']}", icon: Icons.timeline, isMobile: true),
              const SizedBox(width: 12),
              _MetricIndicator(label: "REMAINING", value: "${info['yearsRemaining']} Yrs", icon: Icons.hourglass_empty_rounded, isMobile: true),
            ],
          ),
          const SizedBox(height: 12),
          _MetricIndicator(
            label: "RISK LEVEL", 
            value: info['academicFlag'] ?? "Stable", 
            icon: Icons.shield_rounded, 
            color: info['academicFlag'] == null ? kBrandOlive : Colors.orange,
            isMobile: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingAI ? null : _generateAINarrative,
              icon: _isGeneratingAI 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded),
              label: const Text("ASK AI ANALYST"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

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
  Widget _buildCohortView(bool isMobile) {
    if (_cohortData == null) return const SizedBox();
    final groups = _cohortData['classGroups'] as Map? ?? {};
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Column(
        children: [
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    _MetricIndicator(label: "ON-TRACK", value: "${_cohortData['summary']['onTrack']}", icon: Icons.check_circle_rounded, color: kBrandOlive, isMobile: true),
                    const SizedBox(width: 12),
                    _MetricIndicator(label: "DELAYED", value: "${_cohortData['summary']['atRisk']}", icon: Icons.warning_rounded, color: Colors.orange, isMobile: true),
                  ],
                ),
                const SizedBox(height: 12),
                _MetricIndicator(label: "TOTAL COHORT", value: "${_cohortData['summary']['totalScholars']}", icon: Icons.groups_rounded, isMobile: true),
              ],
            )
          else
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
            isMobile: isMobile,
            title: "Performance Distribution",
            subtitle: "Analysis by Class",
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("CLASS")),
                  DataColumn(label: Text("TOTAL")),
                  DataColumn(label: Text("SUPP.")),
                  DataColumn(label: Text("REPEAT")),
                  DataColumn(label: Text("SUCCESS")),
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
          ),
        ],
      ),
    );
  }

  // --- VIEW 3: SUBJECT ---
  Widget _buildSubjectView(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Column(
        children: [
          _AnalysisCard(
            isMobile: isMobile,
            title: "Subject Audit",
            subtitle: "Failure density mapping",
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("SUBJECT")),
                  DataColumn(label: Text("AVG")),
                  DataColumn(label: Text("FAIL")),
                  DataColumn(label: Text("TOTAL")),
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
          ),
        ],
      ),
    );
  }

  // --- VIEW 4: RISK ---
  Widget _buildRiskView(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Column(
        children: [
          _AnalysisCard(
            isMobile: isMobile,
            title: "Warning Matrix",
            subtitle: "Critical distance mapping",
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text("NAME")),
                  DataColumn(label: Text("AVG")),
                  DataColumn(label: Text("GAP")),
                  DataColumn(label: Text("ACTION")),
                ],
                rows: _riskData.map((r) {
                  final double dist = r['distance']?.toDouble() ?? 0.0;
                  return DataRow(cells: [
                    DataCell(Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(Text("${r['average'].toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12))),
                    DataCell(Text("${dist > 0 ? '+' : ''}${dist.toStringAsFixed(1)}%", 
                      style: TextStyle(color: dist >= 0 ? Colors.orange : Colors.red, fontWeight: FontWeight.w900, fontSize: 12))),
                    DataCell(TextButton(
                      onPressed: () {}, 
                      child: const Text("ALERT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandOlive)),
                    )),
                  ]);
                }).toList(),
              ),
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
  final bool isMobile;
  const _MetricIndicator({required this.label, required this.value, required this.icon, this.color, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF4C3C32);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(color: effectiveColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: effectiveColor, size: isMobile ? 20 : 24),
            ),
            SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), 
                    style: TextStyle(fontSize: isMobile ? 8 : 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.0), 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(value, 
                    style: TextStyle(fontSize: isMobile ? 14 : 18, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), letterSpacing: -0.5), 
                    overflow: TextOverflow.ellipsis
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

class _AnalysisCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final bool isMobile;
  const _AnalysisCard({required this.title, required this.subtitle, required this.child, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(), 
            style: const TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF9AB334), 
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle, 
            style: const TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF4C3C32), 
              letterSpacing: -0.5
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}
