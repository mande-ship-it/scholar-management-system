
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'academics_utils.dart';
import '../services/api_service.dart';

// ============================================================
// Brand palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);
const Color kBrandInk = Color(0xFF2E2620);
const Color kSurfaceMuted = Color(0xFFF7F6F2);

const Color kConfidenceHigh = Color(0xFF3F8F52);
const Color kConfidenceMedium = Color(0xFFC98A1E);
const Color kConfidenceLow = Color(0xFFC94A3A);

// ============================================================
// AcademicsManagementComponent — shell / header
// ============================================================
class AcademicsManagementComponent extends StatefulWidget {
  const AcademicsManagementComponent({super.key});

  @override
  State<AcademicsManagementComponent> createState() => _AcademicsManagementComponentState();
}

class _AcademicsManagementComponentState extends State<AcademicsManagementComponent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: 18),
        const Expanded(child: _EnterResultsSection()),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrandOlive, Color(0xFF7F9A29)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: kBrandOlive.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Academic Results",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
                ),
                SizedBox(height: 3),
                Text(
                  "Record scholar exam results per term or semester — manually, or by importing a document.",
                  style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION: ENTER RESULTS
// ============================================================

class _EnterResultsSection extends StatefulWidget {
  const _EnterResultsSection();

  @override
  State<_EnterResultsSection> createState() => _EnterResultsSectionState();
}

class _EnterResultsSectionState extends State<_EnterResultsSection> {
  SchoolType _schoolType = SchoolType.secondary;
  String? _selectedSchool;
  Student? _selectedStudent;

  late String _selectedYear;
  String? _selectedPeriod;

  List<_ScholarResultEntry> _scholarEntries = [];
  bool _isImporting = false;
  String? _importSourceLabel;
  bool _isLoading = false;

  bool get _isUniversity => _schoolType == SchoolType.university;

  @override
  void initState() {
    super.initState();
    _selectedYear = academicYearOptions().first;
    _scholarEntries.add(_ScholarResultEntry());
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final scholarsRes = await ApiService.getAllScholars();
      if (scholarsRes.statusCode == 200) {
        final List<dynamic> data = scholarsRes.data['data'];
        kStudents.clear();
        for (var item in data) {
          kStudents.add(Student(
            id: item['id'].toString(),
            scholarId: item['scholar_id'] ?? 'N/A',
            name: item['full_name'] ?? 'N/A',
            age: item['age'] != null ? int.parse(item['age'].toString()) : 18,
            schoolType: item['school_type'].toString().toLowerCase() == 'university'
                ? SchoolType.university
                : SchoolType.secondary,
            schoolName: item['school_name'] ?? 'N/A',
            status: item['status'] ?? 'Active',
            district: item['district'] ?? '',
            village: item['village'] ?? '',
            donor: item['donor'] ?? 'General Fund',
            phone: item['phone'] ?? '',
            email: item['email'] ?? '',
            programType: item['program_type'] ?? '',
            programName: item['program_name'] ?? '',
            previousSchool: item['previous_school'] ?? '',
            startYear: item['start_year'] ?? '2026',
            endYear: item['end_year'] ?? '2030',
          ));
        }
      }

      final subjectsRes = await ApiService.getSubjects();
      if (subjectsRes.statusCode == 200) {
        final List<dynamic> data = subjectsRes.data['data'];
        kSubjects.clear();
        for (var item in data) {
          kSubjects.add(Subject(
            name: item['name'],
            code: item['code'],
            details: item['details'] ?? '',
            notes: item['notes'] ?? '',
            level: item['level'].toString().toLowerCase() == 'university'
                ? SubjectLevel.university
                : SubjectLevel.secondary,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var e in _scholarEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _onSchoolTypeChanged(SchoolType type) {
    setState(() {
      _schoolType = type;
      _selectedSchool = null;
      _selectedStudent = null;
      _selectedPeriod = null;
      _resetData();
    });
  }

  void _resetData() {
    for (var e in _scholarEntries) {
      e.dispose();
    }
    _scholarEntries = [_ScholarResultEntry()];
    _importSourceLabel = null;
  }

  List<String> get _schoolOptions {
    final students = kStudents.where((s) => s.schoolType == _schoolType).toList();
    return students.map((s) => s.schoolName).toSet().toList()..sort();
  }

  List<Subject> get _subjectOptions {
    final level = _isUniversity ? SubjectLevel.university : SubjectLevel.secondary;
    return kSubjects.where((s) => s.level == level).toList();
  }

  List<String> get _periodOptions => _isUniversity ? kSemesters : kTerms;

  String _codeFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'GEN101';
    final words = trimmed.split(RegExp(r'\s+'));
    String base;
    if (words.length >= 2) {
      base = (words[0].substring(0, 1) + words[1].substring(0, words[1].length < 3 ? words[1].length : 3)).toUpperCase();
    } else {
      base = trimmed.substring(0, trimmed.length < 4 ? trimmed.length : 4).toUpperCase();
    }
    while (base.length < 3) {
      base += 'X';
    }
    return '${base}101';
  }

  // ================================================================
  // IMPORT PIPELINE — any document in → structured candidates →
  // Review & Correct dialog → applied to the entry rows.
  // Supported: .csv .txt .xlsx .xls .pdf .docx
  // ================================================================
  Future<void> _startImportPipeline() async {
    if (_selectedStudent == null) {
      _showSnack('Select a scholar before importing a results document.', isError: true);
      return;
    }
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Results Document',
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt', 'xlsx', 'xls', 'pdf', 'docx'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      final file = result.files.single;
      final extraction = await ResultDocumentImporter.extract(file);

      if (extraction.lines.isEmpty) {
        _showSnack('Could not find any readable subject/marks data in "${file.name}".', isError: true);
        return;
      }

      final candidates = SmartResultParser.parse(extraction.lines, _subjectOptions);

      if (candidates.isEmpty) {
        _showSnack('"${file.name}" was read, but no subject/marks pairs could be detected. Try Review & Correct manually, or check the file format.', isError: true);
        return;
      }

      if (!mounted) return;
      final approved = await showDialog<List<ImportCandidate>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ImportReviewDialog(
          candidates: candidates,
          knownSubjects: _subjectOptions,
          isUniversity: _isUniversity,
          sourceFileName: file.name,
        ),
      );

      if (approved == null || approved.isEmpty) return;

      final imported = approved.map((c) {
        final entry = _ScholarResultEntry();
        entry.subjectController.text = c.matchedSubject?.name ?? c.subjectRaw.trim();
        entry.marksController.text = c.marksRaw.trim();
        return entry;
      }).toList();

      final capped = (!_isUniversity && imported.length > 12) ? imported.sublist(0, 12) : imported;

      setState(() {
        for (var e in _scholarEntries) {
          e.dispose();
        }
        _scholarEntries = capped;
        _importSourceLabel = file.name;
      });
      _showSnack('Imported ${capped.length} result(s) from "${file.name}". Review the figures below, then record.', isError: false);
    } catch (e) {
      _showSnack('Could not read that document. It may be corrupted, password-protected, or an unsupported layout.', isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _saveAll() async {
    if (_selectedStudent == null || _selectedPeriod == null) {
      _showSnack('Please select a scholar and a ${_isUniversity ? 'semester' : 'term'}.', isError: true);
      return;
    }

    final validEntries = _scholarEntries
        .where((e) => e.subjectController.text.trim().isNotEmpty && e.marksController.text.trim().isNotEmpty)
        .toList();

    if (!_isUniversity) {
      if (validEntries.length < 6 || validEntries.length > 12) {
        _showSnack('For secondary school, please enter between 6 and 12 subjects.', isError: true);
        return;
      }
    } else {
      if (validEntries.isEmpty) {
        _showSnack('Please enter at least one course result.', isError: true);
        return;
      }
    }

    final resultsPayload = validEntries.map((e) {
      return {
        'subjectName': e.subjectController.text.trim(),
        'marks': double.parse(e.marksController.text.trim()),
      };
    }).toList();

    final payload = {
      'scholarId': int.parse(_selectedStudent!.id),
      'results': resultsPayload,
      'year': int.parse(_selectedYear),
      'schoolType': _isUniversity ? 'University' : 'Secondary',
      if (_isUniversity) 'semester': _selectedPeriod else 'term': _selectedPeriod,
    };

    setState(() => _isImporting = true);
    try {
      final response = await ApiService.recordResults(payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        int savedCount = validEntries.length;
        String message = 'Saved $savedCount result(s) for ${_selectedStudent!.name}.';
        
        if (_isUniversity && _selectedPeriod == 'Semester 2') {
          final s1 = kResults.where((r) => r.studentId == _selectedStudent!.id && r.year == _selectedYear && r.semester == 'Semester 1').toList();
          final s2 = validEntries.map((e) => ResultRecord(
            studentId: _selectedStudent!.id,
            code: _codeFromName(e.subjectController.text),
            subject: e.subjectController.text.trim(),
            marks: double.parse(e.marksController.text.trim()),
            gpa: gradeFromMarks(double.parse(e.marksController.text.trim()), isUniversity: true).point,
            year: _selectedYear,
            semester: _selectedPeriod,
          )).toList();
          if (s1.isNotEmpty && s2.isNotEmpty) {
            final annual = calculateAnnualGpa(s1, s2);
            message += ' Annual GPA for $_selectedYear: ${annual.toStringAsFixed(2)}.';
          }
        }
        
        _showSnack(message, isError: false);
        setState(() {
          _resetData();
          _selectedStudent = null;
          _selectedPeriod = null;
        });
      } else {
        _showSnack('Failed to record results: ${response.data['message'] ?? 'Unknown error'}', isError: true);
      }
    } catch (e) {
      _showSnack('Failed to record results: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _updateOrAddResult({
    required String studentId,
    required String code,
    required String name,
    required double marks,
    required String year,
    required String period,
  }) {
    final graded = gradeFromMarks(marks, isUniversity: _isUniversity);

    final index = kResults.indexWhere(
          (r) => r.studentId == studentId && r.subject.toLowerCase() == name.toLowerCase() && r.year == year && (_isUniversity ? r.semester == period : r.term == period),
    );

    final record = ResultRecord(
      studentId: studentId,
      code: code,
      subject: name,
      marks: marks,
      gpa: _isUniversity ? graded.point : null,
      points: !_isUniversity ? graded.point : null,
      year: year,
      term: !_isUniversity ? period : null,
      semester: _isUniversity ? period : null,
    );

    if (index != -1) {
      kResults[index] = record;
    } else {
      kResults.add(record);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? kBrandOrange : kBrandOlive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: kBrandOlive),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepLabel(step: 1, label: "Select Scholar & Period"),
          const SizedBox(height: 10),
          _buildFilterCard(),
          const SizedBox(height: 22),
          _StepLabel(step: 2, label: "Add Results"),
          const SizedBox(height: 10),
          _buildImportBanner(),
          const SizedBox(height: 12),
          _buildEntrySection(),
          const SizedBox(height: 24),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildImportBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.file_present_rounded, color: kBrandOlive, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Import from a document", style: TextStyle(fontWeight: FontWeight.w700, color: kBrandInk, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  _importSourceLabel != null
                      ? 'Last import: $_importSourceLabel'
                      : 'Upload a marksheet as CSV, Excel, PDF, or Word — we detect subjects and marks, then you review before saving.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isImporting ? null : _startImportPipeline,
            icon: _isImporting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kBrandBrown))
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(_isImporting ? 'Reading…' : 'Upload Document'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kBrandBrown,
              side: const BorderSide(color: kBrandBrown),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveAll,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Record Results', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    final years = academicYearOptions();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_rounded, size: 18, color: kBrandOlive),
              const SizedBox(width: 8),
              const Text("Scholar Selection", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kBrandBrown)),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<SchoolType>(
                  initialValue: _schoolType,
                  decoration: _inputDeco("School Type", Icons.category_outlined),
                  items: const [
                    DropdownMenuItem(value: SchoolType.secondary, child: Text('Secondary')),
                    DropdownMenuItem(value: SchoolType.university, child: Text('University')),
                  ],
                  onChanged: (v) => _onSchoolTypeChanged(v!),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSchool,
                  isExpanded: true,
                  decoration: _inputDeco("Select School", Icons.apartment_rounded),
                  items: _schoolOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() {
                    _selectedSchool = v;
                    _selectedStudent = null;
                  }),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<Student>(
                  initialValue: _selectedStudent,
                  isExpanded: true,
                  decoration: _inputDeco("Select Scholar", Icons.badge_outlined),
                  items: kStudents
                      .where((s) => s.schoolType == _schoolType && (_selectedSchool == null || s.schoolName == _selectedSchool))
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudent = v),
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: years.contains(_selectedYear) ? _selectedYear : years.first,
                  decoration: _inputDeco("Academic Year", Icons.calendar_today_rounded),
                  items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPeriod,
                  decoration: _inputDeco(_isUniversity ? "Semester" : "Term", Icons.event_note_rounded),
                  items: _periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _selectedPeriod = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntrySection() {
    if (_selectedStudent == null) {
      return _buildPlaceholder(Icons.person_search_rounded, "Select a scholar to enter their results.");
    }
    if (_selectedPeriod == null) {
      return _buildPlaceholder(Icons.event_note_rounded, "Select a ${_isUniversity ? 'semester' : 'term'} to continue.");
    }

    List<ResultRecord> currentResults = [];
    for (var entry in _scholarEntries) {
      final marks = double.tryParse(entry.marksController.text);
      if (marks != null) {
        final graded = gradeFromMarks(marks, isUniversity: _isUniversity);
        currentResults.add(ResultRecord(
          studentId: _selectedStudent!.id,
          code: '',
          subject: entry.subjectController.text,
          marks: marks,
          gpa: _isUniversity ? graded.point : null,
          points: !_isUniversity ? graded.point : null,
          year: _selectedYear,
        ));
      }
    }

    final outcome = _isUniversity ? calculateUniversityOutcome(currentResults) : calculateSecondaryOutcome(currentResults);

    double? annualGpa;
    if (_isUniversity && _selectedPeriod == 'Semester 2') {
      final semester1Saved = kResults.where((r) => r.studentId == _selectedStudent!.id && r.year == _selectedYear && r.semester == 'Semester 1').toList();
      if (semester1Saved.isNotEmpty) {
        annualGpa = calculateAnnualGpa(semester1Saved, currentResults);
      }
    }

    return Column(
      children: [
        _buildOutcomeCard(outcome, annualGpa),
        const SizedBox(height: 16),
        ..._scholarEntries.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ScholarEntryRow(
              entry: item,
              subjects: _subjectOptions,
              onRemove: _scholarEntries.length > 1 ? () => setState(() => _scholarEntries.removeAt(index)) : null,
              isUniversity: _isUniversity,
              onChanged: () => setState(() {}),
            ),
          );
        }),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => setState(() => _scholarEntries.add(_ScholarResultEntry())),
          icon: const Icon(Icons.add, size: 18),
          label: Text(_isUniversity ? "Add Another Course" : "Add Another Subject"),
          style: OutlinedButton.styleFrom(
            foregroundColor: kBrandOlive,
            side: const BorderSide(color: kBrandOlive),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isUniversity ? "Enter at least one course for this semester." : "Enter between 6 and 12 subjects for this term.",
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildOutcomeCard(dynamic outcome, double? annualGpa) {
    final String statusLabel = _isUniversity ? outcome.status as String : (outcome.passed as bool ? 'PASS' : 'FAIL');
    final bool isGoodStanding = _isUniversity ? statusLabel != 'Fail' && statusLabel != 'N/A' : outcome.passed as bool;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrandCream, kBrandCreamDark],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBrandCreamDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.analytics_rounded, color: kBrandBrown, size: 18),
              ),
              const SizedBox(width: 12),
              if (_isUniversity)
                Expanded(
                  child: Text(
                    "Semester Total: ${outcome.totalMarks.toStringAsFixed(0)}  •  Avg GPA: ${outcome.avgGpa.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandBrown, fontSize: 13),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    "Best Six: Total Marks ${outcome.totalMarks.toStringAsFixed(0)}  •  Total Points ${outcome.totalPoints.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandBrown, fontSize: 13),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isGoodStanding ? kBrandOlive : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          if (annualGpa != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_view_month_rounded, size: 16, color: kBrandBrown),
                const SizedBox(width: 8),
                Text(
                  "Projected Annual GPA (Sem 1 + Sem 2, $_selectedYear): ${annualGpa.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandBrown, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown),
      isDense: true,
      filled: true,
      fillColor: kSurfaceMuted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }
}

// ============================================================
// Small "Step N" label used above each section
// ============================================================
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.step, required this.label});
  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: kBrandBrown, shape: BoxShape.circle),
          child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kBrandInk, letterSpacing: 0.2)),
      ],
    );
  }
}

