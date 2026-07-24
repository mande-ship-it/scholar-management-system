// ---------------------------------------------------------------------
// pubspec.yaml additions needed for export functionality (same as
// viewResults.dart — skip if already added):
//   pdf: ^3.10.8
//   printing: ^5.12.0
//   csv: ^6.0.0
//   file_picker: ^8.1.2
//
// Uses the existing "assets/images/age-logo.png" asset already
// registered in pubspec.yaml.
// ---------------------------------------------------------------------

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import 'academics_utils.dart';

// ============================================================
// Shared Brand Color Palette (consistent with Register Scholar /
// View Scholars / View Results). If these are already declared in
// a shared constants file in your project, remove this block and
// import that file instead to avoid duplicate-definition errors
// when multiple screens are imported together.
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

const String kAgeLogoAsset = 'assets/images/age-logo.png';

/// ---------------------------------------------------------------------
/// HELPERS
/// ---------------------------------------------------------------------

enum ReportMode { student, school }

List<String> _allYears() => kResults.map((r) => r.year).toSet().toList()..sort();

List<ResultRecord> _resultsForStudent(
    String studentId, {
      String? year,
      String? period,
      required bool isUniversity,
    }) {
  return kResults.where((r) {
    if (r.studentId != studentId) return false;
    if (year != null && r.year != year) return false;
    if (period != null) {
      final p = isUniversity ? r.semester : r.term;
      if (p != period) return false;
    }
    return true;
  }).toList();
}

double _averageMarks(List<ResultRecord> records) {
  if (records.isEmpty) return 0;
  return records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
}

String _letterGrade(double marks) {
  if (marks >= 80) return 'A (Distinction)';
  if (marks >= 70) return 'B (Merit)';
  if (marks >= 60) return 'C (Credit)';
  if (marks >= 50) return 'D (Pass)';
  return 'F (Fail)';
}

String _remarkFor(double avg) {
  if (avg >= 80) return 'Excellent performance. Keep up the outstanding work.';
  if (avg >= 65) return 'Good performance overall, with room to push further.';
  if (avg >= 50) return 'Satisfactory performance. More effort is encouraged.';
  return 'Below expectation. Additional support is recommended.';
}

