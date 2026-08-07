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
// Shared Brand Color Palette & UI Helpers
// ============================================================
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

enum ViewResultsMode { selection, secondary, university }

/// -------------------------------------------------------
/// MAIN COMPONENT
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

class _ViewResultsComponentState extends State<ViewResultsComponent> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  ViewResultsMode _mode = ViewResultsMode.selection;
  
  String? _selectedDistrict;
  String? _selectedSchool;
  String? _selectedScholarId;
  String? _selectedYear;
  String? _selectedTerm;
  String? _selectedSemester;
  String _statusFilter = 'All'; // 'All', 'Complete', 'Incomplete', 'Passed', 'Failing'

  bool _isLoading = false;

  final List<String> _academicYears = academicYearOptions();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final resultsRes = await ApiService.getResultsBySchool(null);
      if (resultsRes.statusCode != null && resultsRes.statusCode! < 400) {
        final List<dynamic> data = resultsRes.data['data'] ?? [];
        kResults.clear();
        for (var item in data) {
          kResults.add(ResultRecord.fromMap(item));
        }
      }

      final scholarsRes = await ApiService.getAllScholars();
      if (scholarsRes.statusCode != null && scholarsRes.statusCode! < 400) {
        final List<dynamic> data = scholarsRes.data['data'] ?? [];
        kStudents.clear();
        for (var item in data) {
          kStudents.add(Student(
            id: (item['id'] ?? item['_id'] ?? '').toString(),
            scholarId: item['scholar_id'] ?? 'N/A',
            name: item['full_name'] ?? 'N/A',
            age: item['age'] != null ? int.tryParse(item['age'].toString()) ?? 18 : 18,
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
    } catch (e) {
      debugPrint('Error loading view results data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _availableSchools {
    final type = _mode == ViewResultsMode.university ? SchoolType.university : SchoolType.secondary;
    final students = kStudents.where((s) => s.schoolType == type);
    
    Iterable<Student> filtered = students;
    if (_selectedDistrict != null && _mode == ViewResultsMode.secondary) {
      filtered = filtered.where((s) => s.district == _selectedDistrict);
    }
    
    return filtered.map((s) => s.schoolName).toSet().toList()..sort();
  }

  List<Student> get _availableScholars {
    final type = _mode == ViewResultsMode.university ? SchoolType.university : SchoolType.secondary;
    Iterable<Student> filtered = kStudents.where((s) => s.schoolType == type);
    
    if (_selectedDistrict != null && _mode == ViewResultsMode.secondary) {
      filtered = filtered.where((s) => s.district == _selectedDistrict);
    }
    if (_selectedSchool != null) {
      filtered = filtered.where((s) => s.schoolName == _selectedSchool);
    }
    
    return filtered.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    final bool showingArchive = _tabController.index == 1;
    final type = _mode == ViewResultsMode.university ? SchoolType.university : SchoolType.secondary;

    return kStudents.where((s) {
      if (s.schoolType != type) return false;

      final bool isGraduated = ['Graduated', 'Alumni', 'Completed'].contains(s.status);
      if (showingArchive && !isGraduated) return false;
      if (!showingArchive && isGraduated) return false;

      final matchesQuery = query.isEmpty || s.name.toLowerCase().contains(query);
      final matchesDistrict = _selectedDistrict == null || s.district == _selectedDistrict;
      final matchesSchool = _selectedSchool == null || s.schoolName == _selectedSchool;
      final matchesScholar = _selectedScholarId == null || s.id == _selectedScholarId;

      if (!(matchesQuery && matchesDistrict && matchesSchool && matchesScholar)) return false;

      // Status filtering (Complex Logic)
      if (_statusFilter == 'All') return true;

      final yearForCheck = _selectedYear ?? DateTime.now().year.toString();
      final studentResults = kResults.where((r) => r.studentId == s.id && r.year == yearForCheck).toList();
      final periodCount = studentResults.map((r) => s.schoolType == SchoolType.university ? r.semester : r.term).toSet().length;
      final expected = s.schoolType == SchoolType.university ? 2 : 3;

      if (_statusFilter == 'Complete') return periodCount >= expected;
      if (_statusFilter == 'Incomplete') return periodCount < expected;

      bool hasPassed = false;
      if (s.schoolType == SchoolType.university) {
        final outcome = calculateUniversityOutcome(studentResults);
        hasPassed = outcome.status != 'Fail' && outcome.status != 'N/A';
      } else {
        final outcome = calculateSecondaryOutcome(studentResults);
        hasPassed = outcome.passed;
      }

      if (_statusFilter == 'Passed') return hasPassed;
      if (_statusFilter == 'Failing') return !hasPassed && periodCount > 0;

      return true;
    }).toList();
  }

  void _openConsolidatedRoster() {
    final String title = _selectedSchool ?? _selectedDistrict ?? 'Selected Group';
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Consolidated Roster",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: _ConsolidatedRosterSheet(
                title: title,
                isUniversity: _mode == ViewResultsMode.university,
                selectedYear: _selectedYear,
                selectedTerm: _selectedTerm,
                selectedSemester: _selectedSemester,
                students: _filteredStudents,
              ),
            ),
          ),
        );
      },
    );
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
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
                child: _StudentExamResultsSheet(
                  student: student,
                  initialYear: _selectedYear,
                  initialTerm: _selectedTerm,
                  initialSemester: _selectedSemester,
                ),
              ),
            ),
          ),
        );
      },
    );
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
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kBrandBrown)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    if (_mode == ViewResultsMode.selection) {
      return _buildSelectionScreen();
    }

    final students = _filteredStudents;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF0F2F5), // Facebook-style background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            child: _buildTopHeader(),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            child: _buildFilterBar(),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            child: _buildTabsAndArchiveToggle(),
          ),
          Expanded(
            child: students.isEmpty
                ? _buildNoResultsState()
                : _buildScholarGrid(students),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionScreen() {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: isMobile ? 48 : 64, color: kBrandBrown),
            const SizedBox(height: 24),
            Text(
              "Academic Results Audit",
              style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Select an institution level to begin.",
              style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.grey),
            ),
            SizedBox(height: isMobile ? 32 : 48),
            if (isMobile)
              Column(
                children: [
                  _selectionCard(
                    title: "Secondary Schools",
                    subtitle: "View results by District, School or Scholar.",
                    icon: Icons.account_balance_rounded,
                    color: kBrandOrange,
                    onTap: () => setState(() => _mode = ViewResultsMode.secondary),
                    isMobile: true,
                  ),
                  const SizedBox(height: 16),
                  _selectionCard(
                    title: "Universities",
                    subtitle: "Audit tertiary education performance records.",
                    icon: Icons.auto_stories_rounded,
                    color: Colors.blue.shade700,
                    onTap: () => setState(() => _mode = ViewResultsMode.university),
                    isMobile: true,
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _selectionCard(
                    title: "Secondary Schools",
                    subtitle: "View results by District, School or Individual Scholar across all forms and terms.",
                    icon: Icons.account_balance_rounded,
                    color: kBrandOrange,
                    onTap: () => setState(() => _mode = ViewResultsMode.secondary),
                  ),
                  const SizedBox(width: 32),
                  _selectionCard(
                    title: "Universities / Tertiary",
                    subtitle: "Audit higher education performance by University and Scholar across years and semesters.",
                    icon: Icons.auto_stories_rounded,
                    color: Colors.blue.shade700,
                    onTap: () => setState(() => _mode = ViewResultsMode.university),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: isMobile ? double.infinity : 380,
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: isMobile ? 32 : 40, color: color),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w900, color: kBrandBrown)),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("PROCEED", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final bool isSecondary = _mode == ViewResultsMode.secondary;
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 32, isMobile ? 16 : 32, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => setState(() {
              _mode = ViewResultsMode.selection;
              _selectedDistrict = null;
              _selectedSchool = null;
              _selectedScholarId = null;
              _selectedYear = null;
              _selectedTerm = null;
              _selectedSemester = null;
            }),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: kBrandBrown.withOpacity(0.05),
              foregroundColor: kBrandBrown,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSecondary ? "SECONDARY ACADEMIC AUDIT" : "TERTIARY ACADEMIC AUDIT",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9AB334),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Examination Performance Ledger",
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22, 
                    fontWeight: FontWeight.w900, 
                    color: kBrandBrown, 
                    letterSpacing: -0.5
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            children: [
              if (_selectedSchool != null || (isSecondary && _selectedDistrict != null))
                OutlinedButton.icon(
                  onPressed: _openConsolidatedRoster,
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                  label: const Text("GENERATE ROSTER"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBrandBrown,
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: widget.onEnterResults ?? () => Navigator.pushNamed(context, '/academics/enterResults'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("RECORD RESULTS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerActionBtn({required VoidCallback onTap, required IconData icon, required String label, required Color color}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFilterBar() {
    final bool isSecondary = _mode == ViewResultsMode.secondary;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: Colors.grey.shade50,
      child: isMobile 
        ? Column(
            children: [
              if (isSecondary) ...[
                _filterDropdown(label: "District", hint: "All Districts", value: _selectedDistrict, items: kMalawiDistricts,
                  onChanged: (v) => setState(() { _selectedDistrict = v; _selectedSchool = null; _selectedScholarId = null; })),
                const SizedBox(height: 12),
              ],
              _filterDropdown(label: isSecondary ? "School" : "University", hint: isSecondary ? "All Schools" : "All Universities", value: _selectedSchool, items: _availableSchools,
                onChanged: (v) => setState(() { _selectedSchool = v; _selectedScholarId = null; })),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedScholarId,
                isExpanded: true,
                decoration: _filterDecoration("Scholar", "All Scholars"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Scholars")),
                  ..._availableScholars.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _selectedScholarId = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _filterDropdown(label: "Year", hint: "All", value: _selectedYear, items: _academicYears,
                      onChanged: (v) => setState(() => _selectedYear = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filterDropdown(label: isSecondary ? "Term" : "Semester", hint: "All", value: isSecondary ? _selectedTerm : _selectedSemester, items: isSecondary ? kTerms : kSemesters,
                      onChanged: (v) => setState(() { if (isSecondary) _selectedTerm = v; else _selectedSemester = v; })),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: _filterDecoration("Status", "All Statuses"),
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All Statuses")),
                  DropdownMenuItem(value: "Complete", child: Text("Complete")),
                  DropdownMenuItem(value: "Incomplete", child: Text("Missing Data")),
                  DropdownMenuItem(value: "Passed", child: Text("Passing")),
                  DropdownMenuItem(value: "Failing", child: Text("Failing")),
                ],
                onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
              ),
            ],
          )
        : Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (isSecondary)
                SizedBox(
                  width: 180,
                  child: _filterDropdown(label: "District", hint: "All Districts", value: _selectedDistrict, items: kMalawiDistricts,
                    onChanged: (v) => setState(() { _selectedDistrict = v; _selectedSchool = null; _selectedScholarId = null; })),
                ),
              SizedBox(
                width: 280,
                child: _filterDropdown(label: isSecondary ? "School" : "University", hint: isSecondary ? "All Schools" : "All Universities", value: _selectedSchool, items: _availableSchools,
                  onChanged: (v) => setState(() { _selectedSchool = v; _selectedScholarId = null; })),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String?>(
                  value: _selectedScholarId,
                  isExpanded: true,
                  decoration: _filterDecoration("Scholar", "All Scholars"),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Scholars")),
                    ..._availableScholars.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => _selectedScholarId = v),
                ),
              ),
              SizedBox(
                width: 140,
                child: _filterDropdown(label: "Year", hint: "All Years", value: _selectedYear, items: _academicYears,
                  onChanged: (v) => setState(() => _selectedYear = v)),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: _filterDecoration("Academic Status", "All Statuses"),
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All Statuses")),
                    DropdownMenuItem(value: "Complete", child: Text("Fully Recorded")),
                    DropdownMenuItem(value: "Incomplete", child: Text("Missing Data")),
                    DropdownMenuItem(value: "Passed", child: Text("Passing Annual")),
                    DropdownMenuItem(value: "Failing", child: Text("Failing Annual")),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                ),
              ),
              if (isSecondary)
                SizedBox(
                  width: 140,
                  child: _filterDropdown(label: "Term", hint: "All Terms", value: _selectedTerm, items: kTerms,
                    onChanged: (v) => setState(() => _selectedTerm = v)),
                )
              else
                SizedBox(
                  width: 160,
                  child: _filterDropdown(label: "Semester", hint: "All Semesters", value: _selectedSemester, items: kSemesters,
                    onChanged: (v) => setState(() => _selectedSemester = v)),
                ),
            ],
          ),
    );
  }

  Widget _filterDropdown({required String label, required String hint, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: _filterDecoration(label, hint),
      items: [
        DropdownMenuItem(value: null, child: Text(hint)),
        ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: onChanged,
    );
  }

  InputDecoration _filterDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }

  Widget _buildTabsAndArchiveToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: kBrandOlive,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kBrandOlive,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [Tab(text: "ACTIVE SCHOLARS"), Tab(text: "ALUMNI / GRADUATES")],
          ),
          const Spacer(),
          _miniStat(Icons.groups_rounded, "${_filteredStudents.length} scholars found"),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: kBrandBrown),
            onPressed: () => setState(() {
              _selectedDistrict = null; _selectedSchool = null; _selectedScholarId = null;
              _selectedYear = null; _selectedTerm = null; _selectedSemester = null; _searchController.clear();
            }),
            tooltip: "Reset All Filters",
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No scholars match current filters.", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScholarGrid(List<Student> students) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 220,
          ),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final relevantResults = kResults.where((r) {
              final matchesId = r.studentId == student.id;
              final matchesYear = _selectedYear == null || r.year == _selectedYear;
              final matchesTerm = _selectedTerm == null || r.term == _selectedTerm;
              final matchesSemester = _selectedSemester == null || r.semester == _selectedSemester;
              return matchesId && matchesYear && matchesTerm && matchesSemester;
            }).toList();

            final Set<String> uniquePeriods = {};
            final yearForCheck = _selectedYear ?? DateTime.now().year.toString();
            
            final yearResults = kResults.where((r) => r.studentId == student.id && r.year == yearForCheck).toList();
            
            for (var r in relevantResults) {
              final period = student.schoolType == SchoolType.university ? (r.semester ?? 'N/A') : (r.term ?? 'N/A');
              uniquePeriods.add("${r.year}_$period");
            }
            
            return _ScholarAcademicCard(
              student: student,
              periodCount: uniquePeriods.length,
              selectedYear: yearForCheck,
              yearResults: yearResults,
              onTap: () => _openStudentResults(student),
            );
          },
        );
      },
    );
  }
}

