import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:intl/intl.dart';

enum AnalysisMode { scholar, school }

class PerformanceAnalysisComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  const PerformanceAnalysisComponent({super.key, this.forcedSchoolType});

  @override
  State<PerformanceAnalysisComponent> createState() => _PerformanceAnalysisComponentState();
}

class _PerformanceAnalysisComponentState extends State<PerformanceAnalysisComponent> {
  AnalysisMode _mode = AnalysisMode.scholar;
  String? _selectedId; // Could be studentId or schoolName
  bool _isLoading = false;
  String? _assignedDistrict;
  bool _isFieldOfficer = false;
  
  List<ResultRecord> _analysisData = [];
  List<Student> _relevantStudents = [];

  // Filters
  String _startYear = (DateTime.now().year - 3).toString();
  String _endYear = DateTime.now().year.toString();
  late SchoolType _schoolType;

  @override
  void initState() {
    super.initState();
    _schoolType = widget.forcedSchoolType ?? SchoolType.secondary;
    _fetchUserRole();
    _fetchBaseData();
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            final role = (data['role_name'] ?? '').toString().toLowerCase();
            _isFieldOfficer = role.contains('field');
            _assignedDistrict = data['assignedDistrict'];
            if (_isFieldOfficer) {
              _schoolType = SchoolType.secondary;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchBaseData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getAllScholars();
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data['data'] ?? [];
        kStudents.clear();
        for (var item in data) {
          kStudents.add(Student(
            id: (item['id'] ?? item['_id'] ?? '').toString(),
            scholarId: item['scholar_id'] ?? 'N/A',
            name: item['full_name'] ?? 'N/A',
            status: item['status'] ?? 'Active',
            district: item['district'] ?? 'N/A', // Crucial for filtering
            age: item['age'] != null ? int.tryParse(item['age'].toString()) ?? 16 : 16,
            schoolType: item['school_type'] == 'University' || item['schoolType'] == 'University' ? SchoolType.university : SchoolType.secondary,
            schoolName: item['display_school_name'] ?? 'N/A',
            currentClass: item['academic_year'] ?? 'N/A',
          ));
        }
      }
    } catch (e) {
      debugPrint('Error fetching scholars: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAnalysisData() async {
    if (_selectedId == null) return;
    setState(() => _isLoading = true);
    try {
      if (_mode == AnalysisMode.scholar) {
        final res = await ApiService.getResultsByScholar(_selectedId!);
        if (res.statusCode == 200) {
          final List<dynamic> data = res.data['data'] ?? [];
          _analysisData = data.map((json) => ResultRecord.fromMap(json)).toList();
        }
      } else {
        final res = await ApiService.getResultsBySchool(_selectedId!);
        if (res.statusCode == 200) {
          final List<dynamic> data = res.data['data'] ?? [];
          final allResults = data.map((json) => ResultRecord.fromMap(json)).toList();
          
          // Filter analysis to only include active scholars in the assigned district
          var studentsPool = kStudents.where((s) => s.status == 'Active').toList();
          if (_isFieldOfficer && _assignedDistrict != null && _assignedDistrict != "All Regions") {
            studentsPool = studentsPool.where((s) => s.district == _assignedDistrict).toList();
          }
          
          final activeScholarIds = studentsPool.map((s) => s.id).toSet();
          _analysisData = allResults.where((r) => activeScholarIds.contains(r.studentId)).toList();
        }
        
        var relevantPool = kStudents.where((s) => s.schoolName == _selectedId && s.status == 'Active').toList();
        if (_isFieldOfficer && _assignedDistrict != null && _assignedDistrict != "All Regions") {
          relevantPool = relevantPool.where((s) => s.district == _assignedDistrict).toList();
        }
        _relevantStudents = relevantPool;
      }
    } catch (e) {
      debugPrint('Error fetching analysis data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onModeChanged(Set<AnalysisMode> selection) {
    setState(() {
      _mode = selection.first;
      _selectedId = null;
      _analysisData = [];
    });
  }

  List<String> get _schoolOptions {
    var students = widget.forcedSchoolType == null
        ? kStudents
        : kStudents.where((s) => s.schoolType == widget.forcedSchoolType).toList();
    
    if (_isFieldOfficer && _assignedDistrict != null && _assignedDistrict != "All Regions") {
      students = students.where((s) => s.district == _assignedDistrict).toList();
    }

    return students.map((s) => s.schoolName).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading && kStudents.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            decoration: BoxDecoration(
              color: kBrandBrown.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isFieldOfficer && _assignedDistrict != null ? "Regional Performance Intelligence • $_assignedDistrict" : "Performance Analysis Hub", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.8)),
                Text(_isFieldOfficer ? "Analyzing secondary scholars in $_assignedDistrict district." : "Comparative academic intelligence and trend forecasting.", 
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildYearRangeSelector(),
        ],
      ),
    );
  }