({int rank, int total}) _rankInSchool(
    String studentId,
    String schoolName, {
      String? year,
      String? period,
    }) {
  final peers = kStudents.where((s) => s.schoolName == schoolName).toList();
  final ranked = peers
      .map((s) => MapEntry(
    s.id,
    _averageMarks(_resultsForStudent(
      s.id,
      year: year,
      period: period,
      isUniversity: s.schoolType == SchoolType.university,
    )),
  ))
      .where((e) => e.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final index = ranked.indexWhere((e) => e.key == studentId);
  return (rank: index == -1 ? 0 : index + 1, total: ranked.length);
}

String _today() {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

/// ---------------------------------------------------------------------
/// COMPONENT
/// ---------------------------------------------------------------------

class ReportCardsComponent extends StatefulWidget {
  const ReportCardsComponent({super.key});

  @override
  State<ReportCardsComponent> createState() => _ReportCardsComponentState();
}

class _ReportCardsComponentState extends State<ReportCardsComponent> {
  ReportMode _mode = ReportMode.student;
  String? _selectedSchoolFilter; // narrows the student picker by school
  String? _selectedStudentId;
  String? _selectedSchool; // school-summary mode selection
  String? _yearFilter;
  String? _periodFilter; // null = Overall (all periods combined)
  bool _isExporting = false;
  bool _isLoadingResults = false;

  @override
  void initState() {
    super.initState();
    _fetchBaseData();
  }

  Future<void> _fetchBaseData() async {
    // Ensure scholars are loaded for the pickers
    if (kStudents.isEmpty) {
      try {
        final response = await ApiService.getAllScholars();
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['data'];
          setState(() {
            kStudents.clear();
            for (var item in data) {
              kStudents.add(Student(
                id: item['id'].toString(),
                scholarId: item['scholar_id'] ?? 'N/A',
                name: item['full_name'] ?? 'N/A',
                age: item['dob'] != null && item['dob'].toString().isNotEmpty
                    ? DateTime.now().year - DateTime.parse(item['dob']).year
                    : 16,
                schoolType: item['school_type'] == 'University' ? SchoolType.university : SchoolType.secondary,
                schoolName: item['display_school_name'] ?? 'N/A',
                currentClass: item['academic_year'] ?? 'N/A',
                status: item['status'] ?? 'Active',
                district: item['district'] ?? 'N/A',
                village: item['village'] ?? 'N/A',
                donor: item['donor'] ?? 'N/A',
                phone: item['phone'] ?? 'N/A',
                email: item['email'] ?? 'N/A',
                sex: item['sex'] ?? 'Female',
                dob: item['dob'] ?? '',
                programType: item['program_type'] ?? '',
                startYear: item['start_year']?.toString() ?? '2026',
                endYear: item['end_year']?.toString() ?? '2030',
              ));
            }
          });
        }
      } catch (e) {
        debugPrint('Error fetching scholars for report cards: $e');
      }
    }
  }

  Future<void> _fetchResultsForStudent(String id) async {
    setState(() => _isLoadingResults = true);
    try {
      final response = await ApiService.getResultsByScholar(id);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          // Remove old results for this student and add new ones
          kResults.removeWhere((r) => r.studentId == id);
          for (var item in data) {
            kResults.add(ResultRecord(
              studentId: item['scholar_id'].toString(),
              code: item['subject_code'] ?? 'N/A',
              subject: item['subject_name'] ?? 'N/A',
              marks: double.parse(item['marks'].toString()),
              gpa: item['gpa'] != null ? double.parse(item['gpa'].toString()) : null,
              points: item['points'] != null ? double.parse(item['points'].toString()) : null,
              year: item['academic_year'].toString(),
              term: item['term'],
              semester: item['semester'],
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching results for student: $e');
    } finally {
      if (mounted) setState(() => _isLoadingResults = false);
    }
  }

  Future<void> _fetchResultsForSchool(String schoolName) async {
    setState(() => _isLoadingResults = true);
    try {
      final response = await ApiService.getResultsBySchool(schoolName);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          // In a real app, we might want to be more selective, 
          // but for this dashboard we'll refresh results for students in this school
          final studentIds = kStudents.where((s) => s.schoolName == schoolName).map((s) => s.id).toSet();
          kResults.removeWhere((r) => studentIds.contains(r.studentId));
          
          for (var item in data) {
            kResults.add(ResultRecord(
              studentId: item['scholar_id'].toString(),
              code: item['subject_code'] ?? 'N/A',
              subject: item['subject_name'] ?? 'N/A',
              marks: double.parse(item['marks'].toString()),
              gpa: item['gpa'] != null ? double.parse(item['gpa'].toString()) : null,
              points: item['points'] != null ? double.parse(item['points'].toString()) : null,
              year: item['academic_year'].toString(),
              term: item['term'],
              semester: item['semester'],
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching results for school: $e');
    } finally {
      if (mounted) setState(() => _isLoadingResults = false);
    }
  }

  List<String> get _schoolOptions => kStudents.map((s) => s.schoolName).toSet().toList()..sort();

  List<Student> get _studentOptionsForSchool => _selectedSchoolFilter == null
      ? kStudents
      : kStudents.where((s) => s.schoolName == _selectedSchoolFilter).toList();

  bool get _isUniversitySelection {
    if (_mode == ReportMode.student && _selectedStudentId != null) {
      final s = kStudents.firstWhere((s) => s.id == _selectedStudentId);
      return s.schoolType == SchoolType.university;
    }
    if (_mode == ReportMode.school && _selectedSchool != null) {
      final s = kStudents.firstWhere((s) => s.schoolName == _selectedSchool);
      return s.schoolType == SchoolType.university;
    }
    return false;
  }

  void _onModeChanged(Set<ReportMode> selection) {
    setState(() {
      _mode = selection.first;
      _selectedSchoolFilter = null;
      _selectedStudentId = null;
      _selectedSchool = null;
      _yearFilter = null;
      _periodFilter = null;
    });
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load(kAgeLogoAsset);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null; // Falls back to a plain text header if the asset is missing.
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT — Student transcript (PDF)
  // ---------------------------------------------------------------------
  Future<void> _exportStudentPdf() async {
    if (_selectedStudentId == null) return;
    setState(() => _isExporting = true);
    try {
      final student = kStudents.firstWhere((s) => s.id == _selectedStudentId);
      final isUniversity = student.schoolType == SchoolType.university;
      final records = _resultsForStudent(
        student.id,
        year: _yearFilter,
        period: _periodFilter,
        isUniversity: isUniversity,
      );
      final avgMarks = _averageMarks(records);
      final gpaRecords = records.where((r) => r.gpa != null).toList();
      final avgGpa = gpaRecords.isEmpty ? null : gpaRecords.map((r) => r.gpa!).reduce((a, b) => a + b) / gpaRecords.length;
      final totalPoints = records.where((r) => r.points != null).fold<double>(0, (sum, r) => sum + (r.points ?? 0));
      final position = _rankInSchool(student.id, student.schoolName, year: _yearFilter, period: _periodFilter);
      final logo = await _loadLogo();

      final brown = PdfColor.fromInt(kBrandBrown.toARGB32());
      final gold = PdfColor.fromInt(const Color(0xFFC5A880).toARGB32());

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: gold, width: 2)),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(student.schoolName.toUpperCase(),
                            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: brown)),
                        pw.SizedBox(height: 2),
                        pw.Text('AGE Africa Education Scholarship Program',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                    if (logo != null) pw.Image(logo, height: 44, width: 44) else pw.SizedBox(height: 44),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: gold, thickness: 1.2),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    isUniversity ? 'OFFICIAL ACADEMIC TRANSCRIPT' : 'OFFICIAL ACADEMIC REPORT CARD',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _pdfInfo('Full Name', student.name),
                      _pdfInfo('Scholar ID', student.id.toUpperCase()),
                      _pdfInfo('Scholar Age', '${student.age} Years'),
                      _pdfInfo('Institution Level', isUniversity ? 'University' : 'Secondary School'),
                      _pdfInfo('Academic Year', _yearFilter ?? 'All Recorded Years'),
                      _pdfInfo(isUniversity ? 'Semester' : 'Term', _periodFilter ?? 'Overall'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                if (records.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 24),
                    child: pw.Center(child: pw.Text('No exam scores recorded for the selected filters.')),
                  )
                else ...[
                  pw.TableHelper.fromTextArray(
                    headers: [
                      isUniversity ? 'Course' : 'Subject',
                      'Marks',
                      isUniversity ? 'GPA' : 'Points',
                      if (!isUniversity) 'Letter Grade',
                      'Year',
                      isUniversity ? 'Semester' : 'Term',
                    ],
                    data: records
                        .map((r) => [
                      r.subject,
                      '${r.marks.toStringAsFixed(0)}%',
                      isUniversity ? (r.gpa ?? 0).toStringAsFixed(2) : (r.points ?? 0).toStringAsFixed(0),
                      if (!isUniversity) _letterGrade(r.marks),
                      r.year,
                      (isUniversity ? r.semester : r.term) ?? '-',
                    ])
                        .toList(),
                    headerDecoration: pw.BoxDecoration(color: brown),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(color: brown, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _pdfStat('Subjects', '${records.length}'),
                        _pdfStat('Average', '${avgMarks.toStringAsFixed(1)}%'),
                        if (isUniversity)
                          _pdfStat('Cumulative GPA', (avgGpa ?? 0).toStringAsFixed(2))
                        else
                          _pdfStat('Points', totalPoints.toStringAsFixed(0)),
                        _pdfStat('Ranking', position.rank == 0 ? '—' : '${position.rank}/${position.total}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text('Academic Faculty Remarks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(_remarkFor(avgMarks), style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Issued on ${_today()}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Row(
                        children: [
                          _pdfSignature('Prof. E. Chimphamba', isUniversity ? 'University Registrar' : 'Class Teacher'),
                          pw.SizedBox(width: 24),
                          _pdfSignature('Dr. M. Nyasulu', isUniversity ? 'Dean of Academics' : 'Head Teacher'),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      final fileName = '${student.name.replaceAll(' ', '_')}_ReportCard_${_yearFilter ?? 'AllYears'}.pdf';
      await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: fileName);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT — Student transcript (CSV / Excel)
  // ---------------------------------------------------------------------
  Future<void> _exportStudentCsv() async {
    if (_selectedStudentId == null) return;
    setState(() => _isExporting = true);
    try {
      final student = kStudents.firstWhere((s) => s.id == _selectedStudentId);
      final isUniversity = student.schoolType == SchoolType.university;
      final records = _resultsForStudent(
        student.id,
        year: _yearFilter,
        period: _periodFilter,
        isUniversity: isUniversity,
      );
      final avgMarks = _averageMarks(records);

      final rows = <List<dynamic>>[
        ['Scholar', student.name],
        ['School', student.schoolName],
        ['Year', _yearFilter ?? 'All Recorded Years'],
        [isUniversity ? 'Semester' : 'Term', _periodFilter ?? 'Overall'],
        [],
        [isUniversity ? 'Course' : 'Subject', 'Marks', isUniversity ? 'GPA' : 'Points', 'Letter Grade', 'Year', isUniversity ? 'Semester' : 'Term'],
        for (final r in records)
          [r.subject, r.marks, isUniversity ? (r.gpa ?? 0) : (r.points ?? 0), _letterGrade(r.marks), r.year, (isUniversity ? r.semester : r.term) ?? '-'],
        [],
        ['Average Marks', avgMarks.toStringAsFixed(1)],
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report Card as CSV',
        fileName: '${student.name.replaceAll(' ', '_')}_ReportCard_${_yearFilter ?? 'AllYears'}.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report card exported to CSV successfully.'), backgroundColor: kBrandOlive, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT — School summary (PDF)
  // ---------------------------------------------------------------------
  Future<void> _exportSchoolPdf() async {
    if (_selectedSchool == null) return;
    setState(() => _isExporting = true);
    try {
      final schoolName = _selectedSchool!;
      final students = kStudents.where((s) => s.schoolName == schoolName).toList();
      final isUniversity = students.isNotEmpty && students.first.schoolType == SchoolType.university;
      final rows = students
          .map((s) {
        final records = _resultsForStudent(s.id, year: _yearFilter, period: _periodFilter, isUniversity: isUniversity);
        return (student: s, average: _averageMarks(records), hasRecords: records.isNotEmpty);
      })
          .where((r) => r.hasRecords)
          .toList()
        ..sort((a, b) => b.average.compareTo(a.average));
      final schoolAverage = rows.isEmpty ? 0.0 : rows.map((r) => r.average).reduce((a, b) => a + b) / rows.length;
      final logo = await _loadLogo();

      final brown = PdfColor.fromInt(kBrandBrown.toARGB32());
      final olive = PdfColor.fromInt(kBrandOlive.toARGB32());
      final cream = PdfColor.fromInt(kBrandCream.toARGB32());

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: olive, width: 2))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.Text('School Exam Results Summary Report', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                if (logo != null) pw.Image(logo, height: 40, width: 40) else pw.SizedBox(height: 40),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: cream, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _pdfInfo('Report Year', _yearFilter ?? 'All Years'),
                  _pdfInfo(isUniversity ? 'Semester' : 'Term', _periodFilter ?? 'Overall'),
                  _pdfInfo('Total Tested Students', '${rows.length}'),
                  _pdfInfo('Overall School Average', '${schoolAverage.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            if (rows.isEmpty)
              pw.Center(child: pw.Text('No results found matching this filter.'))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Rank', 'Scholar ID', 'Name', 'Average Marks', 'Performance Band'],
                data: [
                  for (var i = 0; i < rows.length; i++)
                    [
                      '${i + 1}',
                      rows[i].student.id.toUpperCase(),
                      rows[i].student.name,
                      '${rows[i].average.toStringAsFixed(1)}%',
                      performanceBand(rows[i].average).label,
                    ],
                ],
                headerDecoration: pw.BoxDecoration(color: brown),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated on ${_today()}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                _pdfSignature('Dr. G. Phiri', 'AGE Africa Program Officer'),
              ],
            ),
          ],
        ),
      );

      final fileName = '${schoolName.replaceAll(' ', '_')}_Summary_${_yearFilter ?? 'AllYears'}.pdf';
      await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: fileName);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT — School summary (CSV / Excel)
  // ---------------------------------------------------------------------
  Future<void> _exportSchoolCsv() async {
    if (_selectedSchool == null) return;
    setState(() => _isExporting = true);
    try {
      final schoolName = _selectedSchool!;
      final students = kStudents.where((s) => s.schoolName == schoolName).toList();
      final isUniversity = students.isNotEmpty && students.first.schoolType == SchoolType.university;
      final rows = students
          .map((s) {
        final records = _resultsForStudent(s.id, year: _yearFilter, period: _periodFilter, isUniversity: isUniversity);
        return (student: s, average: _averageMarks(records), hasRecords: records.isNotEmpty);
      })
          .where((r) => r.hasRecords)
          .toList()
        ..sort((a, b) => b.average.compareTo(a.average));

      final csvRows = <List<dynamic>>[
        ['School', schoolName],
        ['Year', _yearFilter ?? 'All Years'],
        [isUniversity ? 'Semester' : 'Term', _periodFilter ?? 'Overall'],
        [],
        ['Rank', 'Scholar ID', 'Name', 'Average Marks', 'Performance Band'],
        for (var i = 0; i < rows.length; i++)
          [i + 1, rows[i].student.id.toUpperCase(), rows[i].student.name, rows[i].average.toStringAsFixed(1), performanceBand(rows[i].average).label],
      ];

      final csvData = const ListToCsvConverter().convert(csvRows);
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save School Summary as CSV',
        fileName: '${schoolName.replaceAll(' ', '_')}_Summary_${_yearFilter ?? 'AllYears'}.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School summary exported to CSV successfully.'), backgroundColor: kBrandOlive, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  static pw.Widget _pdfInfo(String label, String value) {
    return pw.SizedBox(
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ],
    );
  }

  static pw.Widget _pdfSignature(String name, String label) {
    return pw.Column(
      children: [
        pw.Text(name, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold)),
        pw.Container(width: 110, height: 0.6, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 3)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _mode == ReportMode.student ? _selectedStudentId != null : _selectedSchool != null;
    final periodOptions = _isUniversitySelection ? kSemesters : kTerms;

    // Wrapped in SingleChildScrollView so this component is safe to drop
    // directly into a Scaffold body (as in ReportCardsPage) without the
    // caller needing to add its own scroll view — prevents RenderFlex
    // overflow once a tall report card is rendered.
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: kBrandBrown.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        kAgeLogoAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const Icon(Icons.picture_as_pdf_rounded, color: kBrandBrown),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Academic Report Cards', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        SizedBox(height: 3),
                        Text('Generate official student transcripts and school summaries.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (hasSelection) ...[
                    OutlinedButton.icon(
                      onPressed: _isExporting ? null : (_mode == ReportMode.student ? _exportStudentCsv : _exportSchoolCsv),
                      icon: const Icon(Icons.grid_on_rounded, size: 18, color: kBrandBrown),
                      label: const Text('CSV / Excel', style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kBrandBrown.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : (_mode == ReportMode.student ? _exportStudentPdf : _exportSchoolPdf),
                      icon: _isExporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(_isExporting ? 'Exporting...' : 'Export PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandOlive,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode toggle
                  SegmentedButton<ReportMode>(
                    segments: const [
                      ButtonSegment(value: ReportMode.student, label: Text('Student Transcript'), icon: Icon(Icons.badge_outlined)),
                      ButtonSegment(value: ReportMode.school, label: Text('School Summary'), icon: Icon(Icons.apartment_outlined)),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _onModeChanged,
                    style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandOlive, selectedForegroundColor: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  if (_mode == ReportMode.student) ...[
                    // Select by school first, to narrow the student list
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedSchoolFilter,
                            isExpanded: true,
                            decoration: _fieldDecoration('Filter by School', Icons.school_outlined),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Schools')),
                              ..._schoolOptions.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (v) => setState(() {
                              _selectedSchoolFilter = v;
                              _selectedStudentId = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Autocomplete<Student>(
                            key: ValueKey(_selectedSchoolFilter),
                            displayStringForOption: (s) => s.name,
                            optionsBuilder: (textValue) {
                              final query = textValue.text.trim().toLowerCase();
                              final pool = _studentOptionsForSchool;
                              if (query.isEmpty) return pool;
                              return pool.where((s) => s.name.toLowerCase().contains(query));
                            },
                            onSelected: (s) {
                              setState(() {
                                _selectedStudentId = s.id;
                                _yearFilter = null;
                                _periodFilter = null;
                              });
                              _fetchResultsForStudent(s.id);
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 340,
                                    constraints: const BoxConstraints(maxHeight: 260),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final s = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          leading: Icon(Icons.person, color: kBrandOlive),
                                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(s.schoolName),
                                          onTap: () => onSelected(s),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: _fieldDecoration('Search for scholar...', Icons.search_rounded).copyWith(
                                  suffixIcon: controller.text.isEmpty
                                      ? null
                                      : IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() => _selectedStudentId = null);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Autocomplete<String>(
                      optionsBuilder: (textValue) {
                        final query = textValue.text.trim().toLowerCase();
                        if (query.isEmpty) return _schoolOptions;
                        return _schoolOptions.where((name) => name.toLowerCase().contains(query));
                      },
                      onSelected: (name) {
                        setState(() {
                          _selectedSchool = name;
                          _yearFilter = null;
                          _periodFilter = null;
                        });
                        _fetchResultsForSchool(name);
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 320,
                              constraints: const BoxConstraints(maxHeight: 260),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final name = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(Icons.apartment, color: kBrandBrown),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    onTap: () => onSelected(name),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _fieldDecoration('Search for school...', Icons.search_rounded).copyWith(
                            suffixIcon: controller.text.isEmpty
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                controller.clear();
                                setState(() => _selectedSchool = null);
                              },
                            ),
                          ),
                        );
                      },
                    ),

                  // Year / Term / Overall filters
                  if (hasSelection) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _yearFilter,
                            decoration: _fieldDecoration('Academic Year', Icons.event_outlined),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Years')),
                              ..._allYears().map((y) => DropdownMenuItem(value: y, child: Text(y))),
                            ],
                            onChanged: (v) => setState(() => _yearFilter = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _periodFilter,
                            decoration: _fieldDecoration(_isUniversitySelection ? 'Semester' : 'Term', Icons.calendar_view_week_outlined),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Overall (All Periods)')),
                              ...periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                            ],
                            onChanged: (v) => setState(() => _periodFilter = v),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Report body
                  if (!hasSelection)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.text_snippet_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _mode == ReportMode.student
                                  ? 'Filter by school and search for a scholar to generate their official transcript.'
                                  : 'Search for a school to generate school-wide exam results reports.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_isLoadingResults)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kBrandOlive)))
                  else if (_mode == ReportMode.student)
                    _StudentReportCard(studentId: _selectedStudentId!, year: _yearFilter, period: _periodFilter)
                  else
                    _SchoolReportCard(schoolName: _selectedSchool!, year: _yearFilter, period: _periodFilter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      prefixIcon: Icon(icon, size: 20),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// ---------------------------------------------------------------------
/// Student report card - Certificate/Official Transcript Style
/// ---------------------------------------------------------------------

class _StudentReportCard extends StatelessWidget {
  const _StudentReportCard({required this.studentId, this.year, this.period});

  final String studentId;
  final String? year;
  final String? period;

  @override
  Widget build(BuildContext context) {
    final student = kStudents.firstWhere((s) => s.id == studentId);
    final isUniversity = student.schoolType == SchoolType.university;
    final records = _resultsForStudent(studentId, year: year, period: period, isUniversity: isUniversity);
    final avgMarks = _averageMarks(records);
    final gpaRecords = records.where((r) => r.gpa != null).toList();
    final avgGpa = gpaRecords.isEmpty ? null : gpaRecords.map((r) => r.gpa!).reduce((a, b) => a + b) / gpaRecords.length;
    final totalPoints = records.where((r) => r.points != null).fold<double>(0, (sum, r) => sum + (r.points ?? 0));
    final position = _rankInSchool(studentId, student.schoolName, year: year, period: period);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        border: Border.all(color: const Color(0xFFC5A880), width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.schoolName.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  const Text('AGE Africa Education Scholarship Program',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC5A880), width: 2),
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Image.asset(
                  kAgeLogoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Icon(Icons.school_rounded, color: Color(0xFFC5A880)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFC5A880), thickness: 1.5),
          const SizedBox(height: 12),

          Center(
            child: Text(
              isUniversity ? 'OFFICIAL ACADEMIC TRANSCRIPT' : 'OFFICIAL ACADEMIC REPORT CARD',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF4A4A4A)),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _InfoLine(label: 'Full Name', value: student.name),
                _InfoLine(label: 'Scholar ID', value: student.id.toUpperCase()),
                _InfoLine(label: 'Scholar Age', value: '${student.age} Years'),
                _InfoLine(label: 'Institution Level', value: isUniversity ? 'University' : 'Secondary School'),
                _InfoLine(label: 'Academic Year', value: year ?? 'All Recorded Years'),
                _InfoLine(label: isUniversity ? 'Academic Semester' : 'School Term', value: period ?? 'Overall'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Text('No exam scores recorded for the selected query filters.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(kBrandBrown),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  dataRowColor: WidgetStateProperty.all(Colors.white),
                  columns: [
                    DataColumn(label: Text(isUniversity ? 'Course Name' : 'Subject Name')),
                    const DataColumn(label: Text('Marks'), numeric: true),
                    DataColumn(label: Text(isUniversity ? 'GPA' : 'Points'), numeric: true),
                    if (!isUniversity) const DataColumn(label: Text('Letter Grade')),
                    const DataColumn(label: Text('Year')),
                    DataColumn(label: Text(isUniversity ? 'Semester' : 'Term')),
                  ],
                  rows: records.map((r) {
                    return DataRow(cells: [
                      DataCell(Text(r.subject, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${r.marks.toStringAsFixed(0)}%')),
                      DataCell(Text(isUniversity ? (r.gpa ?? 0).toStringAsFixed(2) : (r.points ?? 0).toStringAsFixed(0))),
                      if (!isUniversity) DataCell(Text(_letterGrade(r.marks))),
                      DataCell(Text(r.year)),
                      DataCell(Text((isUniversity ? r.semester : r.term) ?? '-')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kBrandBrown, kBrandOlive], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 14,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _SummaryStat(label: 'Subjects Enrolled', value: '${records.length}'),
                  _SummaryStat(label: 'Average Score', value: '${avgMarks.toStringAsFixed(1)}%'),
                  if (isUniversity)
                    _SummaryStat(label: 'Cumulative GPA', value: (avgGpa ?? 0).toStringAsFixed(2))
                  else
                    _SummaryStat(label: 'Aggregate Points', value: totalPoints.toStringAsFixed(0)),
                  _SummaryStat(
                    label: 'Overall Grade',
                    value: isUniversity ? (avgGpa ?? 0).toStringAsFixed(2) : _letterGrade(avgMarks).split(' ')[0],
                  ),
                  _SummaryStat(label: 'School Ranking', value: position.rank == 0 ? '—' : '${position.rank} / ${position.total}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Academic Faculty Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(_remarkFor(avgMarks), style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Issued officially on ${_today()}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Row(
                  children: [
                    _SignatureLine(name: 'Prof. E. Chimphamba', label: isUniversity ? 'University Registrar' : 'Class Teacher'),
                    const SizedBox(width: 32),
                    _SignatureLine(name: 'Dr. M. Nyasulu', label: isUniversity ? 'Dean of Academics' : 'Head Teacher'),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SchoolReportCard extends StatelessWidget {
  const _SchoolReportCard({required this.schoolName, this.year, this.period});

  final String schoolName;
  final String? year;
  final String? period;

  @override
  Widget build(BuildContext context) {
    final students = kStudents.where((s) => s.schoolName == schoolName).toList();
    final isUniversity = students.isNotEmpty && students.first.schoolType == SchoolType.university;

    final rows = students.map((s) {
      final records = _resultsForStudent(s.id, year: year, period: period, isUniversity: isUniversity);
      final avg = _averageMarks(records);
      return (student: s, records: records, average: avg);
    }).where((r) => r.records.isNotEmpty).toList()
      ..sort((a, b) => b.average.compareTo(a.average));

    final schoolAverage = rows.isEmpty ? 0.0 : rows.map((r) => r.average).reduce((a, b) => a + b) / rows.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFFBFDFA), border: Border.all(color: kBrandOlive, width: 2), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: kBrandCream, shape: BoxShape.circle),
                child: Image.asset(
                  kAgeLogoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Icon(Icons.apartment_rounded, color: kBrandBrown, size: 18),
                ),
              ),
              Flexible(
                child: Column(
                  children: [
                    Text(schoolName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 4),
                    const Text('SCHOOL EXAM RESULTS SUMMARY REPORT',
                        style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1.2),
          const SizedBox(height: 12),

          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _InfoLine(label: 'Report Year', value: year ?? 'All Years'),
              _InfoLine(label: isUniversity ? 'Semester' : 'Term', value: period ?? 'Overall'),
              _InfoLine(label: 'Total Tested Students', value: '${rows.length}'),
              _InfoLine(label: 'Overall School Average', value: '${schoolAverage.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 20),

          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No results found matching this filter query.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(kBrandCream),
                  columns: const [
                    DataColumn(label: Text('Rank', style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Student ID', style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Student Name', style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Average Marks', style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Performance Band', style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(rows.length, (index) {
                    final r = rows[index];
                    final band = performanceBand(r.average);
                    return DataRow(cells: [
                      DataCell(Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(r.student.id.toUpperCase())),
                      DataCell(Text(r.student.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${r.average.toStringAsFixed(1)}%')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: band.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(band.label, style: TextStyle(color: band.color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Generated on ${_today()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                _SignatureLine(name: 'Dr. G. Phiri', label: 'AGE Africa Program Officer'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Reusable helper blocks
/// ---------------------------------------------------------------------

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.name, required this.label});

  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 14, fontFamily: 'Courier', fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: kBrandBrown),
        ),
        Container(width: 140, height: 1, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(vertical: 4)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ],
    );
  }
}