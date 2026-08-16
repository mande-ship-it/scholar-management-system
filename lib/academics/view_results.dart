import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback? onBack;
  final VoidCallback? onEnterResults;
  final VoidCallback? onViewPerformance;
  final VoidCallback? onViewReports;

  const ViewResultsComponent({
    super.key, 
    this.onBack,
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
  String _userRole = 'User';

  final List<String> _academicYears = academicYearOptions();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchData();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _userRole = data['role_name'] ?? 'User';
          });
        }
      }
    } catch (_) {}
  }

  bool get _canDelete {
    final String role = _userRole.toLowerCase();
    return ['administrator', 'program coordinator', 'country director'].contains(role);
  }

  Future<void> _deleteScholar(Student s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permanent Deletion", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text("Are you sure you want to permanently delete ${s.name}? This will remove all their results, attendance, and documents from the system archive. This action is irreversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Confirm Deletion"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final res = await ApiService.deleteScholar(s.id);
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scholar and all historical data deleted."), backgroundColor: Colors.red),
          );
          _fetchData();
        }
      } catch (e) {
        debugPrint('Delete error: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }
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

      // User Spec: Alumni are those who completed Form 4 (for secondary) 
      // or are specifically marked as Alumni/Graduated.
      final bool isAlumni = s.status == 'Alumni' || 
                           s.status == 'Graduated' || 
                           s.status == 'Completed' ||
                           (type == SchoolType.secondary && s.currentClass == 'Form 4' && s.status != 'Active');
      
      if (showingArchive && !isAlumni) return false;
      if (!showingArchive && isAlumni) return false;

      final matchesQuery = query.isEmpty || s.name.toLowerCase().contains(query);
      final matchesDistrict = _selectedDistrict == null || s.district == _selectedDistrict;
      final matchesSchool = _selectedSchool == null || s.schoolName == _selectedSchool;
      final matchesScholar = _selectedScholarId == null || s.id == _selectedScholarId;

      if (!(matchesQuery && matchesDistrict && matchesSchool && matchesScholar)) return false;

      // Status filtering
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

    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final students = _filteredStudents;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isMobile ? Colors.white : const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalIntegratedHeader(),
          _buildFilterBar(isMobile),
          if (isMobile) const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                _buildTabNavigation(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                    : students.isEmpty
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

  Widget _buildPortalIntegratedHeader() {
    final bool isSecondary = _mode == ViewResultsMode.secondary;
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() {
              _mode = ViewResultsMode.selection;
              _selectedDistrict = null;
              _selectedSchool = null;
              _selectedScholarId = null;
              _selectedYear = null;
              _selectedTerm = null;
              _selectedSemester = null;
            }),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: kBrandBrown),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          if (!_isSearchExpanded)
            Expanded(
              child: Text(
                isSecondary ? "Sec Results" : "Uni Results",
                style: TextStyle(
                  fontSize: isVerySmall ? 13 : 16, 
                  fontWeight: FontWeight.w900, 
                  color: const Color(0xFF4C3C32), 
                  letterSpacing: -0.2
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_isSearchExpanded)
            Expanded(child: _portalCompactSearchField(isMobile))
          else
            _portalCompactSearchField(isMobile),
          if (!_isSearchExpanded) ...[
            const SizedBox(width: 8),
            if (_selectedSchool != null || (isSecondary && _selectedDistrict != null))
              IconButton(
                onPressed: _openConsolidatedRoster,
                icon: const Icon(Icons.grid_view_rounded, color: kBrandBrown, size: 20),
                tooltip: "Roster",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            if (!isSecondary) // Restricted for secondary as per user request
              IconButton(
                onPressed: widget.onEnterResults ?? () => Navigator.pushNamed(context, '/academics/enterResults'),
                icon: const Icon(Icons.add_circle_outline_rounded, color: kBrandOlive, size: 24),
                tooltip: "Record",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    final bool isSecondary = _mode == ViewResultsMode.secondary;
    final scholars = _availableScholars;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (isSecondary) ...[
              _portalCompactDropdown("District", _selectedDistrict, kMalawiDistricts, (v) => setState(() { _selectedDistrict = v; _selectedSchool = null; _selectedScholarId = null; })),
              const SizedBox(width: 8),
            ],
            _portalCompactDropdown(isSecondary ? "School" : "University", _selectedSchool, _availableSchools, (v) => setState(() { _selectedSchool = v; _selectedScholarId = null; })),
            const SizedBox(width: 8),
            _portalCompactDropdown("Scholar", _selectedScholarId, scholars.map((s) => s.id).toList(), (v) => setState(() => _selectedScholarId = v),
              itemLabelBuilder: (id) => scholars.firstWhere((s) => s.id == id).name,
            ),
            const SizedBox(width: 8),
            _portalCompactDropdown("Year", _selectedYear, _academicYears, (v) => setState(() => _selectedYear = v)),
            const SizedBox(width: 8),
            if (isSecondary)
              _portalCompactDropdown("Term", _selectedTerm, ['Term 1', 'Term 2', 'Term 3'], (v) => setState(() => _selectedTerm = v))
            else
              _portalCompactDropdown("Semester", _selectedSemester, ['Semester 1', 'Semester 2'], (v) => setState(() => _selectedSemester = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: kBrandOlive,
        unselectedLabelColor: Colors.grey,
        indicatorColor: kBrandOlive,
        indicatorWeight: 3,
        labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: isVerySmall ? 11 : 13, letterSpacing: 0.5),
        tabs: [
          Tab(text: "Active Scholars", height: isVerySmall ? 40 : 48), 
          Tab(text: "Alumnae Registry", height: isVerySmall ? 40 : 48)
        ],
      ),
    );
  }

  Widget _portalCompactSearchField(bool isMobile) {
    if (!_isSearchExpanded) {
      return IconButton(
        onPressed: () => setState(() => _isSearchExpanded = true),
        icon: const Icon(Icons.search, color: kBrandBrown),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8F9FA),
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      );
    }

    return Container(
      width: isMobile ? double.infinity : 280,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {}),
        autofocus: true,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Search scholars...",
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 18), 
            onPressed: () => setState(() {
              _isSearchExpanded = false;
              _searchController.clear();
            }),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _portalCompactDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {String Function(String)? itemLabelBuilder}) {
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
          isExpanded: false,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          items: [
            DropdownMenuItem(value: null, child: Text("All $label", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ...items.map((i) => DropdownMenuItem(
              value: i, 
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(itemLabelBuilder != null ? itemLabelBuilder(i) : i, 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            )),
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
    
    // Advanced normalization helper
    String norm(String? s) {
      if (s == null) return '';
      String val = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      
      // If it's just a digit, prepend the appropriate prefix
      if (RegExp(r'^\d+$').hasMatch(val)) {
        if (_mode == ViewResultsMode.university) {
          return "year $val";
        } else {
          return "form $val";
        }
      }
      return val;
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32, 
        vertical: isMobile ? 12 : 32
      ),
      itemCount: students.length,
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
      itemBuilder: (context, index) {
        final student = students[index];
        final String targetClassNorm = norm(student.currentClass);
        
        // Show results for their CURRENT class specifically
        final currentClassResults = kResults.where((r) => 
          r.studentId == student.id && 
          norm(r.currentClass) == targetClassNorm
        ).toList();

        final uniquePeriods = currentClassResults.map((r) => student.schoolType == SchoolType.university ? r.semester : r.term).toSet().length;

        final int expectedPeriods = student.schoolType == SchoolType.university ? 2 : 3;
        bool hasPassed = false;
        double avgScore = 0;
        if (student.schoolType == SchoolType.university) {
          final outcome = calculateUniversityOutcome(currentClassResults);
          hasPassed = outcome.status != 'Fail' && outcome.status != 'N/A';
          avgScore = outcome.totalMarks;
        } else {
          final outcome = calculateSecondaryOutcome(currentClassResults);
          hasPassed = outcome.passed;
          avgScore = outcome.totalMarks;
        }
        
        return _buildScholarCard(student, isMobile, uniquePeriods, expectedPeriods, hasPassed, avgScore, student.currentClass);
      },
    );
  }

  Widget _buildScholarCard(Student s, bool isMobile, int periodCount, int expectedPeriods, bool hasPassed, double avgScore, String selectedYear) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final bool isUniversity = s.schoolType == SchoolType.university;
    final Color accentColor = isUniversity ? Colors.blue.shade700 : const Color(0xFFE05B1C);
    final bool isComplete = periodCount >= expectedPeriods;
    final bool isPartial = periodCount > 0 && periodCount < expectedPeriods;
    final bool showingArchive = _tabController.index == 1;

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
                        if (showingArchive && _canDelete)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () => _deleteScholar(s),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                            if (periodCount > 0)
                              Text("${avgScore.toStringAsFixed(1)}%", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: hasPassed ? kBrandOlive : Colors.redAccent)),
                            const SizedBox(height: 4),
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
                    if (periodCount > 0) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${avgScore.toStringAsFixed(1)}%", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: hasPassed ? kBrandOlive : Colors.redAccent)),
                          const Text("CLASS AVG", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(width: 24),
                    ],
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
                    if (showingArchive && _canDelete)
                       IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () => _deleteScholar(s),
                        tooltip: "Delete Scholar Data",
                      )
                    else
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
          
          // Advanced normalization for robust matching
          String norm(String? s) {
            if (s == null) return '';
            String val = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
            if (RegExp(r'^\d+$').hasMatch(val)) {
              return widget.student.schoolType == SchoolType.university ? "year $val" : "form $val";
            }
            return val;
          }

          final String targetClassNorm = norm(widget.student.currentClass);

          // Find if there are results for the CURRENT class specifically
          final currentClassResults = _studentResults.where((r) => norm(r.currentClass) == targetClassNorm).toList();
          
          if (currentClassResults.isNotEmpty) {
            // Priority 1: Set selected year to the MOST RECENT year found for this current class
            currentClassResults.sort((a, b) => b.year.compareTo(a.year));
            _selectedYear = currentClassResults.first.year;
          } else if (_yearOptions.isNotEmpty && widget.initialYear == null) {
            // Priority 2: Fallback to the absolute latest year if no current-class data exists
            _selectedYear = _yearOptions.first;
          }
        });
      }
    } catch (e) { debugPrint('Error: $e'); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  List<ResultRecord> _resultsFor(String period) {
    // Advanced normalization for robust matching
    String norm(String? s) {
      if (s == null) return '';
      String val = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (RegExp(r'^\d+$').hasMatch(val)) {
        return widget.student.schoolType == SchoolType.university ? "year $val" : "form $val";
      }
      return val;
    }

    final String targetClassNorm = norm(widget.student.currentClass);

    return _studentResults.where((r) {
      final matchesYear = r.year == _selectedYear;
      final matchesPeriod = _isUniversity ? r.semester == period : r.term == period;
      final matchesClass = norm(r.currentClass) == targetClassNorm;
      
      return matchesYear && matchesPeriod && matchesClass;
    }).toList();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final doc = pw.Document();
      final logo = await rootBundle.load('assets/images/age-logo.png');
      final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

      final allResults = _studentResults.where((r) => r.year == _selectedYear).toList();
      double avg = 0;
      if (_isUniversity) {
        avg = calculateUniversityOutcome(allResults).totalMarks;
      } else {
        avg = calculateSecondaryOutcome(allResults).totalMarks;
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, height: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("AGE AFRICA", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Academic Transcript", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
            ],
          ),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text("OFFICIAL ACADEMIC RECORD", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2))),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(
                children: [
                  _pwInfoRowHelper('Scholar Name', widget.student.name.toUpperCase()),
                  _pwInfoRowHelper('Scholar ID', widget.student.scholarId),
                  _pwInfoRowHelper('Institution', widget.student.schoolName),
                  _pwInfoRowHelper('Academic Year', _selectedYear),
                  _pwInfoRowHelper('Year Average', "${avg.toStringAsFixed(1)}%"),
                ]
              )
            ),
            pw.SizedBox(height: 30),
            ..._periods.map((period) {
              final periodResults = _resultsFor(period);
              if (periodResults.isEmpty) return pw.SizedBox();
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(4), topRight: pw.Radius.circular(4))),
                    child: pw.Text(period.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.TableHelper.fromTextArray(
                    headers: ['Subject/Course', 'Marks', 'Grade', 'Status'],
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.5),
                    },
                    data: periodResults.map((r) => [
                      r.subject,
                      "${r.marks.toInt()}%",
                      gradeFromMarks(r.marks, isUniversity: _isUniversity).letter,
                      r.status ?? 'First Attempt',
                    ]).toList(),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => doc.save(), name: 'Transcript_${widget.student.scholarId}.pdf');
    } catch (e) {
      debugPrint('Export Error: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Container(height: 400, alignment: Alignment.center, child: const CircularProgressIndicator(color: Color(0xFF9AB334)));
    
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final allResults = _studentResults.where((r) => r.year == _selectedYear).toList();

    double avgMarks = 0;
    if (_isUniversity) {
      avgMarks = calculateUniversityOutcome(allResults).totalMarks;
    } else {
      avgMarks = calculateSecondaryOutcome(allResults).totalMarks;
    }

    final String displayClass = allResults.isNotEmpty ? (allResults.first.currentClass ?? widget.student.currentClass) : widget.student.currentClass;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(isMobile ? 12 : 0)
      ),
      child: Column(
        children: [
          _buildHeader(isVerySmall, displayClass),
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

  Widget _buildHeader(bool isVerySmall, String displayClass) {
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
                Text("${widget.student.schoolName} — $displayClass",
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
    // Only show results for the scholar's CURRENT class label in the Annual View
    final currentClassAll = all.where((r) => r.currentClass == widget.student.currentClass).toList();
    
    double currentAvg = 0;
    if (currentClassAll.isNotEmpty) {
      if (_isUniversity) {
        currentAvg = calculateUniversityOutcome(currentClassAll).totalMarks;
      } else {
        currentAvg = calculateSecondaryOutcome(currentClassAll).totalMarks;
      }
    }

    return Column(
      children: [
        Text("${widget.student.currentClass.toUpperCase()} CONSOLIDATED PERFORMANCE", 
          style: TextStyle(fontSize: isVerySmall ? 9 : 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: EdgeInsets.all(isVerySmall ? 24 : 48),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text("${currentAvg.toStringAsFixed(1)}%", style: TextStyle(fontSize: isVerySmall ? 32 : 48, fontWeight: FontWeight.w900, color: const Color(0xFF9AB334))),
            const Text("CURRENT CLASS AVERAGE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
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
            onPressed: _isExporting ? null : _exportPdf,
            icon: _isExporting 
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(Icons.picture_as_pdf_rounded, size: isVerySmall ? 14 : 18),
            label: Text(isVerySmall ? "PDF" : "DOWNLOAD TRANSCRIPT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
            DataColumn(label: Text('ATTEMPT')),
          ],
          rows: records.map((r) => DataRow(cells: [
            DataCell(Text(r.subject.toUpperCase())),
            DataCell(Text("${r.marks.toStringAsFixed(0)}%")),
            DataCell(Text(gradeFromMarks(r.marks, isUniversity: isUniversity).letter)),
            DataCell(Text(r.status ?? 'First Attempt', style: TextStyle(
              color: (r.status == 'Repeat') ? Colors.orange.shade700 : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold
            ))),
          ])).toList(),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// CONSOLIDATED ACADEMIC ROSTER
/// ---------------------------------------------------------------------

class _ConsolidatedRosterSheet extends StatefulWidget {
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
  State<_ConsolidatedRosterSheet> createState() => _ConsolidatedRosterSheetState();
}

class _ConsolidatedRosterSheetState extends State<_ConsolidatedRosterSheet> {
  bool _isExporting = false;
  bool _isExportingCsv = false;

  Future<void> _exportCsv(List<String> subjects, List<ResultRecord> results) async {
    setState(() => _isExportingCsv = true);
    try {
      final periodLabel = widget.isUniversity ? (widget.selectedSemester ?? 'Semester 1') : (widget.selectedTerm ?? 'Term 1');
      final yearLabel = widget.selectedYear ?? DateTime.now().year.toString();

      List<List<dynamic>> rows = [];
      
      // Header
      rows.add(['AGE AFRICA - CONSOLIDATED ROSTER']);
      rows.add(['Group:', widget.title]);
      rows.add(['Period:', '$yearLabel $periodLabel']);
      rows.add([]);
      rows.add(['Scholar Name', 'Scholar ID', ...subjects, 'Average', 'Outcome']);

      for (var student in widget.students) {
        final studentResults = results.where((r) => r.studentId == student.id).toList();
        final yearResults = kResults.where((r) => r.studentId == student.id && r.year == yearLabel).toList();
        
        double totalMarks = 0;
        int count = 0;
        final marksData = subjects.map((sub) {
          final r = studentResults.firstWhere((r) => r.subject == sub, orElse: () => const ResultRecord(studentId: '', code: '', subject: '', marks: -1, year: ''));
          if (r.marks != -1) {
            totalMarks += r.marks;
            count++;
            return "${r.marks.toInt()}%";
          }
          return "—";
        }).toList();

        final avg = count > 0 ? (totalMarks / count).toStringAsFixed(1) : "N/A";
        
        bool hasPassed = false;
        if (widget.isUniversity) {
          hasPassed = calculateUniversityOutcome(yearResults).status != 'Fail';
        } else {
          hasPassed = calculateSecondaryOutcome(yearResults).passed;
        }

        rows.add([
          student.name.toUpperCase(),
          student.scholarId,
          ...marksData,
          avg,
          hasPassed ? "PASS" : "FAIL"
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      
      await Printing.sharePdf(bytes: bytes, filename: 'Roster_${widget.title}.csv');
    } catch (e) {
      debugPrint('CSV Export Error: $e');
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _exportPdf(List<String> subjects, List<ResultRecord> results) async {
    setState(() => _isExporting = true);
    try {
      final doc = pw.Document();
      final logo = await rootBundle.load('assets/images/age-logo.png');
      final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

      final periodLabel = widget.isUniversity ? (widget.selectedSemester ?? 'Semester 1') : (widget.selectedTerm ?? 'Term 1');
      final yearLabel = widget.selectedYear ?? DateTime.now().year.toString();

      // Dynamically calculate font size based on column count to prevent overflow
      final int totalCols = subjects.length + 3; // Scholar + subjects + AVG + Outcome
      double fontSize = 7.0;
      if (totalCols > 15) fontSize = 5.0;
      if (totalCols > 20) fontSize = 4.0;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, height: 30),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("AGE AFRICA - CONSOLIDATED ROSTER", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text("${widget.title} | $yearLabel $periodLabel", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
            ],
          ),
          build: (context) => [
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Scholar', ...subjects, 'AVG', 'Outcome'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize + 1),
              cellStyle: pw.TextStyle(fontSize: fontSize),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Scholar name gets more space
                for (int i = 1; i <= subjects.length; i++) i: const pw.FlexColumnWidth(1),
                totalCols - 2: const pw.FlexColumnWidth(1.2), // AVG
                totalCols - 1: const pw.FlexColumnWidth(1.5), // Outcome
              },
              data: widget.students.map((student) {
                final studentResults = results.where((r) => r.studentId == student.id).toList();
                final yearResults = kResults.where((r) => r.studentId == student.id && r.year == yearLabel).toList();
                
                double totalMarks = 0;
                int count = 0;
                final marksData = subjects.map((sub) {
                  final r = studentResults.firstWhere((r) => r.subject == sub, orElse: () => const ResultRecord(studentId: '', code: '', subject: '', marks: -1, year: ''));
                  if (r.marks != -1) {
                    totalMarks += r.marks;
                    count++;
                    return "${r.marks.toInt()}%";
                  }
                  return "—";
                }).toList();

                final avg = count > 0 ? (totalMarks / count).toStringAsFixed(1) : "N/A";
                
                bool hasPassed = false;
                if (widget.isUniversity) {
                  hasPassed = calculateUniversityOutcome(yearResults).status != 'Fail';
                } else {
                  hasPassed = calculateSecondaryOutcome(yearResults).passed;
                }

                return [
                  student.name.toUpperCase(),
                  ...marksData,
                  avg,
                  hasPassed ? "PASS" : "FAIL"
                ];
              }).toList(),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => doc.save(), name: 'Roster_${widget.title}.pdf');
    } catch (e) {
      debugPrint('Export Error: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pwInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Text(": ", style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final periodLabel = widget.isUniversity ? (widget.selectedSemester ?? 'Semester 1') : (widget.selectedTerm ?? 'Term 1');
    final yearLabel = widget.selectedYear ?? DateTime.now().year.toString();

    // 1. Get unique subjects for this group and sitting
    final relevantResults = kResults.where((r) {
      final matchesYear = widget.selectedYear == null || r.year == widget.selectedYear;
      
      // If no period is selected, we show all results for that year to gather subjects
      bool matchesPeriod = true;
      if (widget.isUniversity) {
        if (widget.selectedSemester != null) matchesPeriod = r.semester == widget.selectedSemester;
      } else {
        if (widget.selectedTerm != null) matchesPeriod = r.term == widget.selectedTerm;
      }

      final isStudentInGroup = widget.students.any((s) => s.id == r.studentId);
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
                      Text(widget.title.toUpperCase(),
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
                      child: Text("${widget.students.length} SCHOLARS", 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 0.5)),
                    ),
                    IconButton.filled(
                      onPressed: _isExportingCsv ? null : () => _exportCsv(subjects, relevantResults),
                      icon: _isExportingCsv 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.grid_on_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: kBrandBrown),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isExporting ? null : () => _exportPdf(subjects, relevantResults),
                      icon: _isExporting 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF9AB334)),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${widget.students.length} SCHOLARS AUDITED", 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 0.5)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isExportingCsv ? null : () => _exportCsv(subjects, relevantResults),
                          icon: _isExportingCsv
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.grid_on_rounded, size: 16),
                          label: Text(_isExportingCsv ? "EXPORTING..." : "EXPORT CSV", style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : () => _exportPdf(subjects, relevantResults),
                          icon: _isExporting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                          label: Text(_isExporting ? "GENERATING..." : "EXPORT PDF ROSTER", style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9AB334),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
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
        rows: widget.students.map((student) {
          final studentResults = results.where((r) => r.studentId == student.id).toList();
          
          // Year-wide check for completeness
          final yearResults = kResults.where((r) => r.studentId == student.id && r.year == (widget.selectedYear ?? DateTime.now().year.toString())).toList();
          final uniqueYearPeriods = yearResults.map((r) => widget.isUniversity ? r.semester : r.term).toSet().length;
          final expected = widget.isUniversity ? 2 : 3;
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
          if (widget.isUniversity) {
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

pw.Widget _pwInfoRowHelper(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
        pw.Text(": ", style: const pw.TextStyle(fontSize: 9)),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
      ],
    ),
  );
}
