import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';
import '../widgets/custom_loaders.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewAttendanceComponent extends StatefulWidget {
  final VoidCallback? onMarkAttendance;
  const ViewAttendanceComponent({super.key, this.onMarkAttendance});

  @override
  State<ViewAttendanceComponent> createState() => _ViewAttendanceComponentState();
}

class _ViewAttendanceComponentState extends State<ViewAttendanceComponent> {
  // State for selections
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchoolId;
  String? _selectedSchoolName;
  String? _selectedSchoolLevel;

  String? _selectedTerm;
  String? _selectedSemester;
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = '';

  bool _isLoadingSchools = true;
  bool _isGeneratingReport = false;
  List<dynamic> _attendanceReport = [];

  final List<String> _terms = ['Term 1', 'Term 2', 'Term 3', 'Whole Year'];
  final List<String> _semesters = ['Semester 1', 'Semester 2', 'Whole Year'];
  final List<String> _years = List.generate(10, (i) => (DateTime.now().year - i).toString());

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
            _schools = List<Map<String, dynamic>>.from(response.data['data']);
            _isLoadingSchools = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
      if (mounted) setState(() => _isLoadingSchools = false);
    }
  }

  Future<void> _generateReport() async {
    if (_selectedSchoolId == null) return;
    
    setState(() => _isGeneratingReport = true);
    try {
      final String? term = _selectedTerm == 'Whole Year' ? null : _selectedTerm;
      final String? semester = _selectedSemester == 'Whole Year' ? null : _selectedSemester;

      final response = await ApiService.getSchoolAttendanceReport(
        _selectedSchoolId!,
        term: term,
        semester: semester,
        year: _selectedYear,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _attendanceReport = (response.data['data'] ?? [])
                .where((item) => (item['scholar_status'] ?? item['status'] ?? 'Active') == 'Active')
                .toList();
            _isGeneratingReport = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error generating report: $e');
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  List<dynamic> get _filteredReport {
    if (_searchQuery.isEmpty) return _attendanceReport;
    return _attendanceReport.where((item) {
      final name = (item['scholar_name'] ?? '').toString().toLowerCase();
      final id = (item['age_id'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || id.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Color _getParticipationColor(int rate) {
    if (rate < 50) return Colors.red.shade600;
    if (rate < 80) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  String _getParticipationLabel(int rate) {
    if (rate < 50) return "Low Participation";
    if (rate < 80) return "Moderate Participation";
    return "High Participation";
  }

  String _initialsOf(String name) {
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectionPanel(),
                      const SizedBox(height: 48),
                      if (_isGeneratingReport)
                        const Center(child: Padding(padding: EdgeInsets.all(100), child: BeautifulLoader(isOverlay: false, message: "Synthesizing Attendance Analytics")))
                      else if (_attendanceReport.isEmpty)
                        _buildInitialState()
                      else
                        _buildReportSheet(),
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

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 12, 40, 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrandOlive.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: kBrandOlive, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Participation Sheet",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.2)),
                  const Text("Institutional attendance audit and analytics.",
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onMarkAttendance != null) ...[
                ElevatedButton.icon(
                  onPressed: widget.onMarkAttendance,
                  icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                  label: const Text("MARK REGISTER"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (_attendanceReport.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.file_download_rounded, size: 16),
                  label: const Text("DOWNLOAD SHEET"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? theme.colorScheme.primaryContainer : kBrandBrown,
                    foregroundColor: isDark ? theme.colorScheme.onPrimaryContainer : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. School Selection
        Expanded(
          flex: 3,
          child: _buildDropdown(
            "PARTNER INSTITUTION",
            Icons.school_rounded,
            _isLoadingSchools ? "Loading..." : "Select School",
            _selectedSchoolName,
            _schools.map((s) => s['name'].toString()).toList(),
            (val) {
              final school = _schools.firstWhere((s) => s['name'] == val);
              setState(() {
                _selectedSchoolName = val;
                _selectedSchoolId = school['id'].toString();
                _selectedSchoolLevel = school['level'];
                _selectedTerm = null;
                _selectedSemester = null;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        // 2. Year Selection
        Expanded(
          flex: 2,
          child: _buildDropdown(
            "ACADEMIC YEAR",
            Icons.calendar_today_rounded,
            "Year",
            _selectedYear,
            _years,
            (val) => setState(() => _selectedYear = val!),
          ),
        ),
        const SizedBox(width: 16),
        // 3. Term / Semester
        if (_selectedSchoolLevel != null)
          Expanded(
            flex: 2,
            child: (_selectedSchoolLevel == 'Tertiary / University' || _selectedSchoolLevel == 'University')
                ? _buildDropdown("SEMESTER", Icons.layers_rounded, "Select", _selectedSemester, _semesters, (val) => setState(() => _selectedSemester = val))
                : _buildDropdown("TERM", Icons.layers_rounded, "Select", _selectedTerm, _terms, (val) => setState(() => _selectedTerm = val)),
          ),
        const SizedBox(width: 24),
        // 4. Action Button
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: (_selectedSchoolId != null && (_selectedTerm != null || _selectedSemester != null)) ? _generateReport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
            ),
            child: const Text("GENERATE"),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final report = _filteredReport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 450,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: isDark ? Colors.white : kBrandBrown, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Filter by scholar name or ID handle...",
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 22, color: kBrandOlive),
                  filled: true,
                  fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
                ),
              ),
            ),
            _buildLegend(),
          ],
        ),
        const SizedBox(height: 32),
        
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 160),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
                headingRowHeight: 72,
                dataRowMaxHeight: 80,
                columnSpacing: 24,
                horizontalMargin: 32,
                columns: [
                  DataColumn(label: Text("IDENTIFIER", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 1, fontSize: 11))),
                  DataColumn(label: Text("SCHOLAR IDENTITY", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 1, fontSize: 11))),
                  DataColumn(label: Text("SESSIONS PRESENT", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 1, fontSize: 11))),
                  DataColumn(label: Text("EXPECTED", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 1, fontSize: 11))),
                  DataColumn(label: Text("QUOTIENT (%)", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 1, fontSize: 11))),
                  DataColumn(label: Text("PARTICIPATION METRIC", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 1, fontSize: 11))),
                ],
                rows: report.map((item) {
                  final rate = item['attendanceRate'] as int;
                  final color = _getParticipationColor(rate);
                  return DataRow(
                    cells: [
                      DataCell(Text(item['age_id'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? kBrandOrange : kBrandBrown, letterSpacing: 0.5))),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: kBrandOlive.withOpacity(0.1),
                              child: Text(_initialsOf(item['scholar_name'] ?? '?'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive)),
                            ),
                            const SizedBox(width: 16),
                            Text(item['scholar_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                      DataCell(Text("${item['present_count']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : kBrandBrown))),
                      DataCell(Text("${item['target']}", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.bold))),
                      DataCell(Text("$rate%", style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 20, letterSpacing: -0.5))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Text(
                                _getParticipationLabel(rate).toUpperCase(),
                                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem("High Threshold", Colors.green),
          const SizedBox(width: 24),
          _legendItem("Nominal", Colors.amber),
          const SizedBox(width: 24),
          _legendItem("Intervention Req.", Colors.red),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildInitialState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 120),
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.analytics_rounded, size: 80, color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          const SizedBox(height: 40),
          Text("Institutional sheet context ready",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey.shade400, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: 450,
            child: Text(
              "Please select a partner school and the reporting period above to synthesize the participation audit sheet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kBrandOlive, size: 18),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: isDark ? Colors.white70 : kBrandBrown.withOpacity(0.5)),
            hintText: hint,
            filled: true,
            fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 1.5)),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown),
              overflow: TextOverflow.ellipsis
            )
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _exportToPDF() async {
    final report = _filteredReport;
    if (report.isEmpty) return;

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("AGE AFRICA - ATTENDANCE AUDIT SHEET", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.brown800)),
                      pw.SizedBox(height: 4),
                      pw.Text("Institutional Participation Report", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(_selectedSchoolName ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text("${_selectedTerm ?? _selectedSemester} - ${_selectedYear}", style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Table.fromTextArray(
              context: context,
              data: [
                ['AGE ID', 'SCHOLAR NAME', 'PRESENT', 'TARGET', 'RATE', 'STATUS'],
                ...report.map((item) => [
                  item['age_id'] ?? '',
                  item['scholar_name'] ?? '',
                  item['present_count'].toString(),
                  item['target'].toString(),
                  "${item['attendanceRate']}%",
                  _getParticipationLabel(item['attendanceRate']).toUpperCase()
                ])
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.Footer(
              margin: const pw.EdgeInsets.only(top: 24),
              trailing: pw.Text("Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => doc.save(), name: 'Attendance_${_selectedSchoolName}_${_selectedYear}');
    } catch (e) {
      debugPrint('PDF Error: $e');
    }
  }
}