  Widget _buildYearRangeSelector() {
    final years = academicYearOptions();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _startYear,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _startYear = v);
                _fetchAnalysisData();
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("to", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          DropdownButton<String>(
            value: _endYear,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _endYear = v);
                _fetchAnalysisData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopControls(),
          const SizedBox(height: 32),
          if (_selectedId == null)
            _buildEmptyState()
          else if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: kBrandOlive)))
          else
            _buildAnalysisDashboard(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      children: [
        SegmentedButton<AnalysisMode>(
          segments: const [
            ButtonSegment(value: AnalysisMode.scholar, label: Text('Scholar'), icon: Icon(Icons.person_outline_rounded)),
            ButtonSegment(value: AnalysisMode.school, label: Text('Institution'), icon: Icon(Icons.business_rounded)),
          ],
          selected: {_mode},
          onSelectionChanged: _onModeChanged,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: kBrandOlive,
            selectedForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _mode == AnalysisMode.scholar
              ? _buildScholarSearch()
              : _buildSchoolSearch(),
        ),
      ],
    );
  }

  Widget _buildScholarSearch() {
    return Autocomplete<Student>(
      displayStringForOption: (s) => s.name,
      optionsBuilder: (textValue) {
        final query = textValue.text.trim().toLowerCase();
        var activeStudents = kStudents.where((s) => s.status == 'Active').toList();
        
        if (_isFieldOfficer && _assignedDistrict != null && _assignedDistrict != "All Regions") {
          activeStudents = activeStudents.where((s) => s.district == _assignedDistrict).toList();
        }

        if (query.isEmpty) return activeStudents;
        return activeStudents.where((s) => s.name.toLowerCase().contains(query) || s.scholarId.toLowerCase().contains(query));
      },
      onSelected: (s) {
        setState(() => _selectedId = s.id);
        _fetchAnalysisData();
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _inputDeco('Enter scholar name or ID...', Icons.person_search_rounded).copyWith(
            suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () {
              controller.clear();
              setState(() => _selectedId = null);
            }),
          ),
        );
      },
    );
  }

  Widget _buildSchoolSearch() {
    return Autocomplete<String>(
      optionsBuilder: (textValue) {
        final query = textValue.text.trim().toLowerCase();
        if (query.isEmpty) return _schoolOptions;
        return _schoolOptions.where((n) => n.toLowerCase().contains(query));
      },
      onSelected: (n) {
        setState(() => _selectedId = n);
        _fetchAnalysisData();
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _inputDeco('Enter institution name...', Icons.search_rounded).copyWith(
            suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () {
              controller.clear();
              setState(() => _selectedId = null);
            }),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisDashboard() {
    final startY = int.tryParse(_startYear) ?? 0;
    final endY = int.tryParse(_endYear) ?? 9999;

    final filteredData = _analysisData.where((r) {
      final y = int.tryParse(r.year) ?? 0;
      return y >= startY && y <= endY;
    }).toList();

    if (filteredData.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(60), child: Text("No data found for the selected period.", style: TextStyle(color: Colors.grey))));
    }

    final avgScore = filteredData.map((e) => e.marks).reduce((a, b) => a + b) / filteredData.length;
    
    // Performance comparison logic: Best 6 for Secondary
    double displayAvg = avgScore;
    if (_schoolType == SchoolType.secondary) {
      displayAvg = calculateSecondaryBestSixAverage(filteredData);
    }

    final passRate = (filteredData.where((r) => r.marks >= 50).length / filteredData.length) * 100;
    
    // Grouping for trend - using best 6 logic per year for secondary
    final Map<String, List<double>> yearlyAvg = {};
    for (var r in filteredData) {
      yearlyAvg.putIfAbsent(r.year, () => []).add(r.marks);
    }
    
    final sortedYears = yearlyAvg.keys.toList()..sort();
    final trendPoints = sortedYears.map((y) {
      final marks = yearlyAvg[y]!;
      double yearAvg;
      if (_schoolType == SchoolType.secondary) {
        final yearResults = filteredData.where((r) => r.year == y).toList();
        yearAvg = calculateSecondaryBestSixAverage(yearResults);
      } else {
        yearAvg = marks.reduce((a, b) => a + b) / marks.length;
      }
      return (year: y, avg: yearAvg);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MetricCard(label: _schoolType == SchoolType.secondary ? "Best-6 Average" : "Aggregated Average", value: "${displayAvg.toStringAsFixed(1)}%", icon: Icons.auto_graph_rounded, color: kBrandBrown),
            const SizedBox(width: 20),
            _MetricCard(label: "Success Rate", value: "${passRate.toStringAsFixed(1)}%", icon: Icons.verified_user_rounded, color: kBrandOlive),
            const SizedBox(width: 20),
            _MetricCard(label: "Observation Count", value: "${filteredData.length}", icon: Icons.analytics_outlined, color: kBrandOrange),
          ],
        ),
        const SizedBox(height: 32),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _ComparisonChart(title: "Performance Trajectory", points: trendPoints),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 2,
              child: _SubjectBreakdown(data: filteredData),
            ),
          ],
        ),

        const SizedBox(height: 32),
        _DetailedAnalysisTable(data: filteredData, mode: _mode),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.query_stats_rounded, size: 80, color: Colors.grey.shade100),
          const SizedBox(height: 20),
          Text("Awaiting Parameters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey.shade300)),
          const SizedBox(height: 8),
          Text("Select a scholar or institution to begin comparative performance mapping.", 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.5)),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Icon(icon, size: 18, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({required this.title, required this.points});
  final String title;
  final List<({String year, double avg})> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kBrandBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text("Average score trend across academic sessions", 
            style: TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 48),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= 0 && val.toInt() < points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(points[val.toInt()].year, 
                              style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text("${val.toInt()}%", 
                        style: const TextStyle(color: Colors.white30, fontSize: 9)),
                      reservedSize: 32,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.avg)).toList(),
                    isCurved: true,
                    color: kBrandOlive,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: kBrandOlive.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBreakdown extends StatelessWidget {
  const _SubjectBreakdown({required this.data});
  final List<ResultRecord> data;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<double>> subjectGroups = {};
    for (var r in data) {
      subjectGroups.putIfAbsent(r.subject, () => []).add(r.marks);
    }
    
    final sortedSubjects = subjectGroups.entries.map((e) => (
      name: e.key,
      avg: e.value.reduce((a, b) => a + b) / e.value.length
    )).toList()..sort((a, b) => b.avg.compareTo(a.avg));

    return Container(
      height: 380,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SUBJECT INTELLIGENCE", 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: kBrandBrown, letterSpacing: 1)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: sortedSubjects.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final s = sortedSubjects[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        Text("${s.avg.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBrandOlive)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.avg / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade100,
                        color: s.avg >= 70 ? kBrandOlive : (s.avg >= 50 ? Colors.blue : kBrandOrange),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedAnalysisTable extends StatelessWidget {
  const _DetailedAnalysisTable({required this.data, required this.mode});
  final List<ResultRecord> data;
  final AnalysisMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.grey.shade50,
            child: const Text("GRANULAR SCORE AUDIT", 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
          ),
          DataTable(
            headingRowHeight: 48,
            horizontalMargin: 24,
            columnSpacing: 24,
            columns: [
              if (mode == AnalysisMode.school)
                const DataColumn(label: Text("SCHOLAR ID")),
              const DataColumn(label: Text("SUBJECT / COURSE")),
              const DataColumn(label: Text("YEAR")),
              const DataColumn(label: Text("PERIOD")),
              const DataColumn(label: Text("SCORE")),
              const DataColumn(label: Text("STANDING")),
            ],
            rows: data.reversed.take(10).map((r) {
              final band = performanceBand(r.marks);
              return DataRow(
                cells: [
                  if (mode == AnalysisMode.school)
                    DataCell(Text(r.studentId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(Text(r.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  DataCell(Text(r.year, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(r.term ?? r.semester ?? '-', style: const TextStyle(fontSize: 12))),
                  DataCell(Text("${r.marks.toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: band.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(band.label.toUpperCase(), style: TextStyle(color: band.color, fontSize: 9, fontWeight: FontWeight.bold)),
                  )),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

double calculateSecondaryBestSixAverage(List<ResultRecord> records) {
  if (records.isEmpty) return 0.0;

  // Group records by student, year, and term
  final Map<String, List<ResultRecord>> groups = {};
  for (var r in records) {
    final key = "${r.studentId}_${r.year}_${r.term ?? ''}";
    groups.putIfAbsent(key, () => []).add(r);
  }

  double totalAveragesSum = 0.0;
  int groupCount = 0;

  for (var groupRecords in groups.values) {
    if (groupRecords.isEmpty) continue;
    // Calculate best 6 for this group
    final sorted = List<ResultRecord>.from(groupRecords)
      ..sort((a, b) => (a.points ?? 9).compareTo(b.points ?? 9));
    final bestSix = sorted.take(6).toList();
    
    double groupSum = bestSix.fold(0.0, (sum, r) => sum + r.marks);
    double groupAvg = groupSum / (bestSix.length < 6 ? bestSix.length : 6);
    totalAveragesSum += groupAvg;
    groupCount++;
  }

  return groupCount > 0 ? totalAveragesSum / groupCount : 0.0;
}