class _ScholarResultEntry {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController marksController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    marksController.dispose();
  }
}

class _ScholarEntryRow extends StatelessWidget {
  const _ScholarEntryRow({required this.entry, required this.subjects, this.onRemove, required this.isUniversity, required this.onChanged});

  final _ScholarResultEntry entry;
  final List<Subject> subjects;
  final VoidCallback? onRemove;
  final bool isUniversity;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final marks = double.tryParse(entry.marksController.text);
    final graded = marks != null ? gradeFromMarks(marks, isUniversity: isUniversity) : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<Subject>(
              optionsBuilder: (textValue) {
                if (textValue.text.isEmpty) return subjects;
                return subjects.where((s) => s.name.toLowerCase().contains(textValue.text.toLowerCase()));
              },
              displayStringForOption: (s) => s.name,
              onSelected: (s) {
                entry.subjectController.text = s.name;
                onChanged();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text != entry.subjectController.text) {
                  controller.text = entry.subjectController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: (v) => onFieldSubmitted(),
                  decoration: InputDecoration(
                    labelText: isUniversity ? "Course Name" : "Subject Name",
                    border: const OutlineInputBorder(),
                    helperText: "Type the subject name",
                    isDense: true,
                  ),
                  onChanged: (v) {
                    entry.subjectController.text = v;
                    onChanged();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: entry.marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Marks (0-100)", border: OutlineInputBorder(), isDense: true),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: kBrandCream, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  graded?.letter ?? '—',
                  style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: (graded?.letter.length ?? 0) > 6 ? 10 : 12),
                  textAlign: TextAlign.center,
                ),
                if (graded != null)
                  Text(
                    isUniversity ? "GPA: ${graded.point.toStringAsFixed(2)}" : "Points: ${graded.point.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 9, color: kBrandBrown, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.delete_outline, color: kBrandOrange), onPressed: onRemove),
          ]
        ],
      ),
    );
  }
}

