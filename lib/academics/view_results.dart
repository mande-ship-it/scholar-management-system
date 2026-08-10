import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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
  bool _isSearchExpanded = false;

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
          kStudents.add(Student.fromMap(item));
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
        color: Color(0xFF4C3C32).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF4C3C32)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF4C3C32))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_mode == ViewResultsMode.selection) {
      return _buildSelectionScreen();
    }

    final students = _filteredStudents;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(),
          _buildIntegratedToolbar(),
          Expanded(
            child: Column(
              children: [
                _buildTabsAndArchiveToggle(),
                Expanded(
                  child: students.isEmpty
                      ? _buildNoResultsState()
                      : _buildScholarGrid(students),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalHeader() {
    final bool isSecondary = _mode == ViewResultsMode.secondary;
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    if (isMobile && _isSearchExpanded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Expanded(child: _portalCompactSearchField(true)),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: () => setState(() {
                _isSearchExpanded = false;
                _searchController.clear();
              }),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 12),
            style: IconButton.styleFrom(
              backgroundColor: Color(0xFF4C3C32).withOpacity(0.05),
              foregroundColor: const Color(0xFF4C3C32),
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
          ),
          SizedBox(width: isVerySmall ? 8 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerySmall ? "Results Audit" : "Examination Performance Ledger",
                  style: TextStyle(
                    fontSize: isVerySmall ? 13 : (isMobile ? 14 : 16), 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF4C3C32), 
                    letterSpacing: -0.2
                  ),
                ),
              ],
            ),
          ),
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF4C3C32), size: 20),
              onPressed: () => setState(() => _isSearchExpanded = true),
              visualDensity: VisualDensity.compact,
            ),
            if (!isVerySmall) const SizedBox(width: 4),
            IconButton(
              onPressed: widget.onEnterResults ?? () => Navigator.pushNamed(context, '/academics/enterResults'),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF9AB334),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ] else ...[
            if (_selectedSchool != null || (isSecondary && _selectedDistrict != null))
              _portalHeaderActionBtn(
                onTap: _openConsolidatedRoster,
                icon: Icons.grid_view_rounded,
                label: "Roster",
                color: const Color(0xFF4C3C32),
              ),
            const SizedBox(width: 8),
            _portalHeaderActionBtn(
              onTap: widget.onEnterResults ?? () => Navigator.pushNamed(context, '/academics/enterResults'),
              icon: Icons.add_rounded,
              label: "Record",
              color: const Color(0xFF9AB334),
            ),
          ],
        ],
      ),
    );
  }

  Widget _portalHeaderActionBtn({required VoidCallback onTap, required IconData icon, required String label, required Color color}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildIntegratedToolbar() {
    final bool isSecondary = _mode == ViewResultsMode.secondary;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: isMobile
            ? Row(
                children: [
                  if (isSecondary) ...[
                    _portalCompactDropdown("District", _selectedDistrict, kMalawiDistricts, (v) => setState(() { _selectedDistrict = v; _selectedSchool = null; _selectedScholarId = null; })),
                    const SizedBox(width: 8),
                  ],
                  _portalCompactDropdown(isSecondary ? "School" : "University", _selectedSchool, _availableSchools, (v) => setState(() { _selectedSchool = v; _selectedScholarId = null; })),
                ],
              )
            : Row(
                children: [
                  _portalCompactSearchField(false),
                  const SizedBox(width: 16),
                  if (isSecondary) ...[
                    SizedBox(
                      width: 180,
                      child: _portalCompactDropdown("District", _selectedDistrict, kMalawiDistricts, (v) => setState(() { _selectedDistrict = v; _selectedSchool = null; _selectedScholarId = null; })),
                    ),
                    const SizedBox(width: 12),
                  ],
                  SizedBox(
                    width: 240,
                    child: _portalCompactDropdown(isSecondary ? "Institution" : "University", _selectedSchool, _availableSchools, (v) => setState(() { _selectedSchool = v; _selectedScholarId = null; })),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: _portalCompactDropdown("Year", _selectedYear, _academicYears, (v) => setState(() => _selectedYear = v)),
                  ),
                  const SizedBox(width: 24),
                  _miniStat(Icons.groups_rounded, "${_filteredStudents.length} Scholars found"),
                ],
              ),
      ),
    );
  }

  Widget _portalCompactSearchField(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: isMobile ? Border.all(color: const Color(0xFFEEEEEE)) : null,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {}),
        autofocus: isMobile,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: isMobile ? "Search scholars..." : "Search scholar...",
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _portalCompactDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          underline: const SizedBox(),
          isExpanded: false, // Changed from true to false for better Row integration
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          items: [
            DropdownMenuItem(value: null, child: Text("All $label", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
          ],
          onChanged: onChanged,
        ),
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
            Icon(Icons.school_rounded, size: isMobile ? 48 : 64, color: const Color(0xFF4C3C32)),
            const SizedBox(height: 24),
            Text(
              "Academic Results Audit",
              style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), letterSpacing: -0.5),
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
                    color: const Color(0xFFE05B1C),
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
                    color: const Color(0xFFE05B1C),
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
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: isMobile ? double.infinity : 380,
        padding: EdgeInsets.all(isVerySmall ? 20 : (isMobile ? 24 : 40)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isVerySmall ? 12 : (isMobile ? 14 : 20)),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: isVerySmall ? 24 : (isMobile ? 32 : 40), color: color),
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            Text(title, style: TextStyle(fontSize: isVerySmall ? 16 : (isMobile ? 18 : 20), fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32))),
            SizedBox(height: isVerySmall ? 8 : 12),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: isVerySmall ? 12 : 13, color: Colors.grey.shade600, height: 1.5)),
            SizedBox(height: isVerySmall ? 24 : 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Proceed", style: TextStyle(fontSize: isVerySmall ? 10 : 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: isVerySmall ? 14 : 16, color: color),
              ],
            ),
          ],
        ),
      ),
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
            labelColor: const Color(0xFF9AB334),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF9AB334),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [Tab(text: "Active scholars"), Tab(text: "Alumni / Graduates")],
          ),
          const Spacer(),
          _miniStat(Icons.groups_rounded, "${_filteredStudents.length} scholars found"),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF4C3C32)),
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
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

        final int expectedPeriods = student.schoolType == SchoolType.university ? 2 : 3;
        bool hasPassed = false;
        if (student.schoolType == SchoolType.university) {
          final outcome = calculateUniversityOutcome(yearResults);
          hasPassed = outcome.status != 'Fail' && outcome.status != 'N/A';
        } else {
          final outcome = calculateSecondaryOutcome(yearResults);
          hasPassed = outcome.passed;
        }
        
        return _buildScholarCard(student, isMobile, uniquePeriods.length, expectedPeriods, hasPassed, yearForCheck);
      },
    );
  }

  Widget _buildScholarCard(Student s, bool isMobile, int periodCount, int expectedPeriods, bool hasPassed, String selectedYear) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final bool isUniversity = s.schoolType == SchoolType.university;
    final Color accentColor = isUniversity ? Colors.blue.shade700 : const Color(0xFFE05B1C);
    final bool isComplete = periodCount >= expectedPeriods;
    final bool isPartial = periodCount > 0 && periodCount < expectedPeriods;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openStudentResults(s),
          child: Padding(
            padding: EdgeInsets.all(isVerySmall ? 12 : 20),
            child: isVerySmall 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initialsOf(s.name),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF4C3C32)),
                              ),
                              Text(s.scholarId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.schoolName, 
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                              Text(s.calculatedAcademicYear, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hasPassed ? Color(0xFF9AB334).withOpacity(0.1) : Color(0xFFE05B1C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hasPassed ? "PASSING" : "FAILING",
                                style: TextStyle(
                                  color: hasPassed ? const Color(0xFF9AB334) : const Color(0xFFE05B1C), 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _portalBadge(
                              isComplete ? "COMPLETE" : (isPartial ? "PARTIAL" : "NO DATA"), 
                              isComplete ? Colors.blue.shade700 : (isPartial ? Colors.orange : Colors.grey)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withOpacity(0.2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initialsOf(s.name),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF4C3C32), letterSpacing: -0.2),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(s.scholarId, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(s.district, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.school_outlined, size: 14, color: Color(0xFF9AB334)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(s.schoolName, 
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4C3C32)),
                                    overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(s.calculatedAcademicYear, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasPassed ? Color(0xFF9AB334).withOpacity(0.1) : Color(0xFFE05B1C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasPassed ? "PASSING" : "FAILING",
                            style: TextStyle(
                              color: hasPassed ? const Color(0xFF9AB334) : const Color(0xFFE05B1C), 
                              fontWeight: FontWeight.w900, 
                              fontSize: 9,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _portalBadge(
                          isComplete ? "COMPLETE" : (isPartial ? "PARTIAL" : "NO DATA"), 
                          isComplete ? Colors.blue.shade700 : (isPartial ? Colors.orange : Colors.grey)
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _portalBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
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
    if (_isLoading) return Container(height: 400, alignment: Alignment.center, child: const CircularProgressIndicator(color: Color(0xFF9AB334)));
    
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final allResults = _studentResults.where((r) => r.year == _selectedYear).toList();
    double avgMarks = allResults.isEmpty ? 0 : allResults.fold(0.0, (sum, r) => sum + r.marks) / allResults.length;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(isMobile ? 12 : 0)
      ),
      child: Column(
        children: [
          _buildHeader(isVerySmall),
          _buildPeriodSelector(isVerySmall),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isVerySmall ? 16 : 40),
                child: _activePeriod == 'ANNUAL' ? _buildAnnualView(allResults, avgMarks, isVerySmall) : _buildPeriodicView(_activePeriod!, isVerySmall),
              ),
            ),
          ),
          _buildFooter(allResults, isVerySmall),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isVerySmall ? 16 : 40),
      color: Color(0xFF4C3C32).withOpacity(0.03),
      child: Row(
        children: [
          CircleAvatar(
            radius: isVerySmall ? 20 : 36, 
            backgroundColor: Color(0xFF9AB334).withOpacity(0.1), 
            child: Text(_initialsOf(widget.student.name), 
              style: TextStyle(fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), fontSize: isVerySmall ? 12 : 24))
          ),
          SizedBox(width: isVerySmall ? 12 : 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.student.name.toUpperCase(), 
                  style: TextStyle(fontSize: isVerySmall ? 14 : 24, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), letterSpacing: -0.5)),
                Text(widget.student.schoolName, 
                  style: TextStyle(fontSize: isVerySmall ? 10 : 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (_yearOptions.isNotEmpty)
            DropdownButton<String>(
              value: _selectedYear,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
              onChanged: (v) { if (v != null) setState(() { _selectedYear = v; }); },
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isVerySmall) {
    final options = [..._periods, 'ANNUAL'];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 40, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: options.map((opt) => _toggleBtn(opt, isVerySmall)).toList()),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isVerySmall) {
    final isSelected = _activePeriod == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _activePeriod = label),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF9AB334).withOpacity(0.1) : Colors.transparent, 
            borderRadius: BorderRadius.circular(4), 
            border: Border.all(color: isSelected ? const Color(0xFF9AB334) : Colors.grey.shade200)
          ),
          child: Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? const Color(0xFF9AB334) : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildPeriodicView(String period, bool isVerySmall) {
    final records = _resultsFor(period);
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.history_edu_rounded, size: 48, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text("No results recorded for $period.", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 40),
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

  Widget _buildAnnualView(List<ResultRecord> all, double avg, bool isVerySmall) {
    return Column(
      children: [
        Text("YEAR CONSOLIDATED PERFORMANCE", style: TextStyle(fontSize: isVerySmall ? 9 : 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: EdgeInsets.all(isVerySmall ? 24 : 48),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text("${avg.toStringAsFixed(1)}%", style: TextStyle(fontSize: isVerySmall ? 32 : 48, fontWeight: FontWeight.w900, color: const Color(0xFF9AB334))),
            Text("ACADEMIC YEAR AVERAGE", style: TextStyle(fontSize: isVerySmall ? 8 : 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          ]),
        ),
      ],
    );
  }

  Widget _buildFooter(List<ResultRecord> all, bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isVerySmall ? 16 : 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isVerySmall ? 11 : 13, color: Colors.grey.shade600))
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : () {},
            icon: Icon(Icons.picture_as_pdf_rounded, size: isVerySmall ? 14 : 18),
            label: Text(isVerySmall ? "PDF" : "DOWNLOAD PDF", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C3C32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
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
          decoration: const BoxDecoration(color: Color(0xFF4C3C32), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isVerySmall ? 16 : 32),
            color: const Color(0xFF4C3C32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(),
                        style: TextStyle(fontSize: isVerySmall ? 16 : 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(isVerySmall ? "$yearLabel $periodLabel" : "CONSOLIDATED ACADEMIC ROSTER — $yearLabel $periodLabel",
                        style: TextStyle(fontSize: isVerySmall ? 8 : 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          // Main Table
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: subjects.isEmpty 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text("No records found for the selected sitting.", 
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isVerySmall ? 12 : 40),
                    child: _buildRosterTable(subjects, relevantResults, isVerySmall),
                  ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 40, vertical: isVerySmall ? 12 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: isVerySmall 
              ? Row(
                  children: [
                    Expanded(
                      child: Text("${students.length} SCHOLARS", 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 0.5)),
                    ),
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF9AB334)),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${students.length} SCHOLARS AUDITED", 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 0.5)),
                    ElevatedButton.icon(
                      onPressed: () {}, // Future PDF export
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text("EXPORT ROSTER PDF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9AB334),
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

  Widget _buildRosterTable(List<String> subjects, List<ResultRecord> results, bool isVerySmall) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(kSurfaceMuted),
        border: TableBorder.all(color: Colors.grey.shade200),
        horizontalMargin: isVerySmall ? 12 : 20,
        columnSpacing: isVerySmall ? 16 : 24,
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
          const DataColumn(label: Text("COMPLETE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
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
                    color: isComplete ? Color(0xFF9AB334).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isComplete ? "YES" : "$uniqueYearPeriods/$expected", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isComplete ? const Color(0xFF9AB334) : Colors.orange)),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPassed ? Color(0xFF9AB334).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(hasPassed ? "PASS" : "FAIL",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: hasPassed ? const Color(0xFF9AB334) : Colors.red)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
