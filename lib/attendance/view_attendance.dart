import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';
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
  final List<String> _years = List.generate(5, (i) => (DateTime.now().year - i).toString());

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionPanel(),
                  const SizedBox(height: 40),
                  if (_isGeneratingReport)
                    const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: kBrandOlive)))
                  else if (_attendanceReport.isEmpty)
                    _buildInitialState()
                  else
                    _buildReportSheet(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 32,
        runSpacing: 24,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.analytics_rounded, color: kBrandOlive, size: 32),
              ),
              const SizedBox(width: 24),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Participation Sheet", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                  Text("Detailed institutional attendance audit and analytics.", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.onMarkAttendance != null) ...[
                ElevatedButton.icon(
                  onPressed: widget.onMarkAttendance,
                  icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                  label: const Text("MARK REGISTER"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
              if (_attendanceReport.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.file_download_rounded, size: 20),
                  label: const Text("DOWNLOAD SHEET"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
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
          const SizedBox(width: 20),
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
          const SizedBox(width: 20),
          // 3. Term / Semester
          if (_selectedSchoolLevel != null)
            Expanded(
              flex: 2,
              child: (_selectedSchoolLevel == 'Tertiary / University' || _selectedSchoolLevel == 'University')
                  ? _buildDropdown("SEMESTER", Icons.layers_rounded, "Select", _selectedSemester, _semesters, (val) => setState(() => _selectedSemester = val))
                  : _buildDropdown("TERM", Icons.layers_rounded, "Select", _selectedTerm, _terms, (val) => setState(() => _selectedTerm = val)),
            ),
          const SizedBox(width: 32),
          // 4. Action Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedSchoolId != null && (_selectedTerm != null || _selectedSemester != null)) ? _generateReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text("GENERATE SHEET", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSheet() {
    final report = _filteredReport;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 400,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: "Filter by scholar name or ID...",
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kBrandOlive),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 160),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                headingRowHeight: 64,
                dataRowMaxHeight: 72,
                columnSpacing: 24,
                horizontalMargin: 32,
                columns: const [
                  DataColumn(label: Text("AGE ID", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1, fontSize: 12))),
                  DataColumn(label: Text("SCHOLAR NAME", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1, fontSize: 12))),
                  DataColumn(label: Text("PRESENT", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1, fontSize: 12))),
                  DataColumn(label: Text("TARGET", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1, fontSize: 12))),
                  DataColumn(label: Text("RATE (%)", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1, fontSize: 12))),
                  DataColumn(label: Text("PARTICIPATION STATUS", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1, fontSize: 12))),
                ],
                rows: report.map((item) {
                  final rate = item['attendanceRate'] as int;
                  final color = _getParticipationColor(rate);
                  return DataRow(
                    cells: [
                      DataCell(Text(item['age_id'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                      DataCell(Text(item['scholar_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text("${item['present_count']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      DataCell(Text("${item['target']}", style: TextStyle(color: Colors.grey.shade600))),
                      DataCell(Text("$rate%", style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(
                                _getParticipationLabel(rate).toUpperCase(),
                                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _legendItem("High", Colors.green),
          const SizedBox(width: 24),
          _legendItem("Moderate", Colors.amber),
          const SizedBox(width: 24),
          _legendItem("Low", Colors.red),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 120),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(Icons.fact_check_outlined, size: 80, color: Colors.grey.shade200),
          ),
          const SizedBox(height: 32),
          Text("Institutional Sheet Ready", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          const SizedBox(height: 12),
          SizedBox(
            width: 400,
            child: Text(
              "Please select a partner school and the reporting period above to generate the attendance audit sheet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kBrandOlive),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.5)),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kBrandBrown), overflow: TextOverflow.ellipsis))).toList(),
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
                ['AGE ID', 'SCHOLAR NAME', 'PERIOD', 'PRESENT', 'TARGET', 'RATE', 'STATUS'],
                ...report.map((item) => [
                  item['age_id'] ?? '',
                  item['scholar_name'] ?? '',
                  item['periodLabel'] ?? '',
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