// ================================================================================
// DOCUMENT IMPORT — extraction layer
// Every supported format is normalized down to a flat List<String> of lines
// (or "subject <sep> marks" rows), which SmartResultParser then reads.
// ================================================================================

class ExtractedDocument {
  final List<String> lines;
  final String sourceType;
  ExtractedDocument(this.lines, this.sourceType);
}

class ResultDocumentImporter {
  static Future<ExtractedDocument> extract(PlatformFile file) async {
    final ext = (file.extension ?? '').toLowerCase();
    final bytes = file.bytes!;

    switch (ext) {
      case 'csv':
      case 'txt':
        return ExtractedDocument(_fromDelimitedText(bytes), ext);
      case 'xlsx':
      case 'xls':
        return ExtractedDocument(_fromExcel(bytes), 'excel');
      case 'pdf':
        return ExtractedDocument(_fromPdf(bytes), 'pdf');
      case 'docx':
        return ExtractedDocument(_fromDocx(bytes), 'docx');
      default:
        throw UnsupportedError('Unsupported file type: $ext');
    }
  }

  static List<String> _fromDelimitedText(Uint8List bytes) {
    final raw = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(raw);
    return rows.map((r) => r.map((c) => c.toString().trim()).where((c) => c.isNotEmpty).join('  |  ')).where((l) => l.isNotEmpty).toList();
  }

