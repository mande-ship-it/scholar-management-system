import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    if (!mounted) return;
    setState(() => _isLoadingSchools = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _schools = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
            _isLoadingSchools = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
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
        if (mounted) {
          setState(() {
            _reportData = (response.data['data'] ?? [])
                .where((item) => (item['scholar_status'] ?? item['status'] ?? 'Active') == 'Active')
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfessionalHeader(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? Colors.white : kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text("Attendance Intelligence",
              style: TextStyle(fontSize: isVerySmall ? 13 : 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.2)),
          ),
          IconButton(
            onPressed: _fetchSchools,
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Refresh",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfessionalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 40, isMobile ? 16 : 32, isMobile ? 12 : 40, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isMobile) ...[
                        _buildActionButtons(isMobile),
                        const SizedBox(height: 16),
                      ],
                      _buildControls(isMobile),
                      const SizedBox(height: 32),

                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: kBrandOlive)))
                      else if (_selectedSchool == null)
                        _buildSelectionPlaceholder(isMobile)
                      else ...[
                        _buildReportSummary(isMobile),
                        const SizedBox(height: 32),
                        _reportSection(
                          title: "Participation Registry",
                          subtitle: "Detailed session tracking for the active period.",
                          isMobile: isMobile,
                          child: _buildAttendanceTable(_reportData),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPlaceholder(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 40 : 100),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: isMobile ? 60 : 80, color: isDark ? Colors.white12 : Colors.grey.shade200),
          const SizedBox(height: 32),
          Text("Select institution to generate portal",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: isMobile ? 14 : 18, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ],
      ),
    );
  }

  Widget _buildReportSummary(bool isMobile) {
    if (_reportData.isEmpty) return const SizedBox();

    double avgRate = _reportData.fold(0.0, (sum, item) => sum + (item['attendanceRate'] ?? 0)) / _reportData.length;
    int atRisk = _reportData.where((item) => (item['attendanceRate'] ?? 0) < 50).length;
    int onTrack = _reportData.where((item) => item['status'] == 'On Track').length;

    if (isMobile) {
      return Column(
        children: [
          _metricCard("Aggregate Rate", "${avgRate.toStringAsFixed(1)}%", kBrandOlive, Icons.rule_rounded, "Global Performance", isMobile),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricCard("On Track", "$onTrack", kBrandBrown, Icons.verified_rounded, "Meeting Targets", isMobile)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("At-Risk", "$atRisk", Colors.red, Icons.warning_amber_rounded, "Critical Lows", isMobile)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _metricCard("Aggregate Rate", "${avgRate.toStringAsFixed(1)}%", kBrandOlive, Icons.rule_rounded, "Global Performance", isMobile),
        const SizedBox(width: 24),
        _metricCard("On Track", "$onTrack", kBrandBrown, Icons.verified_rounded, "Meeting Targets", isMobile),
        const SizedBox(width: 24),
        _metricCard("At-Risk Scholars", "$atRisk", Colors.red, Icons.warning_amber_rounded, "Critical Lows", isMobile),
      ],
    );
  }

  Widget _buildControls(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final schoolOptions = _schools.map((s) => DropdownMenuItem(
      value: s,
      child: Text(s['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13)),
    )).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            _dropdownControl("PARTNER INSTITUTION", _selectedSchool, schoolOptions, (v) {
              setState(() {
                _selectedSchool = v;
                _reportData = [];
              });
              _fetchReport();
            }, hint: "Select school..."),
            const SizedBox(height: 16),
            _dropdownControl("REPORTING CYCLE", _selectedPeriodType, [
              'Month', 'Term', 'Semester', 'Week'
            ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13)))).toList(), (v) {
              setState(() {
                _selectedPeriodType = v!;
                _reportData = [];
              });
              _fetchReport();
            }),
            const SizedBox(height: 16),
            _buildPeriodSpecificSelector(isMobile),
          ] else
            Wrap(
              spacing: 24,
              runSpacing: 24,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 320,
                  child: _dropdownControl("PARTNER INSTITUTION", _selectedSchool, schoolOptions, (v) {
                    setState(() {
                      _selectedSchool = v;
                      _reportData = [];
                    });
                    _fetchReport();
                  }, hint: "Select school..."),
                ),
                SizedBox(
                  width: 200,
                  child: _dropdownControl("REPORTING CYCLE", _selectedPeriodType, [
                    'Month', 'Term', 'Semester', 'Week'
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown)))).toList(), (v) {
                    setState(() {
                      _selectedPeriodType = v!;
                      _reportData = [];
                    });
                    _fetchReport();
                  }),
                ),
                _buildPeriodSpecificSelector(isMobile),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.analytics_rounded, size: 20),
              label: const Text("GENERATE ANALYTICS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSpecificSelector(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedPeriodType == 'Month') {
      return SizedBox(
        width: isMobile ? double.infinity : 160,
        child: _dropdownControl("MONTH", _selectedMonth, List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
          value: m, child: Text(DateFormat('MMMM').format(DateTime(2026, m)), style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13))
        )).toList(), (v) {
          setState(() => _selectedMonth = v);
          _fetchReport();
        }),
      );
    } else if (_selectedPeriodType == 'Week') {
      return Row(
        children: [
          Expanded(
            child: _dropdownControl("MONTH", _selectedMonth, List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
              value: m, child: Text(DateFormat('MMM').format(DateTime(2026, m)), style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13))
            )).toList(), (v) {
              setState(() => _selectedMonth = v);
              _fetchReport();
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dropdownControl("WEEK", _selectedWeek, List.generate(5, (i) => i + 1).map((w) => DropdownMenuItem(
              value: w, child: Text("Week $w", style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13))
            )).toList(), (v) {
              setState(() => _selectedWeek = v);
              _fetchReport();
            }, hint: "All"),
          ),
        ],
      );
    } else if (_selectedPeriodType == 'Term') {
      return SizedBox(
        width: isMobile ? double.infinity : 160,
        child: _dropdownControl("TERM", _selectedTerm, ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(
          value: t, child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13))
        )).toList(), (v) {
          setState(() => _selectedTerm = v);
          _fetchReport();
        }, hint: "Select..."),
      );
    } else if (_selectedPeriodType == 'Semester') {
      return SizedBox(
        width: isMobile ? double.infinity : 160,
        child: _dropdownControl("SEMESTER", _selectedSemester, ['Semester 1', 'Semester 2'].map((s) => DropdownMenuItem(
          value: s, child: Text(s, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown, fontSize: 13))
        )).toList(), (v) {
          setState(() => _selectedSemester = v);
          _fetchReport();
        }, hint: "Select..."),
      );
    }
    return const SizedBox();
  }

  Widget _buildActionButtons(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: isDark ? Colors.white70 : kBrandBrown,
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("EXCEL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text("PDF REPORT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.grid_on_rounded, size: 18),
          label: const Text("EXPORT RAW DATA"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            foregroundColor: isDark ? Colors.white70 : kBrandBrown,
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
          label: const Text("EXPORT ANALYTIC PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _reportSection({required String title, required String subtitle, required Widget child, bool isMobile = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: isMobile ? 12 : 14, color: isDark ? Colors.white38 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon, String subtitle, bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
              Icon(icon, color: color.withOpacity(0.6), size: isMobile ? 18 : 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1.0)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _dropdownControl(String label, dynamic value, List<DropdownMenuItem<dynamic>> items, ValueChanged<dynamic> onChanged, {String? hint}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButton<dynamic>(
            value: value,
            isExpanded: true,
            dropdownColor: theme.cardColor,
            hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)) : null,
            underline: const SizedBox(),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTable(List scholars) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (scholars.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(80), child: Text("No individual session telemetry found.")));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 160),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
            headingRowHeight: 64,
            dataRowMaxHeight: 80,
            horizontalMargin: 32,
            columnSpacing: 32,
            columns: [
              DataColumn(label: Text("IDENTIFIER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1))),
              DataColumn(label: Text("SCHOLAR IDENTITY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1))),
              DataColumn(label: Text("QUORUM", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1))),
              DataColumn(label: Text("TARGET", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1))),
              DataColumn(label: Text("EFFICIENCY (%)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1))),
              DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1))),
            ],
            rows: scholars.map((s) {
              final String status = s['status'] ?? 'N/A';
              Color statusColor = Colors.grey;
              if (status == 'On Track') statusColor = kBrandOlive;
              else if (status == 'Behind') statusColor = Colors.orange;
              else if (status == 'At Risk') statusColor = Colors.red;

              return DataRow(
                cells: [
                  DataCell(Text(s['age_id'] ?? 'N/A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? kBrandOrange : Colors.blueGrey, letterSpacing: 0.5))),
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: kBrandOlive.withOpacity(0.1),
                          child: Text(getInitials(s['scholar_name'] ?? '?'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive)),
                        ),
                        const SizedBox(width: 16),
                        Text(s['scholar_name'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : kBrandBrown)),
                      ],
                    ),
                  ),
                  DataCell(Text("${s['present_count'] ?? 0}/${s['total_sessions'] ?? 0}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : kBrandBrown))),
                  DataCell(Text(s['target']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text("${s['attendanceRate'] ?? 0}%", style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 20, letterSpacing: -0.5))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
