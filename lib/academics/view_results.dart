import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);
const Color kSurfaceMuted = Color(0xFFF7F6F2);

String _initialsOf(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

/// -------------------------------------------------------

class ViewResultsComponent extends StatefulWidget {
  final VoidCallback? onEnterResults;
  final VoidCallback? onViewPerformance;
  final VoidCallback? onViewReports;

  const ViewResultsComponent({
    super.key, 
    this.onEnterResults,
    this.onViewPerformance,
    this.onViewReports,
  });

  @override
  State<ViewResultsComponent> createState() => _ViewResultsComponentState();
}

class _ViewResultsComponentState extends State<ViewResultsComponent> {
  final TextEditingController _searchController = TextEditingController();

  SchoolType? _schoolTypeFilter; // null = All
  String? _schoolNameFilter; // null = All
  String? _selectedYearFilter; // To filter the result count in the list
  bool _isExportingRoster = false;
  bool _isLoading = false;

  final List<String> _academicYears = academicYearOptions();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final scholarsRes = await ApiService.getAllScholars();
      if (scholarsRes.statusCode != null && scholarsRes.statusCode! < 400) {
        final List<dynamic> data = scholarsRes.data['data'] ?? [];
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
            schoolName: item['display_school_name'] ?? 'N/A',
            status: item['status'] ?? 'Active',
            district: item['district'] ?? '',
            village: item['village'] ?? '',
            donor: item['donor'] ?? 'General Fund',
            phone: item['phone'] ?? '',
            email: item['email'] ?? '',
            programType: item['program_type'] ?? '',
            programName: item['program_name'] ?? '',
            previousSchool: item['previous_school'] ?? '',
            startYear: item['start_year']?.toString() ?? '2026',
            endYear: item['end_year']?.toString() ?? '2030',
          ));
        }
      }

      final resultsRes = await ApiService.getResultsByScholar('');
      if (resultsRes.statusCode != null && resultsRes.statusCode! < 400) {
        final List<dynamic> data = resultsRes.data['data'] ?? [];
        kResults.clear();
        for (var item in data) {
          kResults.add(ResultRecord(
            studentId: item['scholar_id'].toString(),
            code: item['subject_code'] ?? 'N/A',
            subject: item['subject_name'] ?? 'N/A',
            marks: double.parse(item['marks'].toString()),
            gpa: item['gpa'] != null ? double.parse(item['gpa'].toString()) : null,
            points: item['points'] != null ? double.parse(item['points'].toString()) : null,
            year: (item['academic_year'] ?? item['year'] ?? '').toString(),
            term: item['term'],
            semester: item['semester'],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading view results data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      barrierColor: Colors.black.withOpacity(0.5),
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
        color: kBrandBrown.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kBrandBrown),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kBrandBrown),
          ),
        ],
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
    final students = _filteredStudents;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBrandBrown.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: kBrandBrown,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "View Results",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Monitor scholar performance and download rosters.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: widget.onViewPerformance,
                      icon: const Icon(Icons.insights_rounded, size: 16),
                      label: const Text("Performance"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBrown,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onViewReports,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text("Report Cards"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandOrange,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onEnterResults != null) {
                          widget.onEnterResults!();
                        } else {
                          Navigator.pushNamed(context, '/academics/enterResults');
                        }
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text("Enter Results"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandOlive,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                _isExportingRoster
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kBrandBrown),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: kBrandBrown, size: 18),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _exportRosterCsv,
                    tooltip: "Export Roster (CSV)",
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: kBrandBrown, size: 18),
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
          const Divider(height: 32),
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
                    color: Colors.black.withOpacity(0.03),
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
                        fillColor: Colors.white,
                        labelText: "Search Scholar Name",
                        hintText: "Enter name...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _searchController.clear();
                          }),
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
                        fillColor: Colors.white,
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
                        fillColor: Colors.white,
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
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedYearFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Result Year",
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
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
                        const DropdownMenuItem(value: null, child: Text('All Years')),
                        ..._academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))),
                      ],
                      onChanged: (v) => setState(() => _selectedYearFilter = v),
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
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: students.isEmpty
                    ? _buildNoResultsState()
                    : _buildScholarList(students),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialGuidance() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kBrandOlive.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apartment_rounded, size: 48, color: kBrandOlive),
            ),
            const SizedBox(height: 24),
            const Text(
              "Select a Partner Institution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose an institution from the filters above to view and audit scholar examination results.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
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
    );
  }

  Widget _buildScholarList(List<Student> students) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: students.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100, indent: 84),
      itemBuilder: (context, index) {
        final student = students[index];
        final resultCount = kResults.where((r) {
          final matchesId = r.studentId == student.id;
          final matchesYear = _selectedYearFilter == null || r.year == _selectedYearFilter;
          return matchesId && matchesYear;
        }).length;
        
        final isUniversity = student.schoolType == SchoolType.university;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openStudentResults(student),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kBrandOlive.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: kBrandOlive.withOpacity(0.2)),
                    ),
                    child: Text(
                      _initialsOf(student.name),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(student.name, 
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kBrandBrown, letterSpacing: -0.2)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUniversity ? Colors.blue.withOpacity(0.08) : kBrandOrange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isUniversity ? 'UNI' : 'SEC',
                                style: TextStyle(
                                  color: isUniversity ? Colors.blue.shade700 : kBrandOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(student.scholarId, 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            const Icon(Icons.apartment_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                student.schoolName,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$resultCount',
                              style: const TextStyle(color: kBrandBrown, fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'RECORD${resultCount == 1 ? '' : 'S'}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedYearFilter != null) ...[
                        const SizedBox(height: 4),
                        Text('IN $_selectedYearFilter', 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 0.5)),
                      ],
                    ],
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
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
  bool _isLoading = false;

  bool get _isUniversity => widget.student.schoolType == SchoolType.university;

  List<ResultRecord> get _studentResults =>
      kResults.where((r) => r.studentId == widget.student.id).toList();

  List<String> get _yearOptions {
    final years = _studentResults.map((r) => r.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<String> get _periods => _isUniversity ? ['Semester 1', 'Semester 2'] : ['Term 1', 'Term 2', 'Term 3'];

  String? _activePeriod; // e.g., 'Semester 1', 'ANNUAL'

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year.toString();
    _activePeriod = _isUniversity ? 'Semester 1' : 'Term 1';
    _fetchStudentResults();
  }

  Future<void> _fetchStudentResults() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getResultsByScholar(widget.student.id);
      if (response.statusCode != null && response.statusCode! < 400) {
        final List<dynamic> data = response.data['data'] ?? [];
        debugPrint('Fetched ${data.length} results for scholar ${widget.student.id}');
        
        setState(() {
          // Update the global results list for this student
          kResults.removeWhere((r) => r.studentId == widget.student.id);
          for (var item in data) {
            kResults.add(ResultRecord(
              studentId: item['scholar_id'].toString(),
              code: (item['subject_code'] ?? item['code'] ?? 'N/A').toString(),
              subject: (item['subject_name'] ?? item['subject'] ?? 'N/A').toString(),
              marks: double.tryParse(item['marks'].toString()) ?? 0.0,
              gpa: item['gpa'] != null ? double.tryParse(item['gpa'].toString()) : null,
              points: item['points'] != null ? double.tryParse(item['points'].toString()) : null,
              year: (item['academic_year'] ?? item['year'] ?? '').toString(),
              term: item['term'],
              semester: item['semester'],
            ));
          }
          
          if (_yearOptions.isNotEmpty) {
            _selectedYear = _yearOptions.first;
            debugPrint('Set selected year to $_selectedYear');
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching student results: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _exportCsv(List<String> periodsWithResults, double annualGpa, String outcomeLabel) async {
    setState(() => _isExporting = true);
    try {
      final rows = <List<dynamic>>[
        ['Period', '#', 'Code', 'Title', 'Marks', 'Grade/Letter', 'GP/Points'],
      ];
      for (final period in periodsWithResults) {
        final records = _resultsFor(period);
        for (var i = 0; i < records.length; i++) {
          final r = records[i];
          rows.add([
            period,
            i + 1,
            r.code,
            r.subject,
            r.marks,
            gradeFromMarks(r.marks, isUniversity: _isUniversity).letter,
            _isUniversity ? r.gradePoint.toStringAsFixed(2) : r.gradePoint.toStringAsFixed(0)
          ]);
        }
      }
      rows.add([]);
      for (final period in periodsWithResults) {
        final records = _resultsFor(period);
        if (_isUniversity) {
          final stats = calculateUniversityOutcome(records);
          rows.add(['$period Total Marks', stats.totalMarks]);
          rows.add(['$period GPA', stats.avgGpa.toStringAsFixed(2)]);
          rows.add(['$period Status', stats.status]);
        } else {
          final stats = calculateSecondaryOutcome(records);
          rows.add(['$period Best 6 Total Marks', stats.totalMarks]);
          rows.add(['$period Best 6 Total Points', stats.totalPoints]);
          rows.add(['$period Outcome', stats.passed ? 'PASS' : 'FAIL']);
        }
      }
      if (_isUniversity) {
        rows.add(['Annual GPA', annualGpa.toStringAsFixed(2)]);
      }
      rows.add(['Final Status', outcomeLabel]);

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

  Future<void> _exportPdf(List<String> periodsWithResults, double annualGpa, String outcomeLabel) async {
    setState(() => _isExporting = true);
    try {
      final brown = PdfColor.fromInt(kBrandBrown.toARGB32());
      final olive = PdfColor.fromInt(kBrandOlive.toARGB32());
      final cream = PdfColor.fromInt(kBrandCream.toARGB32());
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
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
              padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
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
              pw.Text('$period Results', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brown)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Code', 'Title', 'Marks', 'Grade/Letter', _isUniversity ? 'GPA' : 'Points'],
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
                        _isUniversity ? r.gradePoint.toStringAsFixed(2) : r.gradePoint.toStringAsFixed(0),
                      ];
                    })(),
                ],
                headerDecoration: pw.BoxDecoration(color: brown),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                cellPadding: const pw.EdgeInsets.fromLTRB(6, 5, 6, 5),
              ),
              pw.SizedBox(height: 6),
              if (_isUniversity)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Semester Total: ${calculateUniversityOutcome(_resultsFor(period)).totalMarks.toStringAsFixed(0)} | GPA: ${calculateUniversityOutcome(_resultsFor(period)).avgGpa.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                )
              else
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Best 6 Total: ${calculateSecondaryOutcome(_resultsFor(period)).totalMarks.toStringAsFixed(0)} | Points: ${calculateSecondaryOutcome(_resultsFor(period)).totalPoints.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              pw.SizedBox(height: 16),
            ],
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (_isUniversity)
                  pw.Text('Annual Average GPA: ${annualGpa.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: pw.BoxDecoration(color: (outcomeLabel == 'FAIL' || outcomeLabel == 'BELOW REQUIREMENT') ? PdfColors.red700 : olive, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text(outcomeLabel, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
    if (_isLoading) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: const CircularProgressIndicator(color: kBrandOlive),
      );
    }
    
    final periodsWithResults = _periods.where((p) => _resultsFor(p).isNotEmpty).toList();

    double annualGpa = 0;
    double annualAverage = 0;
    String finalStatus = 'N/A';

    final allYearResults = _studentResults.where((r) => r.year == _selectedYear).toList();
    
    if (allYearResults.isNotEmpty) {
      // Calculate Annual Average
      annualAverage = allYearResults.fold(0.0, (sum, r) => sum + r.marks) / allYearResults.length;
      
      if (_isUniversity) {
        // University: Average GPA of all courses in the year
        annualGpa = allYearResults.fold(0.0, (sum, r) => sum + (r.gpa ?? 0)) / allYearResults.length;
        finalStatus = calculateUniversityOutcome(allYearResults).status;
      } else {
        // Secondary: Status based on cumulative year performance or latest term
        // Professional standard: Best 6 marks across the year or from the final term?
        // Let's use the latest term with results for the final status badge.
        final latestTerm = periodsWithResults.isNotEmpty ? periodsWithResults.last : null;
        if (latestTerm != null) {
          final latestResults = _resultsFor(latestTerm);
          final outcome = calculateSecondaryOutcome(latestResults);
          finalStatus = outcome.passed ? 'PASS' : 'FAIL';
        }
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 900), // Slightly wider for professional rectangular look
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero, // Rectangular as requested
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 60, offset: const Offset(0, 30)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildProfessionalHeader(),
            _buildViewToggle(),
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: _activePeriod == 'ANNUAL' 
                    ? _buildAnnualSummaryView(annualGpa, annualAverage, finalStatus)
                    : _buildPeriodicView(_activePeriod!),
                ),
              ),
            ),
            _buildActionFooter(periodsWithResults, annualGpa, finalStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    final options = [..._periods, 'ANNUAL'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => _toggleBtn(opt)).toList(),
        ),
      ),
    );
  }

  Widget _toggleBtn(String label) {
    final isSelected = _activePeriod == label;
    final isAnnual = label == 'ANNUAL';
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _activePeriod = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? kBrandOlive.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isSelected ? kBrandOlive : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isAnnual ? Icons.analytics_rounded : Icons.calendar_view_day_rounded, 
                size: 16, color: isSelected ? kBrandOlive : Colors.grey),
              const SizedBox(width: 12),
              Text(
                isAnnual ? "YEAR AVERAGE" : label.toUpperCase(), 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w900, 
                  color: isSelected ? kBrandOlive : Colors.grey.shade600, 
                  letterSpacing: 0.8
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodicView(String period) {
    final records = _resultsFor(period);
    if (records.isEmpty) return _buildNoDataPlaceholder();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdentitySection(),
        const SizedBox(height: 48),
        _PeriodResultsTable(periodLabel: '$period RESULTS', records: records, isUniversity: _isUniversity),
      ],
    );
  }

  Widget _buildAnnualSummaryView(double annualGpa, double annualAverage, String finalStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdentitySection(),
        const SizedBox(height: 48),
        const Text("ANNUAL CONSOLIDATED PERFORMANCE", 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 60,
                runSpacing: 40,
                alignment: WrapAlignment.center,
                children: [
                  _summaryMetric("ACADEMIC YEAR AVG", "${annualAverage.toStringAsFixed(1)}%", kBrandOlive),
                  _summaryMetric(_isUniversity ? "CUMULATIVE GPA" : "YEAR STANDING", _isUniversity ? annualGpa.toStringAsFixed(2) : finalStatus, kBrandBrown),
                ],
              ),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded, color: kBrandOlive, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text("OFFICIAL STATUS: ${finalStatus.toUpperCase()}",
                      style: const TextStyle(color: kBrandBrown, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _summaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
      ],
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 32, 32),
      decoration: BoxDecoration(
        color: kBrandBrown.withOpacity(0.03),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: kBrandOlive, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsOf(widget.student.name),
              style: const TextStyle(color: kBrandBrown, fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(widget.student.name.toUpperCase(), 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5),
                        overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    _badge(widget.student.status, widget.student.status == 'Active' ? Colors.green : Colors.grey),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.student.schoolName, 
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _headerInfoItem(Icons.calendar_month_rounded, "ACADEMIC YEAR", _selectedYear)),
                    const SizedBox(width: 24),
                    Expanded(child: _headerInfoItem(Icons.school_outlined, "INSTITUTION LEVEL", _isUniversity ? "TERTIARY" : "SECONDARY")),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  hoverColor: Colors.grey.shade100,
                  elevation: 1,
                ),
              ),
              if (_yearOptions.length > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    underline: const SizedBox(),
                    items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedYear = v;
                          _fetchStudentResults();
                        });
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kSurfaceMuted,
        borderRadius: BorderRadius.circular(4), // Match the rectangular theme
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          _detailBlock("SCHOLAR ID", widget.student.scholarId),
          _detailBlock("PROGRAM / CLASS", widget.student.currentClass.isEmpty ? "NOT ASSIGNED" : widget.student.currentClass),
          _detailBlock("AGE", "${widget.student.age} YEARS"),
          _detailBlock("SPONSOR", widget.student.donor),
        ],
      ),
    );
  }

  Widget _detailBlock(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
        ],
      ),
    );
  }

  Widget _headerInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: kBrandOlive),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown)),
          ],
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 24),
            Text("No academic records found for $_selectedYear.", 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter(List<String> periodsWithResults, double annualGpa, String outcomeLabel) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          if (periodsWithResults.isNotEmpty) ...[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_isUniversity ? "ANNUAL AGGREGATE GPA" : "LATEST TERM STANDING", 
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(_isUniversity ? annualGpa.toStringAsFixed(2) : outcomeLabel, 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (outcomeLabel == 'FAIL' || outcomeLabel == 'Fail') ? Colors.red : kBrandOlive,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_isUniversity ? outcomeLabel.toUpperCase() : "QUALIFIED", 
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            OutlinedButton.icon(
              onPressed: _isExporting ? null : () => _exportCsv(periodsWithResults, annualGpa, outcomeLabel),
              icon: const Icon(Icons.grid_on_rounded),
              label: const Text("RAW DATA (CSV)"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : () => _exportPdf(periodsWithResults, annualGpa, outcomeLabel),
              icon: _isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded),
              label: const Text("EXPORT AUDIT PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
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
    dynamic outcome;
    if (isUniversity) {
      outcome = calculateUniversityOutcome(records);
    } else {
      outcome = calculateSecondaryOutcome(records);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: kBrandBrown,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(periodLabel.toUpperCase(), 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              if (isUniversity)
                 Text('GPA: ${outcome.avgGpa.toStringAsFixed(2)} | TOTAL: ${outcome.totalMarks.toStringAsFixed(0)}', 
                   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kBrandCream))
              else
                 Text('POINTS: ${outcome.totalPoints.toStringAsFixed(0)} | BEST 6: ${outcome.totalMarks.toStringAsFixed(0)}', 
                   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kBrandCream)),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 900),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columnSpacing: 20,
                horizontalMargin: 16,
                headingRowHeight: 48,
                dataRowMaxHeight: 56,
                border: TableBorder(
                  verticalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                  horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                columns: [
                  const DataColumn(label: Text('CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                  const DataColumn(label: Text('COURSE / SUBJECT TITLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                  const DataColumn(label: Text('MARKS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                  const DataColumn(label: Text('STANDING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                  DataColumn(label: Text(isUniversity ? 'GPA' : 'POINTS', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                ],
                rows: records.map((r) {
                  final graded = gradeFromMarks(r.marks, isUniversity: isUniversity);
                  Color statusColor = Colors.green;
                  if (isUniversity) {
                    if (r.marks < 50) statusColor = Colors.red;
                    else if (r.marks < 70) statusColor = Colors.orange;
                  } else {
                    if (r.marks < 40) statusColor = Colors.red;
                    else if (r.marks < 60) statusColor = Colors.orange;
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(r.code.isEmpty ? 'N/A' : r.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(r.subject.toUpperCase(), 
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        )
                      ),
                      DataCell(Text('${r.marks.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(graded.letter.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10)),
                      )),
                      DataCell(Text(isUniversity ? r.gradePoint.toStringAsFixed(2) : r.gradePoint.toStringAsFixed(0), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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
}