  static List<String> _fromExcel(Uint8List bytes) {
    final book = xls.Excel.decodeBytes(bytes);
    final lines = <String>[];
    for (final sheetName in book.tables.keys) {
      final sheet = book.tables[sheetName];
      if (sheet == null) continue;
      for (final row in sheet.rows) {
        final cells = row.where((c) => c != null).map((c) => c!.value.toString().trim()).where((v) => v.isNotEmpty).toList();
        if (cells.isNotEmpty) lines.add(cells.join('  |  '));
      }
    }
    return lines;
  }

  static List<String> _fromPdf(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(doc).extractText();
    doc.dispose();
    return text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  static List<String> _fromDocx(Uint8List bytes) {
    final text = docxToText(bytes);
    return text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }
}

// ================================================================================
// SMART PARSER — turns raw lines/rows into (subject, marks) candidates
// with a confidence rating, so the reviewer knows what to double-check.
// ================================================================================

enum ImportConfidence { high, medium, low }

class ImportCandidate {
  String subjectRaw;
  String marksRaw;
  Subject? matchedSubject;
  ImportConfidence confidence;
  String? issue;
  bool include;

  ImportCandidate({
    required this.subjectRaw,
    required this.marksRaw,
    this.matchedSubject,
    required this.confidence,
    this.issue,
    this.include = true,
  });
}

class SmartResultParser {
  static final _headerWords = {'subject', 'course', 'marks', 'mark', 'score', 'grade', 'title', 'name', 'total', 'points', 'gpa'};

