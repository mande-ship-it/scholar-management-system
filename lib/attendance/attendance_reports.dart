import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

class AttendanceReportsComponent extends StatefulWidget {
  const AttendanceReportsComponent({super.key});

  @override
  State<AttendanceReportsComponent> createState() => _AttendanceReportsComponentState();
}

class _AttendanceReportsComponentState extends State<AttendanceReportsComponent> {
  Map<String, dynamic>? _selectedSchool;
  String _selectedPeriodType = 'Month'; // Month, Term, Semester, Week
  int? _selectedMonth = DateTime.now().month;
  int? _selectedWeek;
  String? _selectedTerm;
  String? _selectedSemester;

  bool _isLoading = false;
  bool _isLoadingSchools = true;
  List<Map<String, dynamic>> _schools = [];
  List<dynamic> _reportData = [];

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        setState(() {
          _schools = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSchools = false);
    }
  }

  Future<void> _fetchReport() async {
    if (_selectedSchool == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSchoolAttendanceReport(
        _selectedSchool!['id'].toString(),
        month: _selectedPeriodType == 'Month' || _selectedPeriodType == 'Week' ? _selectedMonth : null,
        weekNumber: _selectedPeriodType == 'Week' ? _selectedWeek : null,
        term: _selectedPeriodType == 'Term' ? _selectedTerm : null,
        semester: _selectedPeriodType == 'Semester' ? _selectedSemester : null,
      );

      if (response.statusCode == 200) {
        setState(() {
          _reportData = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance report: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Professional Header
          Container(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBrandOlive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: kBrandOlive, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('School Attendance Reports',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Analyze program participation against targets for specific institutions and periods.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildControls(),
                  const SizedBox(height: 32),
                  
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(80), child: CircularProgressIndicator(color: kBrandOlive)))
                  else if (_selectedSchool == null)
                    _buildSelectionPlaceholder()
                  else ...[
                    _buildReportSummary(),
                    const SizedBox(height: 32),
                    _reportSection(
                      title: "Scholar Participation Registry",
                      subtitle: "Detailed tracking for ${_selectedSchool!['name']} during the selected ${_selectedPeriodType.toLowerCase()}",
                      child: _buildAttendanceTable(_reportData),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(80),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text("Select a school and reporting period to generate attendance report.",
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildReportSummary() {
    if (_reportData.isEmpty) return const SizedBox();

    double avgRate = _reportData.fold(0.0, (sum, item) => sum + (item['attendanceRate'] ?? 0)) / _reportData.length;
    int atRisk = _reportData.where((item) => (item['attendanceRate'] ?? 0) < 50).length;
    int onTrack = _reportData.where((item) => item['status'] == 'On Track').length;

    return Row(
      children: [
        _metricCard("Aggregate Rate", "${avgRate.toStringAsFixed(1)}%", kBrandOlive, Icons.rule_rounded, "Global Performance"),
        const SizedBox(width: 24),
        _metricCard("On Track Scholars", "$onTrack", kBrandBrown, Icons.verified_rounded, "Meeting Targets"),
        const SizedBox(width: 24),
        _metricCard("At-Risk Indicators", "$atRisk", Colors.red, Icons.warning_amber_rounded, "Critical Lows"),
      ],
    );
  }

  Widget _buildControls() {
    final schoolOptions = _schools.map((s) => DropdownMenuItem(
      value: s,
      child: Text(s['name'] ?? ''),
    )).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 300,
            child: _dropdownControl("PARTNER INSTITUTION", _selectedSchool, schoolOptions, (v) {
              setState(() {
                _selectedSchool = v;
                _reportData = [];
              });
              _fetchReport();
            }, hint: "Select school..."),
          ),
          SizedBox(
            width: 180,
            child: _dropdownControl("REPORTING DIMENSION", _selectedPeriodType, [
              'Month', 'Term', 'Semester', 'Week'
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), (v) {
              setState(() {
                _selectedPeriodType = v!;
                _reportData = [];
              });
              _fetchReport();
            }),
          ),
          _buildPeriodSpecificSelector(),
          ElevatedButton.icon(
            onPressed: _fetchReport,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Generate"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSpecificSelector() {
    if (_selectedPeriodType == 'Month') {
      return SizedBox(
        width: 150,
        child: _dropdownControl("MONTH", _selectedMonth, List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
          value: m, child: Text("Month $m")
        )).toList(), (v) {
          setState(() => _selectedMonth = v);
          _fetchReport();
        }),
      );
    } else if (_selectedPeriodType == 'Week') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            child: _dropdownControl("MONTH", _selectedMonth, List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
              value: m, child: Text("Month $m")
            )).toList(), (v) {
              setState(() => _selectedMonth = v);
              _fetchReport();
            }),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: _dropdownControl("WEEK", _selectedWeek, List.generate(5, (i) => i + 1).map((w) => DropdownMenuItem(
              value: w, child: Text("Week $w")
            )).toList(), (v) {
              setState(() => _selectedWeek = v);
              _fetchReport();
            }, hint: "All"),
          ),
        ],
      );
    } else if (_selectedPeriodType == 'Term') {
      return SizedBox(
        width: 150,
        child: _dropdownControl("TERM", _selectedTerm, ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(
          value: t, child: Text(t)
        )).toList(), (v) {
          setState(() => _selectedTerm = v);
          _fetchReport();
        }, hint: "Select..."),
      );
    } else if (_selectedPeriodType == 'Semester') {
      return SizedBox(
        width: 150,
        child: _dropdownControl("SEMESTER", _selectedSemester, ['Semester 1', 'Semester 2'].map((s) => DropdownMenuItem(
          value: s, child: Text(s)
        )).toList(), (v) {
          setState(() => _selectedSemester = v);
          _fetchReport();
        }, hint: "Select..."),
      );
    }
    return const SizedBox();
  }

  Widget _dropdownControl(String label, dynamic value, List<DropdownMenuItem<dynamic>> items, ValueChanged<dynamic> onChanged, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButton<dynamic>(
            value: value,
            isDense: false,
            isExpanded: true,
            hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 14)) : null,
            underline: const SizedBox(),
            style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 14),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {}, // Implement export logic
          icon: const Icon(Icons.grid_on_rounded, size: 18),
          label: const Text("Export CSV"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: kBrandBrown,
            side: const BorderSide(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {}, // Implement PDF logic
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
          label: const Text("Export PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _reportSection({required String title, required String subtitle, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(List scholars) {
    if (scholars.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No individual records found for this period.")));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        headingRowHeight: 56,
        horizontalMargin: 24,
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text("SCHOLAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 0.5))),
          DataColumn(label: Text("AGE ID", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 0.5))),
          DataColumn(label: Text("SESSIONS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 0.5))),
          DataColumn(label: Text("TARGET", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 0.5))),
          DataColumn(label: Text("RATE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 0.5))),
          DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 0.5))),
        ],
        rows: scholars.map((s) {
          final String status = s['status'] ?? 'N/A';
          Color statusColor = Colors.grey;
          if (status == 'On Track') statusColor = kBrandOlive;
          else if (status == 'Behind') statusColor = Colors.orange;
          else if (status == 'At Risk') statusColor = Colors.red;

          return DataRow(
            cells: [
              DataCell(Text(s['scholar_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBrandBrown))),
              DataCell(Text(s['age_id'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
              DataCell(Text("${s['present_count'] ?? 0}/${s['total_sessions'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(s['target']?.toString() ?? '0')),
              DataCell(Text("${s['attendanceRate'] ?? 0}%", style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 14))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
