import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'academics_utils.dart';

class PerformanceAnalysisComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  final String? scholarId;
  final VoidCallback? onBack;
  final bool showBackButton;
  const PerformanceAnalysisComponent({super.key, this.forcedSchoolType, this.scholarId, this.onBack, this.showBackButton = true});

  @override
  State<PerformanceAnalysisComponent> createState() => _PerformanceAnalysisComponentState();
}

class _PerformanceAnalysisComponentState extends State<PerformanceAnalysisComponent> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  late String _selectedType; // Secondary or University
  bool _isFieldOfficer = false;
  
  // Filtering
  String _analysisScope = 'All'; // All, District, School, Scholar
  String? _selectedDistrict;
  String? _selectedSchoolId;
  String? _selectedSchoolName;

  // Data for views
  dynamic _cohortData;
  List<dynamic> _subjectData = [];
  List<dynamic> _riskData = [];
  Map<String, dynamic>? _engagementData;
  Map<String, dynamic>? _individualData;
  Student? _selectedScholar;
  String _aiNarrative = "";
  bool _isGeneratingAI = false;
  bool _isSearchExpanded = false;

  List<Map<String, dynamic>> _allSchools = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.forcedSchoolType == SchoolType.university ? 'University' : 'Secondary';
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _fetchCurrentTabData();
    });
    _checkRoleAndInitialize();
  }

  Future<void> _checkRoleAndInitialize() async {
    try {
      final res = await ApiService.getAccountProfile();
      if (res.statusCode == 200) {
        final data = res.data['data'];
        final role = (data['role_name'] ?? '').toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isFieldOfficer = role.contains('field');
            if (widget.scholarId != null) {
              _analysisScope = 'Scholar';
              _tabController.animateTo(0);
            } else if (_isFieldOfficer) {
              _selectedType = 'Secondary';
              _selectedDistrict = data['assignedDistrict'];
              _analysisScope = 'District';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Role check error: $e');
    }
    await _fetchScholars();
    
    if (widget.scholarId != null) {
      try {
        final student = kStudents.firstWhere((s) => s.id == widget.scholarId);
        setState(() {
          _selectedScholar = student;
          _selectedType = student.schoolType == SchoolType.university ? 'University' : 'Secondary';
        });
      } catch (e) {
        debugPrint('Target scholar not found in registry: $e');
      }
    }

    await _fetchSchools();
    _fetchCurrentTabData();
  }

  Future<void> _fetchSchools() async {
    try {
      final res = await ApiService.getAllSchools();
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _allSchools = data.map((s) => Map<String, dynamic>.from(s)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    }
  }

  Future<void> _fetchScholars() async {
    try {
      final res = await ApiService.getAllScholars();
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            kStudents.clear();
            for (var item in data) kStudents.add(Student.fromMap(item));
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching scholars for analysis: $e');
    }
  }

  Future<void> _fetchCurrentTabData() async {
    if (!mounted) return;
    
    // If scope is scholar but none selected, don't fetch aggregated data
    if (_analysisScope == 'Scholar' && _selectedScholar == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String? dist = _analysisScope == 'District' ? _selectedDistrict : null;
      final String? schId = _analysisScope == 'School' ? _selectedSchoolId : null;

      switch (_tabController.index) {
        case 0: // Scholar Trend
          if (_selectedScholar != null) await _fetchIndividualTrend(_selectedScholar!.id);
          else setState(() => _isLoading = false);
          break;
        case 1: // Cohort Analytics
          final res = await ApiService.getCohortAnalytics(_selectedType, district: dist, schoolId: schId);
          if (mounted) setState(() => _cohortData = res.data['data']);
          break;
        case 2: // Subject Intelligence
          final res = await ApiService.getSubjectInsights(_selectedType, district: dist, schoolId: schId);
          if (mounted) setState(() => _subjectData = res.data['data'] ?? []);
          break;
        case 3: // Risk Indicators
          final res = await ApiService.getEarlyWarningRisk(schoolType: _selectedType, district: dist, schoolId: schId);
          if (mounted) setState(() => _riskData = res.data['data'] ?? []);
          break;
        case 4: // CHATs Impact
          final res = await ApiService.getEngagementImpact(_selectedType, district: dist, schoolId: schId);
          if (mounted) setState(() => _engagementData = res.data['data']);
          break;
      }
    } catch (e) {
      debugPrint('Error fetching performance data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchIndividualTrend(String scholarId) async {
    try {
      final res = await ApiService.getScholarTrend(scholarId);
      if (mounted) {
        setState(() {
          _individualData = res.data['data'];
          _aiNarrative = ""; // Clear old narrative
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching scholar trend: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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

      final res = await ApiService.chatWithAI([{'role': 'user', 'content': prompt}], currentPage: 'Performance Analysis');
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

  Widget _buildExecutiveHeader(bool isMobile, bool isVerySmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.showBackButton) ...[
                IconButton(
                  onPressed: widget.onBack ?? () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
              ],
              if (!_isSearchExpanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "INTELLIGENCE ENGINE",
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 1.5),
                      ),
                      Text(
                        _selectedScholar != null && _tabController.index == 0
                            ? _selectedScholar!.name.toUpperCase()
                            : (isVerySmall ? "Analytics" : "Performance Hub"),
                        style: TextStyle(
                          fontSize: isVerySmall ? 14 : 16, 
                          fontWeight: FontWeight.w900, 
                          color: kBrandBrown, 
                          letterSpacing: -0.5
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              if (_analysisScope == 'Scholar' || _tabController.index == 0) _buildScholarPicker(isMobile: isMobile, isVerySmall: isVerySmall),
              if (!_isSearchExpanded) ...[
                const SizedBox(width: 12),
                if (!isVerySmall && !_isFieldOfficer) _buildTypeToggle(),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _fetchCurrentTabData,
                  icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
                  tooltip: "Sync Analysis",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          if (!_isSearchExpanded) _buildScopeAndFilters(isMobile, isVerySmall),
        ],
      ),
    );
  }

  Widget _buildScopeAndFilters(bool isMobile, bool isVerySmall) {
    final bool isSecondary = _selectedType == 'Secondary';
    final List<String> scopes = isSecondary 
        ? ['All', 'District', 'School', 'Scholar'] 
        : ['All', 'School', 'Scholar'];

    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildScopeSelector(scopes, isVerySmall),
            if (_analysisScope == 'District' && isSecondary) ...[
              const SizedBox(width: 12),
              _buildDistrictDropdown(isVerySmall),
            ],
            if (_analysisScope == 'School') ...[
              const SizedBox(width: 12),
              _buildSchoolDropdown(isVerySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSelector(List<String> scopes, bool isVerySmall) {
    return Row(
      children: scopes.map((s) {
        final isSelected = _analysisScope == s;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(s.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : kBrandBrown)),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _analysisScope = s;
                  if (s == 'Scholar') _tabController.animateTo(0);
                  else if (_tabController.index == 0) _tabController.animateTo(1);
                });
                _fetchCurrentTabData();
              }
            },
            selectedColor: kBrandOlive,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? kBrandOlive : Colors.grey.shade200)),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistrictDropdown(bool isVerySmall) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<String>(
        value: _selectedDistrict,
        hint: const Text("Select District", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.grey),
        items: kMalawiDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))).toList(),
        onChanged: _isFieldOfficer ? null : (v) {
          setState(() => _selectedDistrict = v);
          _fetchCurrentTabData();
        },
      ),
    );
  }

  Widget _buildSchoolDropdown(bool isVerySmall) {
    final filteredSchools = _allSchools.where((s) {
      final level = (s['level'] ?? '').toString().toLowerCase();
      if (_selectedType == 'Secondary') {
        return level.contains('secondary') || level.contains('high');
      } else {
        return level.contains('university') || level.contains('tertiary');
      }
    }).toList();

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<String>(
        value: _selectedSchoolId,
        hint: const Text("Select Institution", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.grey),
        items: filteredSchools.map((s) => DropdownMenuItem(
          value: (s['id'] ?? s['_id']).toString(), 
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(s['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))
          )
        )).toList(),
        onChanged: (v) {
          setState(() {
            _selectedSchoolId = v;
            _selectedSchoolName = filteredSchools.firstWhere((s) => (s['id'] ?? s['_id']).toString() == v)['name'];
          });
          _fetchCurrentTabData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 900;
    final bool isVerySmall = width < 500;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildExecutiveHeader(isMobile, isVerySmall),
          _buildMainTabBar(isMobile),
          if (isVerySmall && !_isFieldOfficer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: _buildTypeToggle(fullWidth: true),
            ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIndividualView(isMobile, isVerySmall),
                    _buildCohortView(isMobile, isVerySmall),
                    _buildSubjectView(isMobile, isVerySmall),
                    _buildRiskView(isMobile, isVerySmall),
                    _buildEngagementImpactView(isMobile, isVerySmall),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle({bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Secondary', label: Text("SECONDARY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          ButtonSegment(value: 'University', label: Text("UNIVERSITY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        ],
        selected: {_selectedType},
        onSelectionChanged: (val) {
          setState(() {
            _selectedType = val.first;
            // Reset filters on type change
            if (_selectedType == 'University' && _analysisScope == 'District') {
              _analysisScope = 'All';
            }
            _selectedDistrict = null;
            _selectedSchoolId = null;
            _selectedSchoolName = null;
            _selectedScholar = null;
            _individualData = null;
          });
          _fetchCurrentTabData();
        },
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: kBrandBrown,
          selectedForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildMainTabBar(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white, 
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: kBrandOlive,
        unselectedLabelColor: Colors.grey.shade400,
        indicatorColor: kBrandOlive,
        indicatorWeight: 3,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
        tabs: const [
          Tab(text: "INDIVIDUAL TREND"),
          Tab(text: "COHORT ANALYTICS"),
          Tab(text: "SUBJECT INTELLIGENCE"),
          Tab(text: "RISK INDICATORS"),
          Tab(text: "CHATS IMPACT"),
        ],
      ),
    );
  }

  Widget _buildIndividualView(bool isMobile, bool isVerySmall) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 0 : (isMobile ? 16 : 32),
        vertical: isVerySmall ? 12 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_individualData != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 0),
              child: _buildIndividualInsightsSummary(isMobile, isVerySmall),
            ),
            if (_individualData!['scholarInfo']['academicFlag'] != null)
              Padding(
                padding: EdgeInsets.fromLTRB(isVerySmall ? 16 : 0, 16, isVerySmall ? 16 : 0, 0),
                child: _buildSmartInterventionBanner(isVerySmall),
              ),
            const SizedBox(height: 24),
            if (_selectedType == 'Secondary') ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 0),
                child: _buildMSCEForecastingCard(isMobile, isVerySmall),
              ),
              const SizedBox(height: 24),
            ],
            if (_aiNarrative.isNotEmpty) 
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 0),
                child: _buildAINarrativeBox(isVerySmall),
              ),
            const SizedBox(height: 24),
            if (isMobile)
              Column(
                children: [
                  _buildScoreTrendLine(isMobile, isVerySmall),
                  const SizedBox(height: 24),
                  _buildFlagHistory(isMobile, isVerySmall),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildScoreTrendLine(false, false)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildFlagHistory(false, false)),
                ],
              ),
            const SizedBox(height: 24),
            _buildPeriodBreakdownTable(isMobile, isVerySmall),
            if ((_individualData!['timeline'] as List).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text("No Academic History Found", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text("This scholar does not have any recorded examination results yet.", 
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ] else
            _buildEmptyIndividualState(isVerySmall),
        ],
      ),
    );
  }

  // New Engagement Impact View
  Widget _buildEngagementImpactView(bool isMobile, bool isVerySmall) {
    if (_engagementData == null || _engagementData!.isEmpty) return _buildEmptyCohortState(isVerySmall, message: "NO ENGAGEMENT METRICS FOUND");

    final List<String> groupNames = _engagementData!.keys.toList();
    final List<Color> palette = [const Color(0xFF2E7D32), const Color(0xFFF9A825), const Color(0xFFD32F2F)];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 0 : (isMobile ? 16 : 32),
        vertical: isVerySmall ? 12 : 32,
      ),
      child: Column(
        children: [
          _AnalysisCard(
            isMobile: isMobile,
            isVerySmall: isVerySmall,
            title: "Longitudinal Correlation",
            subtitle: "Academic Achievement vs CHATs Participation Density",
            child: SizedBox(
              height: isVerySmall ? 200 : 320,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))))),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: groupNames.asMap().entries.map((e) {
                    final points = _engagementData![e.value] as List;
                    return LineChartBarData(
                      spots: points.map((p) => FlSpot(double.parse(p['year'].toString()), double.parse(p['score'].toString()))).toList(),
                      isCurved: true,
                      color: palette[e.key % palette.length],
                      barWidth: isVerySmall ? 2.5 : 4,
                      dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3, color: Colors.white, strokeWidth: 2, strokeColor: palette[e.key % palette.length])),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: groupNames.asMap().entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 4, decoration: BoxDecoration(color: palette[e.key % palette.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandBrown)),
                ],
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _AnalysisCard(
            isMobile: isMobile,
            isVerySmall: isVerySmall,
            isTable: true,
            title: "Causality Intelligence",
            subtitle: "Group-level performance metrics",
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: isVerySmall ? 24 : 32,
                columns: const [
                  DataColumn(label: Text("PARTICIPATION TIER")),
                  DataColumn(label: Text("SCHOLAR COUNT")),
                  DataColumn(label: Text("MEAN ACADEMIC SCORE")),
                ],
                rows: groupNames.map((name) {
                  final data = _engagementData![name] as List;
                  final latest = data.last;
                  return DataRow(cells: [
                    DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
                    DataCell(Text("${latest['count']}")),
                    DataCell(Text("${latest['score']}%", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInterventionBanner(bool isVerySmall) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.red.shade700]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("IMMEDIATE INTERVENTION REQUIRED", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text("This scholar is currently flagged for ${_individualData!['scholarInfo']['academicFlag']}. Immediate support is recommended.", 
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarPicker({bool isMobile = false, bool isVerySmall = false}) {
    if (!_isSearchExpanded) {
      return IconButton(
        onPressed: () => setState(() => _isSearchExpanded = true),
        icon: const Icon(Icons.person_search_rounded, color: kBrandBrown, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: kBrandCream,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Expanded(
      child: Autocomplete<Student>(
        displayStringForOption: (s) => "${s.name} (${s.schoolName})",
        optionsBuilder: (val) {
          if (val.text.isEmpty) return const Iterable<Student>.empty();
          return kStudents.where((s) {
            final matchesSearch = s.name.toLowerCase().contains(val.text.toLowerCase());
            final matchesType = s.schoolType.name.toLowerCase() == _selectedType.toLowerCase();
            return matchesSearch && matchesType;
          });
        },
        onSelected: (s) {
          setState(() {
            _selectedScholar = s;
            _isSearchExpanded = false;
            _tabController.animateTo(0); // Switch to Individual Trend tab
          });
          _fetchIndividualTrend(s.id);
        },
        fieldViewBuilder: (ctx, ctrl, focus, onSubmitted) {
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              autofocus: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Scholar search...",
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16), 
                  onPressed: () => setState(() => _isSearchExpanded = false),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAINarrativeBox(bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isVerySmall ? 16 : 24),
      decoration: BoxDecoration(
        color: kBrandOlive.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBrandOlive.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: kBrandOlive, size: 18),
              const SizedBox(width: 12),
              const Text("SMART ANALYST NARRATIVE", 
                style: TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 10, letterSpacing: 1.2)),
              const Spacer(),
              if (_isGeneratingAI)
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: kBrandOlive)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_aiNarrative, 
            style: TextStyle(fontSize: isVerySmall ? 13 : 14, color: kBrandBrown, height: 1.6, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildScoreTrendLine(bool isMobile, bool isVerySmall) {
    final timeline = _individualData!['timeline'] as List;
    if (timeline.isEmpty) return const SizedBox();

    return _AnalysisCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "Score Trajectory",
      subtitle: "Performance mapping over time",
      child: SizedBox(
        height: isVerySmall ? 200 : 280,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true, 
              drawVerticalLine: false, 
              horizontalInterval: 20,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: isVerySmall ? 30 : 40, 
                getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                if (v.toInt() < timeline.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(timeline[v.toInt()]['period'].toString().replaceAll(' ', '\n'), 
                      textAlign: TextAlign.center, style: TextStyle(fontSize: isVerySmall ? 7 : 8, fontWeight: FontWeight.w900, color: kBrandBrown)),
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
                curveSmoothness: 0.35,
                color: kBrandOlive,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, x, bar, index) => FlDotCirclePainter(
                    radius: 4, 
                    color: Colors.white, 
                    strokeWidth: 3, 
                    strokeColor: kBrandOlive
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true, 
                  gradient: LinearGradient(
                    colors: [kBrandOlive.withOpacity(0.2), kBrandOlive.withOpacity(0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: kBrandBrown,
                getTooltipItems: (items) => items.map((i) => LineTooltipItem("${i.y.toStringAsFixed(1)}%", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
              ),
            ),
            minY: 0, maxY: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildFlagHistory(bool isMobile, bool isVerySmall) {
    final history = _individualData!['flagHistory'] as List;
    return _AnalysisCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "Audit Log",
      subtitle: "Automatic promotion outcomes",
      child: Column(
        children: [
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded, color: Colors.grey.shade100, size: 40),
                  const SizedBox(height: 12),
                  const Text("No progression flags recorded.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            )
          else
            ...history.map((h) {
              final isFail = h['result'].toString().contains('Fail');
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFail ? Colors.red.shade50 : kBrandOlive.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(isFail ? Icons.report_problem_rounded : Icons.verified_rounded, 
                      color: isFail ? Colors.red : kBrandOlive, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${h['year']} | ${h['result']}", 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isFail ? Colors.red.shade900 : kBrandBrown)),
                          Text("Avg: ${h['average']}% • ${h['from_class']} → ${h['to_class']}", 
                            style: TextStyle(fontSize: 10, color: kBrandBrown.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPeriodBreakdownTable(bool isMobile, bool isVerySmall) {
    final timeline = _individualData!['timeline'] as List;
    return _AnalysisCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      isTable: true,
      title: "Threshold Mapping",
      subtitle: "Detailed performance audit",
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: isVerySmall ? 24 : 32,
          horizontalMargin: isVerySmall ? 16 : 24,
          headingRowHeight: isVerySmall ? 40 : 48,
          dataRowMaxHeight: isVerySmall ? 56 : 64,
          dividerThickness: 1,
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1),
          dataTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandBrown),
          columns: const [
            DataColumn(label: Text("PERIOD")),
            DataColumn(label: Text("AVERAGE")),
            DataColumn(label: Text("AGGREGATE")),
            DataColumn(label: Text("PRIMARY SUBJECT")),
          ],
          rows: timeline.map((t) {
            final best6 = t['best6'] as List;
            final agg = _calculateAggregatePoints(best6);
            final isGood = agg <= 36;
            return DataRow(cells: [
              DataCell(Text(t['period'], style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text("${t['average']}%")),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isGood ? kBrandOlive : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("${agg.toInt()} pts", 
                  style: TextStyle(color: isGood ? kBrandOlive : Colors.red, fontWeight: FontWeight.w900, fontSize: 11)),
              )),
              DataCell(Text(best6.isNotEmpty ? best6[0]['subject'] : 'N/A', 
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
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
      final grade = gradeFromMarks(marks, isUniversity: _selectedType == 'University');
      total += grade.point;
    }
    if (best6.isEmpty) return 54.0;
    if (best6.length < 6) {
      total += (6 - best6.length) * 9.0;
    }
    return total;
  }

  Widget _buildMSCEForecastingCard(bool isMobile, bool isVerySmall) {
    final timeline = _individualData!['timeline'] as List;
    if (timeline.isEmpty) return const SizedBox();
    
    final latestBest6 = timeline.last['best6'] as List;
    final double currentPoints = _calculateAggregatePoints(latestBest6);
    
    double forecastedPoints = currentPoints;
    if (timeline.length >= 2) {
      final prevBest6 = timeline[timeline.length - 2]['best6'] as List;
      final double prevPoints = _calculateAggregatePoints(prevBest6);
      final double improvement = prevPoints - currentPoints; 
      forecastedPoints = currentPoints - (improvement * 0.5); 
    }
    
    forecastedPoints = forecastedPoints.clamp(6.0, 54.0);
    
    final Color forecastColor = forecastedPoints <= 18 ? Colors.green : (forecastedPoints <= 36 ? Colors.orange : Colors.red);
    final String division = forecastedPoints <= 17 ? "Division 1 (Excellent)" : (forecastedPoints <= 30 ? "Division 2" : "Division 3 / Fail");
    
    final String tip = forecastedPoints > 17 && forecastedPoints <= 25 
        ? "Strategic focus on top 3 subjects could secure a Division 1 outcome."
        : (forecastedPoints > 30 ? "Immediate academic recovery plan needed to avoid secondary failure." : "Maintain current trajectory for stable outcome.");

    return _AnalysisCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "Outcome Projection",
      subtitle: "Aggregate point forecasting (Best Six)",
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _forecastMetric("CURRENT", currentPoints.toInt().toString(), "pts", kBrandBrown, isVerySmall),
              Icon(Icons.trending_up_rounded, color: Colors.grey.shade200, size: isVerySmall ? 24 : 48),
              _forecastMetric("PROJECTED", forecastedPoints.toInt().toString(), "pts", forecastColor, isVerySmall),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: forecastColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: forecastColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: forecastColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.psychology_outlined, color: forecastColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("EXPECTED MSCE OUTCOME", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: forecastColor, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(division.toUpperCase(), style: TextStyle(fontSize: isVerySmall ? 13 : 15, fontWeight: FontWeight.w900, color: forecastColor)),
                      const SizedBox(height: 8),
                      Text(tip, style: TextStyle(fontSize: 10, color: forecastColor.withOpacity(0.8), fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
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

  Widget _forecastMetric(String label, String value, String unit, Color color, bool isVerySmall) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(fontSize: isVerySmall ? 28 : 42, fontWeight: FontWeight.w900, color: color, letterSpacing: -1.5)),
              TextSpan(text: " $unit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color.withOpacity(0.4))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualInsightsSummary(bool isMobile, bool isVerySmall) {
    final info = _individualData?['scholarInfo'];
    if (info == null) return const SizedBox();

    final bool hasRisk = info['academicFlag'] != null;

    final String interventionLevel = hasRisk ? "HIGH PRIORITY" : (info['yearsRemaining'] <= 1 ? "GRADUATION FOCUS" : "STANDARD TRACK");
    final Color interventionColor = hasRisk ? Colors.red : (info['yearsRemaining'] <= 1 ? Colors.blue : kBrandOlive);

    IconData trendIcon = Icons.trending_flat_rounded;
    Color trendColor = Colors.grey;
    String trendLabel = "Stable";
    String topStrengths = "Pending Analysis";
    
    final timeline = _individualData!['timeline'] as List;
    if (timeline.isNotEmpty) {
      if (timeline.length >= 2) {
        final latest = double.tryParse(timeline.last['average'].toString()) ?? 0.0;
        final prev = double.tryParse(timeline[timeline.length - 2]['average'].toString()) ?? 0.0;
        if (latest > prev + 1) {
          trendIcon = Icons.trending_up_rounded;
          trendColor = kBrandOlive;
          trendLabel = "Improving";
        } else if (latest < prev - 1) {
          trendIcon = Icons.trending_down_rounded;
          trendColor = Colors.red;
          trendLabel = "Declining";
        }
      }
      final best6 = timeline.last['best6'] as List;
      if (best6.isNotEmpty) {
        topStrengths = best6.take(2).map((s) => s['subject']).join(', ');
      }
    }

    if (isVerySmall) {
      return Column(
        children: [
          Row(
            children: [
              _MetricIndicator(label: "PROGRESSION", value: "Year ${info['currentRelativeYear']}", icon: Icons.auto_graph_rounded, isVerySmall: true),
              const SizedBox(width: 8),
              _MetricIndicator(label: "REMAINING", value: "${info['yearsRemaining']} Yrs", icon: Icons.hourglass_empty_rounded, isVerySmall: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricIndicator(label: "TREND", value: trendLabel, icon: trendIcon, color: trendColor, isVerySmall: true),
              const SizedBox(width: 8),
              _MetricIndicator(label: "STRENGTHS", value: topStrengths, icon: Icons.star_border_purple500_rounded, color: Colors.amber.shade700, isVerySmall: true),
            ],
          ),
          const SizedBox(height: 8),
          _MetricIndicator(
            label: "INTERVENTION", 
            value: interventionLevel, 
            icon: Icons.psychology_alt_rounded, 
            color: interventionColor,
            isVerySmall: true,
          ),
          const SizedBox(height: 16),
          _buildAIButton(true),
        ],
      );
    }

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _MetricIndicator(label: "PROGRAM YEAR", value: "Year ${info['currentRelativeYear']} of ${info['programDurationYears']}", icon: Icons.timeline),
              const SizedBox(width: 12),
              _MetricIndicator(label: "TIME REMAINING", value: "${info['yearsRemaining']} Years", icon: Icons.hourglass_empty_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricIndicator(label: "PERFORMANCE TREND", value: trendLabel, icon: trendIcon, color: trendColor),
              const SizedBox(width: 12),
              _MetricIndicator(label: "CORE STRENGTHS", value: topStrengths, icon: Icons.star_border_purple500_rounded, color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 12),
          _MetricIndicator(label: "INTERVENTION PRIORITY", value: interventionLevel, icon: Icons.psychology_alt_rounded, color: interventionColor),
          const SizedBox(height: 16),
          _buildAIButton(true),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _MetricIndicator(label: "PROGRAM YEAR", value: "Year ${info['currentRelativeYear']} of ${info['programDurationYears']}", icon: Icons.timeline),
            const SizedBox(width: 20),
            _MetricIndicator(label: "TIME REMAINING", value: "${info['yearsRemaining']} Years", icon: Icons.hourglass_empty_rounded),
            const SizedBox(width: 20),
            _MetricIndicator(label: "PERFORMANCE TREND", value: trendLabel, icon: trendIcon, color: trendColor),
            const SizedBox(width: 20),
            _MetricIndicator(label: "CORE STRENGTHS", value: topStrengths, icon: Icons.star_border_purple500_rounded, color: Colors.amber.shade700),
            const SizedBox(width: 20),
            _MetricIndicator(label: "INTERVENTION PRIORITY", value: interventionLevel, icon: Icons.psychology_alt_rounded, color: interventionColor),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildAIButton(false)),
          ],
        ),
      ],
    );
  }

  Widget _buildAIButton(bool isFullWidth) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingAI ? null : _generateAINarrative,
        icon: _isGeneratingAI 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_awesome_rounded, size: 20),
        label: const Text("GENERATE INTELLIGENCE REPORT", style: TextStyle(letterSpacing: 0.5, fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // --- VIEW 2: COHORT ---
  Widget _buildCohortView(bool isMobile, bool isVerySmall) {
    if (_cohortData == null) return _buildEmptyCohortState(isVerySmall, message: "NO COHORT DATA DISCOVERED");
    final groups = _cohortData['classGroups'] as Map? ?? {};
    final summary = _cohortData['summary'] ?? {};

    String groupTitle = "All $_selectedType Schools";
    if (_analysisScope == 'District') groupTitle = "${_selectedDistrict ?? 'Selected'} District";
    if (_analysisScope == 'School') groupTitle = _selectedSchoolName ?? 'Selected Institution';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 0 : (isMobile ? 16 : 32),
        vertical: isVerySmall ? 12 : 32,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 0),
            child: Row(
              children: [
                _MetricIndicator(label: "ON-TRACK", value: "${summary['onTrack']}", icon: Icons.verified_user_rounded, color: kBrandOlive, isVerySmall: isVerySmall),
                SizedBox(width: isVerySmall ? 8 : 16),
                _MetricIndicator(label: "AT RISK", value: "${summary['atRisk']}", icon: Icons.warning_amber_rounded, color: Colors.orange, isVerySmall: isVerySmall),
                if (!isVerySmall) ...[
                  const SizedBox(width: 16),
                  _MetricIndicator(label: "TOTAL COHORT", value: "${summary['totalScholars']}", icon: Icons.groups_rounded),
                ]
              ],
            ),
          ),
          if (isVerySmall) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MetricIndicator(label: "TOTAL COHORT", value: "${summary['totalScholars']}", icon: Icons.groups_rounded, isVerySmall: true),
            ),
          ],
          const SizedBox(height: 24),
          _AnalysisCard(
            isMobile: isMobile,
            isVerySmall: isVerySmall,
            isTable: true,
            title: "Performance Distribution",
            subtitle: groupTitle,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: isVerySmall ? 24 : 32,
                      horizontalMargin: isVerySmall ? 16 : 24,
                      headingRowHeight: isVerySmall ? 40 : 48,
                      dataRowMaxHeight: isVerySmall ? 56 : 64,
                      dividerThickness: 1,
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1),
                      dataTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandBrown),
                      columns: const [
                        DataColumn(label: Text("COHORT")),
                        DataColumn(label: Text("TOTAL")),
                        DataColumn(label: Text("SUPP.")),
                        DataColumn(label: Text("REPEAT")),
                        DataColumn(label: Text("SUCCESS RATE")),
                      ],
                      rows: groups.entries.map((e) {
                        final val = e.value;
                        final double total = (val['total'] ?? 0).toDouble();
                        final double fail = ((val['repeat'] ?? 0) + (val['supplementary'] ?? 0)).toDouble();
                        final double success = total > 0 ? (total - fail) / total * 100 : 0.0;
                        return DataRow(cells: [
                          DataCell(Text(_formatCohortLabel(e.key), style: const TextStyle(fontWeight: FontWeight.w900))),
                          DataCell(Text("${val['total']}")),
                          DataCell(Text("${val['supplementary']}", style: TextStyle(color: val['supplementary'] > 0 ? Colors.orange : null))),
                          DataCell(Text("${val['repeat']}", style: TextStyle(color: val['repeat'] > 0 ? Colors.red : null))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (success >= 80 ? kBrandOlive : (success >= 60 ? Colors.orange : Colors.red)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text("${success.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.w900, color: success >= 80 ? kBrandOlive : (success >= 60 ? Colors.orange : Colors.red))),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 3: SUBJECT ---
  Widget _buildSubjectView(bool isMobile, bool isVerySmall) {
    if (_subjectData.isEmpty) return _buildEmptyCohortState(isVerySmall, message: "NO SUBJECT ANALYTICS RECORDED");
    
    String groupTitle = "Subject Insights: All $_selectedType Schools";
    if (_analysisScope == 'District') groupTitle = "Subject Insights: ${_selectedDistrict ?? 'Selected'} District";
    if (_analysisScope == 'School') groupTitle = "Subject Insights: ${_selectedSchoolName ?? 'Selected Institution'}";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 0 : (isMobile ? 16 : 32),
        vertical: isVerySmall ? 12 : 32,
      ),
      child: Column(
        children: [
          _AnalysisCard(
            isMobile: isMobile,
            isVerySmall: isVerySmall,
            isTable: true,
            title: "Subject Intelligence",
            subtitle: groupTitle,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: isVerySmall ? 24 : 32,
                      horizontalMargin: isVerySmall ? 16 : 24,
                      headingRowHeight: isVerySmall ? 40 : 48,
                      dataRowMaxHeight: isVerySmall ? 56 : 64,
                      dividerThickness: 1,
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1),
                      dataTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandBrown),
                      columns: const [
                        DataColumn(label: Text("SUBJECT")),
                        DataColumn(label: Text("MEAN SCORE")),
                        DataColumn(label: Text("FAILURE RATE")),
                        DataColumn(label: Text("COHORT SIZE")),
                      ],
                      rows: _subjectData.map((s) {
                        final double avg = s['avgMark']?.toDouble() ?? 0.0;
                        final double fails = (s['failCount'] ?? 0).toDouble();
                        final double total = (s['totalCount'] ?? 1).toDouble();
                        final double failRate = (fails / total) * 100;
                        return DataRow(cells: [
                          DataCell(Text(s['_id'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w900))),
                          DataCell(Text("${avg.toStringAsFixed(1)}%")),
                          DataCell(Text("${failRate.toStringAsFixed(1)}%", style: TextStyle(color: failRate > 20 ? Colors.red : kBrandBrown))),
                          DataCell(Text("${s['totalCount']}")),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 4: RISK ---
  Widget _buildRiskView(bool isMobile, bool isVerySmall) {
    if (_riskData.isEmpty) return _buildEmptyCohortState(isVerySmall, message: "NO AT-RISK SCHOLARS DETECTED");

    String groupTitle = "High Alert Matrix: All $_selectedType Schools";
    if (_analysisScope == 'District') groupTitle = "High Alert Matrix: ${_selectedDistrict ?? 'Selected'} District";
    if (_analysisScope == 'School') groupTitle = "High Alert Matrix: ${_selectedSchoolName ?? 'Selected Institution'}";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 0 : (isMobile ? 16 : 32),
        vertical: isVerySmall ? 12 : 32,
      ),
      child: Column(
        children: [
          _AnalysisCard(
            isMobile: isMobile,
            isVerySmall: isVerySmall,
            isTable: true,
            title: "Early Warning Matrix",
            subtitle: groupTitle,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: isVerySmall ? 24 : 32,
                      horizontalMargin: isVerySmall ? 16 : 24,
                      headingRowHeight: isVerySmall ? 40 : 48,
                      dataRowMaxHeight: isVerySmall ? 56 : 64,
                      dividerThickness: 1,
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1),
                      dataTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandBrown),
                      columns: const [
                        DataColumn(label: Text("SCHOLAR")),
                        DataColumn(label: Text("AVERAGE")),
                        DataColumn(label: Text("THRESHOLD GAP")),
                        DataColumn(label: Text("STATUS")),
                      ],
                      rows: _riskData.map((r) {
                        final double dist = r['distance']?.toDouble() ?? 0.0;
                        final isNegative = dist < 0;
                        return DataRow(cells: [
                          DataCell(Text(r['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w900))),
                          DataCell(Text("${r['average']?.toStringAsFixed(1)}%")),
                          DataCell(Text("${!isNegative ? '+' : ''}${dist.toStringAsFixed(1)}%", 
                            style: TextStyle(color: isNegative ? Colors.red : Colors.orange, fontWeight: FontWeight.w900))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isNegative ? Colors.red : Colors.orange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(isNegative ? "CRITICAL" : "MONITOR", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isNegative ? Colors.red : Colors.orange)),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIndividualState(bool isVerySmall) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
              child: Icon(Icons.psychology_rounded, size: isVerySmall ? 48 : 64, color: Colors.grey.shade200),
            ),
            const SizedBox(height: 24),
            const Text("Engine Ready for Selection", 
              style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text("Please select a scholar from the search bar to\ninitialize performance mapping and trajectory analysis.", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCohortState(bool isVerySmall, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: isVerySmall ? 48 : 64, color: Colors.grey.shade200),
            const SizedBox(height: 24),
            Text(message ?? "Analyzing System Data...", 
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  String _formatCohortLabel(String key) {
    // If it's a year like "2023", make it "2023 Intake"
    if (RegExp(r'^\d{4}$').hasMatch(key)) {
      return "$key Intake";
    }
    // If it's a class like "Form 1", clarify it as a group
    return key;
  }
}

class _MetricIndicator extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  final bool isVerySmall;
  const _MetricIndicator({required this.label, required this.value, required this.icon, this.color, this.isVerySmall = false});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? kBrandBrown;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isVerySmall ? 12 : 20),
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
              padding: EdgeInsets.all(isVerySmall ? 8 : 12),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: effectiveColor, size: isVerySmall ? 18 : 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label.toUpperCase(), 
                    style: TextStyle(
                      fontSize: isVerySmall ? 7 : 9, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.grey.shade400, 
                      letterSpacing: 1.2
                    ), 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(value, 
                    style: TextStyle(
                      fontSize: isVerySmall ? 14 : 18, 
                      fontWeight: FontWeight.w900, 
                      color: kBrandBrown, 
                      letterSpacing: -0.5
                    ),
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
  final bool isMobile, isVerySmall;
  final bool isTable;
  const _AnalysisCard({
    required this.title, 
    required this.subtitle, 
    required this.child, 
    this.isMobile = false, 
    this.isVerySmall = false,
    this.isTable = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool useFullWidth = isVerySmall && isTable;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: isVerySmall ? 8 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: useFullWidth ? 0 : (isVerySmall ? 16 : (isMobile ? 24 : 32)),
        vertical: isVerySmall ? 20 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: useFullWidth ? BorderRadius.zero : BorderRadius.circular(24),
        border: useFullWidth ? null : Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: useFullWidth ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: useFullWidth ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(), 
                  style: TextStyle(
                    fontSize: isVerySmall ? 9 : 10, 
                    fontWeight: FontWeight.w900, 
                    color: kBrandOlive, 
                    letterSpacing: 1.5
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle, 
                  style: TextStyle(
                    fontSize: isVerySmall ? 14 : 16, 
                    fontWeight: FontWeight.w900, 
                    color: kBrandBrown, 
                    letterSpacing: -0.5
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isVerySmall ? 20 : 24),
          child,
        ],
      ),
    );
  }
}