  // Matches "Subject Name  <sep>  85"  or  "Subject Name 85%"  at end of line.
  static final _trailingNumberPattern = RegExp(r'^(.*?)[\s\-:|,]{1,4}(\d{1,3}(?:\.\d+)?)\s*%?$');

  static List<ImportCandidate> parse(List<String> lines, List<Subject> knownSubjects) {
    final candidates = <ImportCandidate>[];

    for (final rawLine in lines) {
      final line = rawLine.replaceAll('|', ' ').trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();
      final isLikelyHeader = _headerWords.any((w) => lower == w || lower.startsWith('$w ') || lower == '$w,');
      if (isLikelyHeader && line.length < 40) continue;

      final match = _trailingNumberPattern.firstMatch(line);
      if (match == null) continue;

      var subjectRaw = match.group(1)!.trim();
      final marksRaw = match.group(2)!.trim();
      subjectRaw = subjectRaw.replaceAll(RegExp(r'^[\d\.\)\-\s]+'), '').trim(); // strip leading row numbers

      if (subjectRaw.isEmpty) continue;
      final marks = double.tryParse(marksRaw);
      if (marks == null) continue;

      String? issue;
      ImportConfidence confidence;
      Subject? matched = _matchSubject(subjectRaw, knownSubjects);

      if (marks < 0 || marks > 100) {
        confidence = ImportConfidence.low;
        issue = 'Marks out of expected 0–100 range';
      } else if (matched != null && matched.name.toLowerCase() == subjectRaw.toLowerCase()) {
        confidence = ImportConfidence.high;
      } else if (matched != null) {
        confidence = ImportConfidence.medium;
        issue = 'Matched by similarity to "${matched.name}" — please confirm';
      } else {
        confidence = ImportConfidence.medium;
        issue = 'No matching subject on file — will be added as new';
      }

      candidates.add(ImportCandidate(
        subjectRaw: subjectRaw,
        marksRaw: marksRaw,
        matchedSubject: matched,
        confidence: confidence,
        issue: issue,
      ));
    }

    // De-duplicate on subject name, keeping the highest-confidence hit.
    final seen = <String, ImportCandidate>{};
    for (final c in candidates) {
      final key = c.subjectRaw.toLowerCase();
      if (!seen.containsKey(key) || c.confidence.index < seen[key]!.confidence.index) {
        seen[key] = c;
      }
    }
    return seen.values.toList();
  }

