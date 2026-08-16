import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'scholar_attendance.dart';

enum ViewAttendanceMode { selection, secondary, university }

String _initialsOf(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

class ViewAttendanceComponent extends StatefulWidget {
  final VoidCallback? onMarkAttendance;
  final VoidCallback? onBack;
  const ViewAttendanceComponent({super.key, this.onMarkAttendance, this.onBack});

  @override
  State<ViewAttendanceComponent> createState() => _ViewAttendanceComponentState();
}

class _ViewAttendanceComponentState extends State<ViewAttendanceComponent> with SingleTickerProviderStateMixin {
  ViewAttendanceMode _mode = ViewAttendanceMode.selection;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String? _selectedDistrict;
  String? _selectedSchool;
  String? _selectedScholarId;
  String? _selectedYear;
  String? _selectedTerm;
  String? _selectedSemester;
  String _statusFilter = 'All';

  bool _isLoading = false;
  bool _isSearchExpanded = false;
  Map<String, Map<String, dynamic>> _reportSummaryMap = {};
  List<Student> _allScholars = [];
  List<Map<String, dynamic>> _allSchools = [];

  final List<String> _academicYears = academicYearOptions();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _fetchScholars(),
      _fetchSchools(),
    ]);
    _fetchReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
    try {
      final res = await ApiService.getAllSchools();
      if (res.statusCode == 200) {
        if (mounted) setState(() => _allSchools = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
      }
    } catch (e) { debugPrint('Error schools: $e'); }
  }

  Future<void> _fetchScholars() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllScholars();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _allScholars = data.map((s) => Student.fromMap(s)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching scholars: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReport() async {
    if (_mode == ViewAttendanceMode.selection) return;

    setState(() => _isLoading = true);
    try {
      String? schoolId;
      if (_selectedSchool != null) {
        try {
          final school = _allSchools.firstWhere((s) => s['name'] == _selectedSchool);
          schoolId = (school['id'] ?? school['_id']).toString();
        } catch (_) {}
      }

      final response = await ApiService.getSchoolAttendanceReport(
        schoolId,
        month: null,
        year: _selectedYear,
        term: _selectedTerm,
        semester: _selectedSemester,
        schoolType: _mode == ViewAttendanceMode.university ? 'University' : 'Secondary',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _reportSummaryMap = {
              for (var item in data) item['_id'].toString(): Map<String, dynamic>.from(item)
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _availableSchools {
    final type = _mode == ViewAttendanceMode.university ? SchoolType.university : SchoolType.secondary;
    final students = _allScholars.where((s) => s.schoolType == type);

    Iterable<Student> filtered = students;
    if (_selectedDistrict != null && _mode == ViewAttendanceMode.secondary) {
      filtered = filtered.where((s) => s.district == _selectedDistrict);
    }

    return filtered.map((s) => s.schoolName).toSet().toList()..sort();
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    final bool showingArchive = _tabController.index == 1;
    final type = _mode == ViewAttendanceMode.university ? SchoolType.university : SchoolType.secondary;

    return _allScholars.where((s) {
      if (s.schoolType != type) return false;

      final bool isAlumni = s.status == 'Alumni' || s.status == 'Graduated' || s.status == 'Completed';
      if (showingArchive && !isAlumni) return false;
      if (!showingArchive && isAlumni) return false;

      final matchesQuery = query.isEmpty || s.name.toLowerCase().contains(query);
      final matchesDistrict = _selectedDistrict == null || s.district == _selectedDistrict;
      final matchesSchool = _selectedSchool == null || s.schoolName == _selectedSchool;

      if (_statusFilter != 'All') {
        final summary = _reportSummaryMap[s.id];
        final rate = summary?['attendanceRate'] ?? 0;
        if (_statusFilter == 'Critical' && rate >= 50) return false;
        if (_statusFilter == 'On Track' && rate < 85) return false;
      }

      return matchesQuery && matchesDistrict && matchesSchool;
    }).toList();
  }

  void _openConsolidatedRoster() {
    final String title = _selectedSchool ?? _selectedDistrict ?? 'Selected Group';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _ConsolidatedAttendanceRoster(
          title: title,
          year: _selectedYear ?? DateTime.now().year.toString(),
          period: (_mode == ViewAttendanceMode.university ? _selectedSemester : _selectedTerm) ?? 'Whole Year',
          data: _reportSummaryMap.values.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ViewAttendanceMode.selection) {
      return _buildSelectionScreen();
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final students = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          _buildFilterBar(isMobile),
          _buildTabNavigation(),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : students.isEmpty
                ? _buildNoResultsState()
                : _buildScholarGrid(students, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
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
              _mode = ViewAttendanceMode.selection;
              _selectedDistrict = null;
              _selectedSchool = null;
              _selectedYear = null;
              _selectedTerm = null;
              _selectedSemester = null;
              _reportSummaryMap = {};
            }),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: kBrandBrown),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          if (!_isSearchExpanded)
            Expanded(
              child: Text(
                _mode == ViewAttendanceMode.university ? "Uni Participation" : "Sec Participation",
                style: TextStyle(fontSize: isVerySmall ? 13 : 16, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_isSearchExpanded)
            Expanded(child: _buildSearchField(isMobile))
          else
            _buildSearchField(isMobile),
          if (!_isSearchExpanded) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _openConsolidatedRoster,
              icon: const Icon(Icons.grid_view_rounded, color: kBrandBrown, size: 20),
              tooltip: "Consolidated Roster",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                _fetchScholars();
                _fetchReport();
              },
              icon: Icon(Icons.sync_rounded, color: kBrandOlive, size: 22),
              tooltip: "Sync Records",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isMobile) {
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
      height: 40,
      width: isMobile ? double.infinity : 280,
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
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() {
              _isSearchExpanded = false;
              _searchController.clear();
            }),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (_mode == ViewAttendanceMode.secondary) ...[
              _portalCompactDropdown("District", _selectedDistrict, kMalawiDistricts, (v) {
                setState(() { _selectedDistrict = v; _selectedSchool = null; });
                _fetchReport();
              }),
              const SizedBox(width: 8),
            ],
            _portalCompactDropdown(_mode == ViewAttendanceMode.university ? "University" : "School", _selectedSchool, _availableSchools, (v) {
              setState(() => _selectedSchool = v);
              _fetchReport();
            }),
            const SizedBox(width: 8),
            _portalCompactDropdown("Year", _selectedYear, _academicYears, (v) {
              setState(() => _selectedYear = v);
              _fetchReport();
            }),
            const SizedBox(width: 8),
            if (_mode == ViewAttendanceMode.secondary)
              _portalCompactDropdown("Term", _selectedTerm, ['Term 1', 'Term 2', 'Term 3'], (v) {
                setState(() => _selectedTerm = v);
                _fetchReport();
              })
            else
              _portalCompactDropdown("Semester", _selectedSemester, ['Semester 1', 'Semester 2'], (v) {
                setState(() => _selectedSemester = v);
                _fetchReport();
              }),
            const SizedBox(width: 8),
            _portalCompactDropdown("Status", _statusFilter, ['All', 'On Track', 'Critical'], (v) {
              setState(() => _statusFilter = v!);
            }),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(text: "ACTIVE REGISTRY", height: isVerySmall ? 40 : 48),
          Tab(text: "HISTORICAL ARCHIVE", height: isVerySmall ? 40 : 48)
        ],
      ),
    );
  }

  Widget _portalCompactDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          items: [
            DropdownMenuItem(value: null, child: Text("All $label", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.how_to_reg_rounded, size: 64, color: kBrandBrown),
              const SizedBox(height: 24),
              const Text("Attendance Archives", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text("Select institutional level to audit participation logs.", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              if (isMobile)
                Column(
                  children: [
                    _selectionCard("Secondary Schools", "Audit participation in CHATs and classroom registers.", Icons.school_rounded, kBrandOrange, () => setState(() => _mode = ViewAttendanceMode.secondary)),
                    const SizedBox(height: 20),
                    _selectionCard("Universities", "Monitor engagement in tertiary education sessions.", Icons.account_balance_rounded, Colors.blue.shade700, () => setState(() => _mode = ViewAttendanceMode.university)),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _selectionCard("Secondary Schools", "Audit participation in CHATs and classroom registers across all districts.", Icons.school_rounded, kBrandOrange, () => setState(() => _mode = ViewAttendanceMode.secondary)),
                    const SizedBox(width: 32),
                    _selectionCard("Universities / Tertiary", "Monitor engagement in tertiary education sessions and academic workshops.", Icons.account_balance_rounded, Colors.blue.shade700, () => setState(() => _mode = ViewAttendanceMode.university)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kBrandBrown)),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Proceed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarGrid(List<Student> students, bool isMobile) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 12 : 32
      ),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        final summary = _reportSummaryMap[student.id];
        return _buildScholarCard(student, summary, isMobile);
      },
    );
  }

  Widget _buildScholarCard(Student s, Map<String, dynamic>? summary, bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final int rate = summary?['attendanceRate'] ?? 0;
    final int present = summary?['present_count'] ?? 0;
    final int total = summary?['total_sessions'] ?? 0;

    Color statusColor = rate >= 85 ? kBrandOlive : (rate >= 50 ? Colors.orange : Colors.red);
    if (total == 0) statusColor = Colors.grey.shade300;

    final bool hasData = total > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openScholarParticipationSheet(s),
          child: Padding(
            padding: EdgeInsets.all(isVerySmall ? 16 : 24),
            child: isVerySmall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: kBrandOlive.withOpacity(0.1),
                          child: Text(_initialsOf(s.name), style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 11)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kBrandBrown, letterSpacing: -0.2),
                                overflow: TextOverflow.ellipsis),
                              Text(s.scholarId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        if (hasData)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("$rate%", style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 18, letterSpacing: -0.5)),
                              _portalBadge(rate >= 85 ? "STABLE" : "ALERT", statusColor),
                            ],
                          )
                        else
                          const Icon(Icons.history_toggle_off_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.schoolName, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: kBrandOlive.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: kBrandOlive.withOpacity(0.2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(_initialsOf(s.name), style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 18)),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kBrandBrown, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _miniLabelChip(Icons.badge_outlined, s.scholarId),
                              const SizedBox(width: 12),
                              _miniLabelChip(Icons.location_on_outlined, s.district),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.schoolName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(hasData ? "$present of $total logs recorded" : "No telemetry logs",
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(hasData ? "$rate%" : "0%", style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 28, letterSpacing: -1.5)),
                        const SizedBox(height: 4),
                        _portalBadge(
                          hasData ? (rate >= 85 ? "EXCELLENT" : (rate >= 50 ? "NOMINAL engagement" : "CRITICAL ALERT")) : "PENDING DATA",
                          statusColor
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _miniLabelChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
        ],
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

  void _openScholarParticipationSheet(Student student) {
    showDialog(
      context: context,
      builder: (context) => _ScholarParticipationSheet(
        scholarId: student.id,
        scholarName: student.name,
        ageId: student.scholarId,
        year: _selectedYear ?? DateTime.now().year.toString(),
        term: _selectedTerm,
        semester: _selectedSemester,
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text("No scholars found matching current filters.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ConsolidatedAttendanceRoster extends StatelessWidget {
  final String title;
  final String year;
  final String period;
  final List<Map<String, dynamic>> data;

  const _ConsolidatedAttendanceRoster({
    required this.title,
    required this.year,
    required this.period,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isVerySmall ? 0 : 24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmall ? 20 : 40),
            color: const Color(0xFF4C3C32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: isVerySmall ? 18 : 24, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                      const SizedBox(height: 4),
                      Text(isVerySmall ? "$year $period" : "OFFICIAL CONSOLIDATED ATTENDANCE ROSTER — $year $period",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24)
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: data.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text("Audit pool empty.", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                      ],
                    ))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isVerySmall ? 12 : 40),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 15)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                            headingRowHeight: 60,
                            dataRowMaxHeight: 72,
                            horizontalMargin: 24,
                            columnSpacing: 40,
                            headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1.2),
                            columns: const [
                              DataColumn(label: Text("IDENTIFIER")),
                              DataColumn(label: Text("SCHOLAR NAME")),
                              DataColumn(label: Text("PARTICIPATION")),
                              DataColumn(label: Text("RATIO (%)")),
                              DataColumn(label: Text("AUDIT STATUS")),
                            ],
                            rows: data.map((item) {
                              final int rate = item['attendanceRate'] ?? 0;
                              final status = item['status'] ?? 'N/A';
                              Color statusColor = rate >= 85 ? kBrandOlive : (rate >= 50 ? Colors.orange : Colors.red);

                              return DataRow(cells: [
                                DataCell(Text(item['age_id'] ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12))),
                                DataCell(Text(item['scholar_name']?.toString().toUpperCase() ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kBrandBrown))),
                                DataCell(Row(
                                  children: [
                                    Text("${item['present_count'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kBrandBrown)),
                                    Text(" / ${item['total_sessions'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                  ],
                                )),
                                DataCell(Text("$rate%", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: statusColor, letterSpacing: -0.5))),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status.toString().toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 20 : 40, vertical: 24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                if (!isMobile)
                  Text("${data.length} SCHOLARS AUDITED IN THIS SITTING",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 0.5)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text("EXPORT CSV", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    foregroundColor: kBrandBrown,
                    side: const BorderSide(color: Color(0xFFEEEEEE), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text("PRINT PDF ROSTER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScholarParticipationSheet extends StatefulWidget {
  final String scholarId;
  final String scholarName;
  final String ageId;
  final String year;
  final String? term;
  final String? semester;

  const _ScholarParticipationSheet({
    required this.scholarId,
    required this.scholarName,
    required this.ageId,
    required this.year,
    this.term,
    this.semester,
  });

  @override
  State<_ScholarParticipationSheet> createState() => _ScholarParticipationSheetState();
}

class _ScholarParticipationSheetState extends State<_ScholarParticipationSheet> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await ApiService.getScholarAttendanceHistory(
        widget.scholarId,
        year: widget.year,
        term: widget.term,
        semester: widget.semester,
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _sessions = res.data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isVerySmall ? 0 : 24)),
      insetPadding: EdgeInsets.all(isVerySmall ? 0 : 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isVerySmall ? 20 : 40),
              decoration: BoxDecoration(
                color: kBrandOlive.withOpacity(0.04),
                borderRadius: BorderRadius.vertical(top: Radius.circular(isVerySmall ? 0 : 24)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isVerySmall ? 24 : 36,
                    backgroundColor: kBrandOlive,
                    child: Text(_initialsOf(widget.scholarName), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: isVerySmall ? 14 : 20)),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.scholarName.toUpperCase(),
                          style: TextStyle(fontSize: isVerySmall ? 16 : 22, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text("${widget.ageId} • VERIFIED ACADEMIC PARTICIPATION LOG",
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 24, color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                : _sessions.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text("No telemetry recorded for ${widget.year}.",
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
                      ],
                    ))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isVerySmall ? 16 : 32),
                      child: Column(
                        children: [
                          _buildParticipationKPIs(isVerySmall),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                                headingRowHeight: 52,
                                dataRowMaxHeight: 64,
                                columnSpacing: isVerySmall ? 20 : 32,
                                horizontalMargin: 20,
                                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.0),
                                columns: const [
                                  DataColumn(label: Text("SESSION DATE")),
                                  DataColumn(label: Text("EVENT TYPE")),
                                  DataColumn(label: Text("STATUS")),
                                  DataColumn(label: Text("VENUE / FACILITATOR")),
                                ],
                                rows: _sessions.map((s) {
                                  final session = s['session'] ?? {};
                                  final date = DateTime.tryParse(session['sessionDate'] ?? '') ?? DateTime.now();
                                  final isPresent = s['status'] == 'present';

                                  return DataRow(cells: [
                                    DataCell(Text(DateFormat('dd MMMM yyyy').format(date),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandBrown))),
                                    DataCell(Text(session['type']?.toString().toUpperCase() ?? 'N/A',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey))),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isPresent ? Colors.green : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(s['status']?.toString().toUpperCase() ?? 'N/A',
                                        style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.w900)),
                                    )),
                                    DataCell(Text(session['facilitator'] ?? 'General Session',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 20 : 40, vertical: 24),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
              child: Row(
                children: [
                  if (!isVerySmall)
                    const Expanded(
                      child: Text("OFFICIAL AGE AFRICA TRANSCRIPT",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text("EXPORT LOGS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationKPIs(bool isVerySmall) {
    final int present = _sessions.where((s) => s['status'] == 'present').length;
    final int total = _sessions.length;
    final double rate = total > 0 ? (present / total) * 100 : 0;

    return Row(
      children: [
        _miniKPI("TOTAL SESSIONS", "$total", kBrandBrown, isVerySmall),
        const SizedBox(width: 16),
        _miniKPI("ATTENDED", "$present", kBrandOlive, isVerySmall),
        const SizedBox(width: 16),
        _miniKPI("QUORUM RATE", "${rate.toInt()}%", rate >= 85 ? kBrandOlive : Colors.orange, isVerySmall),
      ],
    );
  }

  Widget _miniKPI(String label, String value, Color color, bool isVerySmall) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isVerySmall ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: isVerySmall ? 18 : 24, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