class _ScholarAcademicCard extends StatelessWidget {
  const _ScholarAcademicCard({
    required this.student, 
    required this.periodCount, 
    required this.onTap, 
    required this.selectedYear,
    required this.yearResults,
  });
  final Student student;
  final int periodCount;
  final VoidCallback onTap;
  final String selectedYear;
  final List<ResultRecord> yearResults;

  @override
  Widget build(BuildContext context) {
    final bool isUniversity = student.schoolType == SchoolType.university;
    final Color accentColor = isUniversity ? Colors.blue.shade700 : kBrandOrange;

    // --- Intelligence Logic ---
    final int expectedPeriods = isUniversity ? 2 : 3;
    final bool isComplete = periodCount >= expectedPeriods;
    final bool isPartial = periodCount > 0 && periodCount < expectedPeriods;
    
    bool hasPassed = false;
    if (isUniversity) {
      final outcome = calculateUniversityOutcome(yearResults);
      hasPassed = outcome.status != 'Fail' && outcome.status != 'N/A';
    } else {
      final outcome = calculateSecondaryOutcome(yearResults);
      hasPassed = outcome.passed;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComplete ? kBrandOlive.withOpacity(0.3) : Colors.grey.shade200, 
              width: isComplete ? 2 : 1
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              // Card Header: Profile Info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withOpacity(0.2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(_initialsOf(student.name), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name.toUpperCase(), 
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2), 
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(student.scholarId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Card Content: Status Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.apartment_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(child: Text(student.schoolName, 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700), 
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (periodCount > 0) ...[
                          _statusBadge(
                            hasPassed ? "PASSED" : "FAILING", 
                            hasPassed ? kBrandOlive : Colors.red,
                            Icons.verified_rounded
                          ),
                          const SizedBox(width: 8),
                        ],
                        _statusBadge(
                          isComplete ? "COMPLETE" : (isPartial ? "PARTIAL" : "NO DATA"), 
                          isComplete ? Colors.blue.shade700 : (isPartial ? Colors.orange : Colors.grey),
                          isComplete ? Icons.check_circle_rounded : Icons.pending_actions_rounded
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),
              
              // Card Footer: Stats & Call to Action
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isComplete ? kBrandOlive.withOpacity(0.05) : kSurfaceMuted,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedYear, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('$periodCount / $expectedPeriods RECORDED', 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isComplete ? kBrandOlive : kBrandBrown)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _StudentExamResultsSheet extends StatefulWidget {
  const _StudentExamResultsSheet({required this.student, this.initialYear, this.initialTerm, this.initialSemester});
  final Student student;
  final String? initialYear;
  final String? initialTerm;
  final String? initialSemester;
  @override
  State<_StudentExamResultsSheet> createState() => _StudentExamResultsSheetState();
}

class _StudentExamResultsSheetState extends State<_StudentExamResultsSheet> {
  late String _selectedYear;
  String? _activePeriod;
  bool _isLoading = false;
  bool _isExporting = false;

  bool get _isUniversity => widget.student.schoolType == SchoolType.university;
  List<ResultRecord> get _studentResults => kResults.where((r) => r.studentId == widget.student.id).toList();
  List<String> get _yearOptions => _studentResults.map((r) => r.year).toSet().toList()..sort((a, b) => b.compareTo(a));
  List<String> get _periods => _isUniversity ? ['Semester 1', 'Semester 2'] : ['Term 1', 'Term 2', 'Term 3'];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year.toString();
    _activePeriod = _isUniversity ? (widget.initialSemester ?? 'Semester 1') : (widget.initialTerm ?? 'Term 1');
    _fetchStudentResults();
  }

  Future<void> _fetchStudentResults() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getResultsByScholar(widget.student.id);
      if (response.statusCode != null && response.statusCode! < 400) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          kResults.removeWhere((r) => r.studentId == widget.student.id);
          for (var item in data) kResults.add(ResultRecord.fromMap(item));
          if (_yearOptions.isNotEmpty && widget.initialYear == null) _selectedYear = _yearOptions.first;
        });
      }
    } catch (e) { debugPrint('Error: $e'); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  List<ResultRecord> _resultsFor(String period) {
    return _studentResults.where((r) => r.year == _selectedYear && (_isUniversity ? r.semester == period : r.term == period)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Container(height: 400, alignment: Alignment.center, child: const CircularProgressIndicator(color: kBrandOlive));
    
    final allResults = _studentResults.where((r) => r.year == _selectedYear).toList();
    double avgMarks = allResults.isEmpty ? 0 : allResults.fold(0.0, (sum, r) => sum + r.marks) / allResults.length;
    
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          _buildHeader(),
          _buildPeriodSelector(),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: _activePeriod == 'ANNUAL' ? _buildAnnualView(allResults, avgMarks) : _buildPeriodicView(_activePeriod!),
              ),
            ),
          ),
          _buildFooter(allResults),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: kBrandBrown.withOpacity(0.03),
      child: Row(
        children: [
          CircleAvatar(radius: 36, backgroundColor: kBrandOlive.withOpacity(0.1), child: Text(_initialsOf(widget.student.name), style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 24))),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.student.name.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text(widget.student.schoolName, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (_yearOptions.isNotEmpty)
            DropdownButton<String>(
              value: _selectedYear,
              underline: const SizedBox(),
              items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (v) { if (v != null) setState(() { _selectedYear = v; }); },
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final options = [..._periods, 'ANNUAL'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: options.map((opt) => _toggleBtn(opt)).toList()),
    );
  }

  Widget _toggleBtn(String label) {
    final isSelected = _activePeriod == label;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _activePeriod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: isSelected ? kBrandOlive.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(4), border: Border.all(color: isSelected ? kBrandOlive : Colors.grey.shade200)),
          child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? kBrandOlive : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildPeriodicView(String period) {
    final records = _resultsFor(period);
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 24),
            Text("No results recorded for $period.", 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text("Check other terms or change the academic year above.", 
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PeriodResultsTable(periodLabel: '$period RESULTS', records: records, isUniversity: _isUniversity),
      ],
    );
  }

  Widget _buildAnnualView(List<ResultRecord> all, double avg) {
    return Column(
      children: [
        const Text("YEAR CONSOLIDATED PERFORMANCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
          child: Column(children: [
            Text("${avg.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: kBrandOlive)),
            const Text("ACADEMIC YEAR AVERAGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          ]),
        ),
      ],
    );
  }

  Widget _buildFooter(List<ResultRecord> all) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text("CLOSE TRANSCRIPT")),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : () {},
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text("DOWNLOAD PDF"),
            style: ElevatedButton.styleFrom(backgroundColor: kBrandBrown, foregroundColor: Colors.white),
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
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(color: kBrandBrown, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
          child: Text(periodLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        DataTable(
          columns: const [
            DataColumn(label: Text('SUBJECT/COURSE')),
            DataColumn(label: Text('MARKS')),
            DataColumn(label: Text('GRADE')),
          ],
          rows: records.map((r) => DataRow(cells: [
            DataCell(Text(r.subject.toUpperCase())),
            DataCell(Text("${r.marks.toStringAsFixed(0)}%")),
            DataCell(Text(gradeFromMarks(r.marks, isUniversity: isUniversity).letter)),
          ])).toList(),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// CONSOLIDATED ACADEMIC ROSTER
/// ---------------------------------------------------------------------

class _ConsolidatedRosterSheet extends StatelessWidget {
  const _ConsolidatedRosterSheet({
    required this.title,
    required this.isUniversity,
    this.selectedYear,
    this.selectedTerm,
    this.selectedSemester,
    required this.students,
  });

  final String title;
  final bool isUniversity;
  final String? selectedYear;
  final String? selectedTerm;
  final String? selectedSemester;
  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final periodLabel = isUniversity ? (selectedSemester ?? 'Semester 1') : (selectedTerm ?? 'Term 1');
    final yearLabel = selectedYear ?? DateTime.now().year.toString();

    // 1. Get unique subjects for this group and sitting
    final relevantResults = kResults.where((r) {
      final matchesYear = selectedYear == null || r.year == selectedYear;
      final matchesPeriod = isUniversity ? r.semester == selectedSemester : r.term == selectedTerm;
      final isStudentInGroup = students.any((s) => s.id == r.studentId);
      return matchesYear && matchesPeriod && isStudentInGroup;
    }).toList();

    final subjects = relevantResults.map((r) => r.subject).toSet().toList()..sort();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(32),
            color: kBrandBrown,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text("CONSOLIDATED ACADEMIC ROSTER — $yearLabel $periodLabel",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          // Main Table
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subjects.isEmpty) 
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 100),
                          child: Text("No records found for the selected year and sitting.", 
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                        ),
                      )
                    else
                      _buildRosterTable(subjects, relevantResults),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${students.length} SCHOLARS AUDITED", 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 0.5)),
                ElevatedButton.icon(
                  onPressed: () {}, // Future PDF export
                  icon: const Icon(Icons.download_rounded),
                  label: const Text("EXPORT ROSTER PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterTable(List<String> subjects, List<ResultRecord> results) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(kSurfaceMuted),
        border: TableBorder.all(color: Colors.grey.shade200),
        horizontalMargin: 20,
        columnSpacing: 24,
        columns: [
          const DataColumn(label: Text("SCHOLAR NAME", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
          ...subjects.map((sub) => DataColumn(
            label: SizedBox(
              width: 80,
              child: Text(sub, 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, overflow: TextOverflow.ellipsis),
                textAlign: TextAlign.center),
            ),
          )),
          const DataColumn(label: Text("AVERAGE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
          const DataColumn(label: Text("COMPLETENESS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
          const DataColumn(label: Text("OUTCOME", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        ],
        rows: students.map((student) {
          final studentResults = results.where((r) => r.studentId == student.id).toList();
          
          // Year-wide check for completeness
          final yearResults = kResults.where((r) => r.studentId == student.id && r.year == (selectedYear ?? DateTime.now().year.toString())).toList();
          final uniqueYearPeriods = yearResults.map((r) => isUniversity ? r.semester : r.term).toSet().length;
          final expected = isUniversity ? 2 : 3;
          final bool isComplete = uniqueYearPeriods >= expected;

          double totalMarks = 0;
          int count = 0;
          
          final cells = subjects.map((sub) {
            final record = studentResults.firstWhere((r) => r.subject == sub, orElse: () => const ResultRecord(studentId: '', code: '', subject: '', marks: -1, year: ''));
            if (record.marks != -1) {
              totalMarks += record.marks;
              count++;
              return DataCell(Center(child: Text("${record.marks.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold))));
            }
            return const DataCell(Center(child: Text("—", style: TextStyle(color: Colors.grey))));
          }).toList();

          final double average = count > 0 ? totalMarks / count : 0;
          
          bool hasPassed = false;
          if (isUniversity) {
            final outcome = calculateUniversityOutcome(yearResults);
            hasPassed = outcome.status != 'Fail' && outcome.status != 'N/A';
          } else {
            final outcome = calculateSecondaryOutcome(yearResults);
            hasPassed = outcome.passed;
          }

          return DataRow(
            cells: [
              DataCell(Text(student.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              ...cells,
              DataCell(Text(count > 0 ? "${average.toStringAsFixed(1)}%" : "N/A", style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete ? kBrandOlive.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isComplete ? "COMPLETE" : "$uniqueYearPeriods/$expected", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isComplete ? kBrandOlive : Colors.orange)),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPassed ? kBrandOlive.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(hasPassed ? "PASSED" : "FAILED", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: hasPassed ? kBrandOlive : Colors.red)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