  static Subject? _matchSubject(String raw, List<Subject> known) {
    final normalized = raw.toLowerCase().trim();
    for (final s in known) {
      if (s.name.toLowerCase() == normalized) return s;
    }
    for (final s in known) {
      final sName = s.name.toLowerCase();
      if (sName.contains(normalized) || normalized.contains(sName)) return s;
    }
    return null;
  }
}

// ================================================================================
// REVIEW & CORRECT DIALOG
// A dedicated, professional data-correction surface shown after every
// document import — nothing reaches the entry list without passing through here.
// ================================================================================

class ImportReviewDialog extends StatefulWidget {
  const ImportReviewDialog({
    super.key,
    required this.candidates,
    required this.knownSubjects,
    required this.isUniversity,
    required this.sourceFileName,
  });

  final List<ImportCandidate> candidates;
  final List<Subject> knownSubjects;
  final bool isUniversity;
  final String sourceFileName;

  @override
  State<ImportReviewDialog> createState() => _ImportReviewDialogState();
}

class _ImportReviewDialogState extends State<ImportReviewDialog> {
  late List<ImportCandidate> _rows;
  late List<TextEditingController> _subjectCtrls;
  late List<TextEditingController> _marksCtrls;

  @override
  void initState() {
    super.initState();
    _rows = widget.candidates;
    _subjectCtrls = _rows.map((c) => TextEditingController(text: c.matchedSubject?.name ?? c.subjectRaw)).toList();
    _marksCtrls = _rows.map((c) => TextEditingController(text: c.marksRaw)).toList();
  }

