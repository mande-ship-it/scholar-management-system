import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'academicsUtils.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

String _initialsOf(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

/// ---------------------------------------------------------------------
/// COMPONENT
/// ---------------------------------------------------------------------

class ViewResultsComponent extends StatefulWidget {
  const ViewResultsComponent({super.key});

  @override
  State<ViewResultsComponent> createState() => _ViewResultsComponentState();
}

class _ViewResultsComponentState extends State<ViewResultsComponent> {
  final TextEditingController _searchController = TextEditingController();

  SchoolType? _schoolTypeFilter; // null = All
  String? _schoolNameFilter; // null = All
  bool _isExportingRoster = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _schoolNameOptions {
    final students = _schoolTypeFilter == null
        ? kStudents
        : kStudents.where((s) => s.schoolType == _schoolTypeFilter).toList();
    final names = students.map((s) => s.schoolName).toSet().toList()..sort();
    return names;
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    return kStudents.where((s) {
      final matchesQuery = query.isEmpty || s.name.toLowerCase().contains(query);
      final matchesType =
          _schoolTypeFilter == null || s.schoolType == _schoolTypeFilter;
      final matchesSchool =
          _schoolNameFilter == null || s.schoolName == _schoolNameFilter;
      return matchesQuery && matchesType && matchesSchool;
    }).toList();
  }

  void _openStudentResults(Student student) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Exam Results",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * curved.value),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
                child: _StudentExamResultsSheet(student: student),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportRosterCsv() async {
    setState(() => _isExportingRoster = true);
    try {
      final rows = <List<dynamic>>[
        ['Student ID', 'Name', 'School Type', 'School', 'Result Count'],
      ];
      for (final student in _filteredStudents) {
        final count = kResults.where((r) => r.studentId == student.id).length;
        rows.add([
          student.id,
          student.name,
          student.schoolType == SchoolType.university ? 'University' : 'Secondary',
          student.schoolName,
          count,
        ]);
      }
      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Student Roster as CSV',
        fileName: 'Scholars_Results_Roster.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roster exported successfully.'),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingRoster = false);
    }
  }

  Widget _miniStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kBrandCream),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F6F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kBrandBrown, kBrandOlive],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "View Results",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${students.length} of ${kStudents.length} students",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _miniStat(Icons.groups_rounded, "${students.length} shown"),
                    _miniStat(Icons.fact_check_rounded, "${kResults.length} results"),
                  ],
                ),
                const SizedBox(width: 8),
                _isExportingRoster
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _exportRosterCsv,
                    tooltip: "Export Roster (CSV)",
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _schoolTypeFilter = null;
                      _schoolNameFilter = null;
                    }),
                    tooltip: "Reset Filters",
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Search by Name",
                        hintText: "Enter name...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(_searchController.clear),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<SchoolType?>(
                      initialValue: _schoolTypeFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "School Type",
                        prefixIcon: const Icon(Icons.category_outlined, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Types')),
                        DropdownMenuItem(value: SchoolType.secondary, child: Text('Secondary')),
                        DropdownMenuItem(value: SchoolType.university, child: Text('University')),
                      ],
                      onChanged: (v) => setState(() {
                        _schoolTypeFilter = v;
                        _schoolNameFilter = null;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey(_schoolTypeFilter),
                      initialValue: _schoolNameFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "School Name",
                        prefixIcon: const Icon(Icons.school_outlined, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Schools')),
                        ..._schoolNameOptions.map(
                              (name) => DropdownMenuItem(
                            value: name,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _schoolNameFilter = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: students.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No Students Found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try loosening your filters or clearing search text.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final resultCount = kResults.where((r) => r.studentId == student.id).length;
                    final isUniversity = student.schoolType == SchoolType.university;

                    return Material(
                      color: index.isEven ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.6),
                      child: InkWell(
                        onTap: () => _openStudentResults(student),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: kBrandOlive.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _initialsOf(student.name),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isUniversity ? kBrandBrown.withValues(alpha: 0.08) : kBrandOrange.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isUniversity ? 'University' : 'Secondary',
                                            style: TextStyle(
                                              color: isUniversity ? kBrandBrown : kBrandOrange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            student.schoolName,
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kBrandCream,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$resultCount result${resultCount == 1 ? '' : 's'}',
                                  style: const TextStyle(color: kBrandBrown, fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentExamResultsSheet extends StatefulWidget {
  const _StudentExamResultsSheet({required this.student});

  final Student student;

  @override
  State<_StudentExamResultsSheet> createState() => _StudentExamResultsSheetState();
}

class _StudentExamResultsSheetState extends State<_StudentExamResultsSheet> {
  late String _selectedYear;
  bool _isExporting = false;

  bool get _isUniversity => widget.student.schoolType == SchoolType.university;

  List<ResultRecord> get _studentResults =>
      kResults.where((r) => r.studentId == widget.student.id).toList();

  List<String> get _yearOptions {
    final years = _studentResults.map((r) => r.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<String> get _periods => _isUniversity ? ['Semester 1', 'Semester 2'] : ['Term 1', 'Term 2', 'Term 3'];

  @override
  void initState() {
    super.initState();
    _selectedYear = _yearOptions.isNotEmpty ? _yearOptions.first : DateTime.now().year.toString();
  }

  List<ResultRecord> _resultsFor(String period) {
    return _studentResults.where((r) {
      final matchesYear = r.year == _selectedYear;
      final matchesPeriod = _isUniversity ? r.semester == period : r.term == period;
      return matchesYear && matchesPeriod;
    }).toList();
  }

  double _gpaFor(List<ResultRecord> records) {
    if (records.isEmpty) return 0;
    return records.map((r) => r.gradePoint).reduce((a, b) => a + b) / records.length;
  }

  Future<void> _exportCsv(List<String> periodsWithResults, double endOfYearGpa, bool passed) async {
    setState(() => _isExporting = true);
    try {
      final rows = <List<dynamic>>[
        ['Period', '#', 'Code', 'Title', 'Final Grade', 'Letter Grade', 'Grade Point'],
      ];
      for (final period in periodsWithResults) {
        final records = _resultsFor(period);
        for (var i = 0; i < records.length; i++) {
          final r = records[i];
          rows.add([period, i + 1, r.code, r.subject, r.marks, gradeFromMarks(r.marks, isUniversity: _isUniversity).letter, r.gradePoint.toStringAsFixed(2)]);
        }
      }
      rows.add([]);
      for (final period in periodsWithResults) {
        rows.add(['$period GPA', _gpaFor(_resultsFor(period)).toStringAsFixed(2)]);
      }
      rows.add(['End of Year GPA', endOfYearGpa.toStringAsFixed(2)]);
      rows.add(['Outcome', passed ? 'PASS AND PROCEED' : 'BELOW REQUIREMENT']);

      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final fileName = '${widget.student.name.replaceAll(' ', '_')}_Results_$_selectedYear.csv';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Results as CSV',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results exported to CSV successfully.'), backgroundColor: kBrandOlive, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf(List<String> periodsWithResults, double endOfYearGpa, bool passed) async {
    setState(() => _isExporting = true);
    try {
      final brown = PdfColor.fromInt(kBrandBrown.toARGB32());
      final olive = PdfColor.fromInt(kBrandOlive.toARGB32());
      final cream = PdfColor.fromInt(kBrandCream.toARGB32());
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: brown, width: 2))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('EXAM RESULTS TRANSCRIPT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.SizedBox(height: 2),
                    pw.Text('AGE Africa — Scholar Management System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(_selectedYear, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: olive)),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: cream, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Scholar: ${widget.student.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.SizedBox(height: 3),
                      pw.Text('School: ${widget.student.schoolName}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Text(_isUniversity ? 'University' : 'Secondary', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brown)),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            for (final period in periodsWithResults) ...[
              pw.Text('$period Courses', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brown)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Code', 'Title', 'Final Grade', 'Letter Grade', 'Grade Point'],
                data: [
                  for (var i = 0; i < _resultsFor(period).length; i++)
                    (() {
                      final r = _resultsFor(period)[i];
                      return [
                        '${i + 1}',
                        r.code,
                        r.subject,
                        r.marks.toStringAsFixed(0),
                        gradeFromMarks(r.marks, isUniversity: _isUniversity).letter,
                        r.gradePoint.toStringAsFixed(2),
                      ];
                    })(),
                ],
                headerDecoration: pw.BoxDecoration(color: brown),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              ),
              pw.SizedBox(height: 6),
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('$period GPA: ${_gpaFor(_resultsFor(period)).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 16),
            ],
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('End of Year GPA: ${endOfYearGpa.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(color: passed ? olive : PdfColors.red700, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text(passed ? 'PASS AND PROCEED' : 'BELOW REQUIREMENT', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      );

      final fileName = '${widget.student.name.replaceAll(' ', '_')}_Results_$_selectedYear.pdf';
      await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: fileName);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodsWithResults = _periods.where((p) => _resultsFor(p).isNotEmpty).toList();
    final allYearResults = _studentResults.where((r) => r.year == _selectedYear).toList();
    final endOfYearGpa = _gpaFor(allYearResults);
    final passed = allYearResults.isNotEmpty && endOfYearGpa >= 2.0;
    final initials = _initialsOf(widget.student.name);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kBrandBrown, kBrandOlive])),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  alignment: Alignment.center,
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXAM RESULTS — ${widget.student.name}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(widget.student.schoolName, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (_yearOptions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      dropdownColor: kBrandBrown,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.expand_more, color: Colors.white, size: 18),
                      items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop(), style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15))),
              ],
            ),
          ),
          Flexible(
            child: periodsWithResults.isEmpty
                ? const Padding(padding: EdgeInsets.all(48), child: Text('No results recorded yet.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final period in periodsWithResults) ...[
                          _PeriodResultsTable(periodLabel: '$period Courses', records: _resultsFor(period), isUniversity: _isUniversity),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
          ),
          if (periodsWithResults.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: kBrandOrange),
                      for (final period in periodsWithResults) Text('$period GPA: ${_gpaFor(_resultsFor(period)).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      Text('End of Year GPA: ${endOfYearGpa.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kBrandBrown)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: passed ? kBrandOlive : Colors.red.shade600, borderRadius: BorderRadius.circular(4)), child: Text(passed ? 'PASS AND PROCEED' : 'BELOW REQUIREMENT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: _isExporting ? null : () => _exportCsv(periodsWithResults, endOfYearGpa, passed), icon: const Icon(Icons.grid_on_rounded, size: 18), label: const Text('Export CSV / Excel'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), foregroundColor: kBrandBrown, side: const BorderSide(color: kBrandBrown)))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(onPressed: _isExporting ? null : () => _exportPdf(periodsWithResults, endOfYearGpa, passed), icon: _isExporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.picture_as_pdf_outlined, size: 18), label: Text(_isExporting ? 'Exporting...' : 'Export PDF'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: kBrandOlive, foregroundColor: Colors.white, elevation: 0))),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodResultsTable extends StatelessWidget {
  const _PeriodResultsTable({required this.periodLabel, required this.records, required this.isUniversity});
  final String periodLabel;
  final List<ResultRecord> records;
  final bool isUniversity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(periodLabel, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(kBrandCream),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                DataColumn(label: Text('Final Grade', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                DataColumn(label: Text('Letter Grade', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                DataColumn(label: Text('Grade Point', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
              ],
              rows: List.generate(records.length, (index) {
                final r = records[index];
                return DataRow(
                  color: WidgetStateProperty.all(index.isEven ? Colors.white : Colors.grey.shade50),
                  cells: [
                    DataCell(Text('${index + 1}', style: TextStyle(color: Colors.grey.shade600))),
                    DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kBrandOlive, borderRadius: BorderRadius.circular(6)), child: Text(r.code, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))),
                    DataCell(Text(r.subject, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Container(width: 32, height: 32, alignment: Alignment.center, decoration: const BoxDecoration(color: kBrandBrown, shape: BoxShape.circle), child: Text(r.marks.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                    DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kBrandOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text(gradeFromMarks(r.marks, isUniversity: isUniversity).letter, style: const TextStyle(color: kBrandOrange, fontWeight: FontWeight.bold, fontSize: 12)))),
                    DataCell(Text(r.gradePoint.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