  @override
  void dispose() {
    for (final c in _subjectCtrls) {
      c.dispose();
    }
    for (final c in _marksCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  int get _highCount => _rows.where((r) => r.confidence == ImportConfidence.high).length;
  int get _needsReviewCount => _rows.where((r) => r.confidence != ImportConfidence.high).length;

  void _removeRow(int i) {
    setState(() {
      _rows.removeAt(i);
      _subjectCtrls.removeAt(i).dispose();
      _marksCtrls.removeAt(i).dispose();
    });
  }

  void _apply() {
    final result = <ImportCandidate>[];
    for (int i = 0; i < _rows.length; i++) {
      if (!_rows[i].include) continue;
      final subject = _subjectCtrls[i].text.trim();
      final marks = _marksCtrls[i].text.trim();
      if (subject.isEmpty || marks.isEmpty) continue;
      final row = _rows[i];
      row.subjectRaw = subject;
      row.marksRaw = marks;
      result.add(row);
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildSummaryBar(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kBrandBrown, Color(0xFF3A2E26)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text("Review & Correct Import", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16.5)),
              const SizedBox(height: 3),
              Text("Detected from \"${widget.sourceFileName}\" — edit anything before it's applied.",
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    ),
    IconButton(
    icon: const Icon(Icons.close_rounded, color: Colors.white70),
    onPressed: () => Navigator.of(context).pop(null),
    ),
    ],
    ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      color: kSurfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: Row(
        children: [
          _confidenceChip(ImportConfidence.high, '$_highCount look correct'),
          const SizedBox(width: 10),
          _confidenceChip(ImportConfidence.medium, '$_needsReviewCount need a check', forceOrange: _needsReviewCount > 0),
          const Spacer(),
          Text('${_rows.length} row(s) detected', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _confidenceChip(ImportConfidence level, String label, {bool forceOrange = false}) {
    final color = forceOrange ? kConfidenceMedium : (level == ImportConfidence.high ? kConfidenceHigh : kConfidenceMedium);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_rows.isEmpty) {
      return Center(
        child: Text('No rows remaining — cancel and re-import if needed.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildRow(i),
    );
  }

  Widget _buildRow(int i) {
    final row = _rows[i];
    final color = row.confidence == ImportConfidence.high
        ? kConfidenceHigh
        : row.confidence == ImportConfidence.medium
        ? kConfidenceMedium
        : kConfidenceLow;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: row.include ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4), top: BorderSide(color: Colors.grey.shade200), right: BorderSide(color: Colors.grey.shade200), bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: row.include,
                activeColor: kBrandOlive,
                onChanged: (v) => setState(() => row.include = v ?? true),
              ),
              Expanded(
                flex: 3,
                child: Autocomplete<Subject>(
                  optionsBuilder: (t) => t.text.isEmpty
                      ? widget.knownSubjects
                      : widget.knownSubjects.where((s) => s.name.toLowerCase().contains(t.text.toLowerCase())),
                  displayStringForOption: (s) => s.name,
                  onSelected: (s) {
                    _subjectCtrls[i].text = s.name;
                    setState(() {
                      row.matchedSubject = s;
                      row.confidence = ImportConfidence.high;
                      row.issue = null;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    if (controller.text != _subjectCtrls[i].text) controller.text = _subjectCtrls[i].text;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: row.include,
                      decoration: const InputDecoration(labelText: 'Subject', isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) => _subjectCtrls[i].text = v,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _marksCtrls[i],
                  enabled: row.include,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Marks', isDense: true, border: OutlineInputBorder()),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: kBrandOrange, size: 20),
                onPressed: () => _removeRow(i),
                tooltip: 'Remove row',
              ),
            ],
          ),
          if (row.issue != null && row.include) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: color),
                  const SizedBox(width: 5),
                  Expanded(child: Text(row.issue!, style: TextStyle(fontSize: 11, color: color, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel Import', style: TextStyle(color: Colors.grey)),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _rows.isEmpty ? null : _apply,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Apply ${_rows.where((r) => r.include).length} Result(s)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ],
      ),
    );
  }
}