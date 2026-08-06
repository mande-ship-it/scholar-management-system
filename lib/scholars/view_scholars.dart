import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import '../widgets/custom_loaders.dart';
import '../services/file_download_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import 'scholar_profile.dart';

// Shared validation patterns (kept consistent with Register Scholar).
final RegExp _kEmailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

// ============================================================
// VIEW SCHOLARS COMPONENT (registry table + profile pop-up)
// ============================================================

class ViewScholarsComponent extends StatefulWidget {
  final VoidCallback? onRegisterScholar;
  final Function(String)? onViewProfile;
  final VoidCallback? onViewGraduates;
  final String? forcedSchoolType;
  final bool hideUniversity;
  final bool hideRegistration; // Added this parameter
  const ViewScholarsComponent({
    super.key,
    this.onRegisterScholar,
    this.onViewProfile,
    this.onViewGraduates,
    this.forcedSchoolType,
    this.hideUniversity = false,
    this.hideRegistration = false, // Default to false
  });

  @override
  State<ViewScholarsComponent> createState() => _ViewScholarsComponentState();
}

class _ViewScholarsComponentState extends State<ViewScholarsComponent> with SingleTickerProviderStateMixin {
  // Search & Filter state variables
  String _searchQuery = '';
  late String _selectedSchoolType;
  String _selectedSchoolName = 'All';
  String _selectedDistrict = 'All';
  String _selectedSex = 'All';
  String _selectedClass = 'All';
  bool _isLoading = true;
  String _userRole = 'User';
  String? _assignedDistrict;
  late TabController _tabController;

  bool get _isFieldOfficer {
    final String currentRole = PermissionService.userRole ?? _userRole;
    return ['Field Officer', 'Field Coordinator', 'Field Operations', 'Operational Officer'].contains(currentRole) || widget.hideUniversity;
  }

  @override
  void initState() {
    super.initState();
    final String currentRole = PermissionService.userRole ?? 'User';
    final bool isField = ['Field Officer', 'Field Coordinator', 'Field Operations', 'Operational Officer'].contains(currentRole);
    _selectedSchoolType = isField ? 'Secondary' : (widget.forcedSchoolType ?? 'All');
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchUserRole();
    _fetchScholars();
  }

  @override
  void didUpdateWidget(ViewScholarsComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forcedSchoolType != oldWidget.forcedSchoolType) {
      setState(() {
        _selectedSchoolType = widget.forcedSchoolType ?? 'All';
        _selectedSchoolName = 'All';
        _selectedDistrict = 'All';
        _selectedClass = 'All';
      });
      _fetchScholars();
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _userRole = data['role_name'] ?? 'User';
            _assignedDistrict = data['assignedDistrict'];
            if (_isFieldOfficer) {
              _selectedSchoolType = 'Secondary';
              if (_assignedDistrict != null && _assignedDistrict!.isNotEmpty && _assignedDistrict != "All Regions") {
                _selectedDistrict = _assignedDistrict!;
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  List<String> _registeredSchoolNames = [];

  Future<void> _fetchScholars() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      debugPrint('Syncing scholars and schools from backend...');

      // Parallel fetch for efficiency
      final results = await Future.wait([
        ApiService.getAllScholars(),
        ApiService.getAllSchools(),
      ]);

      final response = results[0];
      final schoolsRes = results[1];

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];

        if (mounted) {
          setState(() {
            kStudents.clear();
            for (var item in data) {
              try {
                // Ensure we catch all variants of field names from the backend
                final String rawClass = (item['academic_year'] ?? item['academicYear'] ?? item['current_class'] ?? item['currentClass'] ?? '').toString();

                kStudents.add(Student(
                  id: (item['id'] ?? item['_id']).toString(),
                  scholarId: item['scholar_id']?.toString() ?? item['scholarId']?.toString() ?? 'N/A',
                  name: item['full_name'] ?? item['fullName'] ?? 'N/A',
                  age: item['dob'] != null && item['dob'].toString().isNotEmpty
                      ? DateTime.now().year - DateTime.parse(item['dob'].toString()).year
                      : 16,
                  schoolType: (item['school_type']?.toString().toLowerCase().contains('university') ?? false) ||
                              (item['schoolType']?.toString().toLowerCase().contains('university') ?? false)
                      ? SchoolType.university
                      : SchoolType.secondary,
                  schoolName: item['display_school_name'] ?? item['schoolName'] ?? 'N/A',
                  currentClass: rawClass.isEmpty ? 'N/A' : rawClass,
                  status: item['status'] ?? 'Active',
                  district: item['district'] ?? 'N/A',
                  village: item['village'] ?? 'N/A',
                  donor: item['donor'] ?? 'N/A',
                  phone: item['phone'] ?? 'N/A',
                  email: item['email'] ?? 'N/A',
                  sex: item['sex'] ?? 'Female',
                  dob: item['dob']?.toString() ?? '',
                  programType: item['program_type'] ?? item['programType'] ?? '',
                  programName: item['program_name'] ?? item['programName'] ?? 'N/A',
                  previousSchool: item['previous_primary_school'] ?? item['previous_school'] ?? item['previousSchool'] ?? 'N/A',
                  startYear: item['start_year']?.toString() ?? item['startYear']?.toString() ?? '2026',
                  endYear: item['end_year']?.toString() ?? item['endYear']?.toString() ?? '2030',
                  guardianName: item['guardian_name'] ?? item['guardianName'],
                  guardianPhone: item['guardian_phone'] ?? item['guardianPhone'],
                  guardianEmail: item['guardian_email'] ?? item['guardianEmail'],
                  guardianRelation: item['guardian_relation'] ?? item['guardianRelation'],
                  guardianOccupation: item['guardian_occupation'] ?? item['guardianOccupation'],
                  progressionStatus: item['progression_status'] ?? item['progressionStatus'] ?? 'Pending',
                  progressionHistory: item['progression_history'] ?? item['progressionHistory'] ?? [],
                  yearsRemaining: int.tryParse(item['years_remaining']?.toString() ?? item['yearsRemaining']?.toString() ?? '0') ?? 0,
                  registeredClass: item['registered_class'] ?? item['registeredClass'],
                  programStartYearLabel: item['program_start_year_label'] ?? item['programStartYearLabel'],
                  programDurationYears: item['program_duration_years'] ?? item['programDurationYears'] ?? 4,
                  yearsCompleted: item['years_completed'] ?? item['yearsCompleted'] ?? 0,
                  flag: item['flag'],
                ));
              } catch (e) {
                debugPrint('Failed to map scholar: $e');
              }
            }
          });
        }
      }

      if (schoolsRes.statusCode == 200) {
        final List<dynamic> sData = schoolsRes.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSchoolNames = sData
                .map((s) => s['name']?.toString() ?? '')
                .where((n) => n.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dynamic getter referencing the global kStudents database as a single source of truth
  List<Map<String, String>> get _allScholars {
    return kStudents.map((s) => {
      'id': s.id,
      'scholarId': s.scholarId,
      'name': s.name,
      'schoolType': s.schoolType == SchoolType.secondary ? 'Secondary' : 'University',
      'school': s.schoolName,
      'class': s.calculatedAcademicYear,
      'status': s.status,
      'district': s.district,
      'donor': s.donor,
      'sex': s.sex,
      'dob': s.dob,
      'village': s.village,
      'phone': s.phone,
      'email': s.email,
      'programType': s.programType,
      'programName': s.programName,
      'previousSchool': s.previousSchool,
      'startYear': s.startYear,
      'endYear': s.endYear,
      'guardianName': s.guardianName ?? '',
      'guardianPhone': s.guardianPhone ?? '',
      'guardianEmail': s.guardianEmail ?? '',
      'guardianRelation': s.guardianRelation ?? '',
      'guardianOccupation': s.guardianOccupation ?? '',
      'progressionStatus': s.progressionStatus,
      'yearsRemaining': s.calculatedRemainingYears.toString(),
    }).toList();
  }

  // Helper to get matching schools list for the dropdown filter based on selected school type
  List<String> _getAvailableSchoolsForFilter() {
    var filteredStudents = kStudents;
    if (_isFieldOfficer && _assignedDistrict != null && _assignedDistrict != "All Regions") {
      filteredStudents = filteredStudents.where((s) => s.district == _assignedDistrict).toList();
    }

    final schoolNamesFromScholars = filteredStudents.map((s) => s.schoolName).where((n) => n.isNotEmpty && n != 'N/A');
    final combinedSet = <String>{
      ..._registeredSchoolNames,
      ...schoolNamesFromScholars,
    };

    final combinedList = combinedSet.toList();
    combinedList.sort();

    if (_selectedSchoolType == 'Secondary') {
      return combinedList.where((s) => s.toLowerCase().contains('secondary') || s.toLowerCase().contains('high') || s.toLowerCase().contains('school')).toList();
    } else if (_selectedSchoolType == 'University') {
      return combinedList.where((s) => s.toLowerCase().contains('university') || s.toLowerCase().contains('college') || s.toLowerCase().contains('polytechnic')).toList();
    } else {
      return combinedList;
    }
  }

  // Filter scholars list based on current user inputs
  List<Map<String, String>> _getFilteredScholars() {
    final statusFilter = _tabController.index == 0 ? 'Active' : 'Pending';
    final bool lockDistrict = _isFieldOfficer && _assignedDistrict != null && _assignedDistrict != "All Regions";

    return _allScholars.where((scholar) {
      // 0. Filter by status based on tab
      // For University Registry, we might want to see Active or Graduated
      if (_selectedSchoolType == 'University') {
        if (_tabController.index == 0) {
           // Show both Active and Graduated/Awaiting Allocation in the active tab for University
           if (scholar['status'] != 'Active' && scholar['status'] != 'Graduated' && scholar['status'] != 'Awaiting Allocation') return false;
        } else {
           if (scholar['status'] != 'Pending') return false;
        }
      } else {
        if (scholar['status'] != statusFilter) return false;
      }

      // 1. Search by name (case-insensitive text search)
      final nameMatches = scholar['name']!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      // 2. Filter by school type
      final typeMatches = _selectedSchoolType == 'All' ||
          scholar['schoolType'] == _selectedSchoolType;

      // 3. Filter by school name
      final schoolMatches = _selectedSchoolName == 'All' ||
          scholar['school'] == _selectedSchoolName;

      // 4. Filter by district
      bool districtMatches = _selectedDistrict == 'All' ||
          scholar['district'] == _selectedDistrict;

      if (lockDistrict) {
        districtMatches = scholar['district'] == _assignedDistrict;
      }

      // 5. Filter by sex
      final sexMatches =
          _selectedSex == 'All' || scholar['sex'] == _selectedSex;

      // 6. Filter by class
      final classMatches =
          _selectedClass == 'All' || scholar['class'] == _selectedClass;

      return nameMatches && typeMatches && schoolMatches && districtMatches && sexMatches && classMatches;
    }).toList();
  }

  String _initialsOf(String name) {
    if (name.trim().isEmpty) return 'NS';
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
    final filteredScholars = _getFilteredScholars();
    final availableSchools = _getAvailableSchoolsForFilter();
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    // Executive Metrics Calculation
    final totalInSelection = filteredScholars.length;
    final activeInSelection = filteredScholars.where((s) => s['status'] == 'Active').length;
    final movingWell = filteredScholars.where((s) => s['progressionStatus'] == 'Moved').length;
    final atRisk = filteredScholars.where((s) => s['progressionStatus'] == 'Failed' || (int.tryParse(s['yearsRemaining'] ?? '5') ?? 5) <= 1).length;

    final availableClasses = _allScholars
        .where((s) => (_selectedSchoolType == 'All' || s['schoolType'] == _selectedSchoolType) &&
                      (_selectedSchoolName == 'All' || s['school'] == _selectedSchoolName))
        .map((s) => s['class'] ?? '')
        .where((c) => c.isNotEmpty && c != 'N/A')
        .toSet()
        .toList();
    availableClasses.sort();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildExecutiveHeader(totalInSelection, activeInSelection, movingWell, atRisk, isMobile),
          _buildFilterArchitecture(availableSchools, availableClasses, isMobile),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 0 : 32, 0, isMobile ? 0 : 32, isMobile ? 0 : 32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoading 
                    ? const BeautifulLoader(isOverlay: false, message: "Synchronizing Data...")
                    : Column(
                        children: [
                          _buildTabNavigation(),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildRegistrySurface(filteredScholars, isMobile),
                                _buildRegistrySurface(filteredScholars, isMobile),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(int total, int active, int moving, int risk, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBrandBrown.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedSchoolType == 'University' ? Icons.account_balance_rounded : Icons.school_rounded,
                    color: kBrandBrown, size: 28
                  ),
                ),
                const SizedBox(width: 24),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSchoolType == 'University' ? "University Scholars Registry" : "Secondary Scholars Registry",
                      style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -1),
                    ),
                    Text(
                      _isFieldOfficer && _assignedDistrict != null ? "Monitoring Region: $_assignedDistrict" : "Program-wide longitudinal tracking and oversight.",
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!isMobile) _buildGlobalActions(false),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 20),
            _buildGlobalActions(true),
          ],
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    _metricCard("TOTAL", total.toString(), Icons.groups_outlined, kBrandBrown, true),
                    const SizedBox(width: 12),
                    _metricCard("ACTIVE", active.toString(), Icons.check_circle_outline, kBrandOlive, true),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _metricCard("PROGRESS", moving.toString(), Icons.trending_up_rounded, Colors.blue, true),
                    const SizedBox(width: 12),
                    _metricCard("AT RISK", risk.toString(), Icons.warning_amber_rounded, kBrandOrange, true),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                _metricCard("TOTAL ENROLLMENT", total.toString(), Icons.groups_outlined, kBrandBrown, false),
                const SizedBox(width: 20),
                _metricCard("ACTIVE STATUS", active.toString(), Icons.check_circle_outline, kBrandOlive, false),
                const SizedBox(width: 20),
                _metricCard("PROGRESSED", moving.toString(), Icons.trending_up_rounded, Colors.blue, false),
                const SizedBox(width: 20),
                _metricCard("AT RISK", risk.toString(), Icons.warning_amber_rounded, kBrandOrange, false),
              ],
            ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, bool isMobile) {
    Widget content = Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: isMobile ? 8 : 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1), overflow: TextOverflow.ellipsis),
                Text(value, style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );

    return isMobile ? Expanded(child: content) : Expanded(child: content);
  }

  Widget _buildGlobalActions(bool isMobile) {
    return Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (_selectedSchoolType != 'University' && !_isFieldOfficer)
          isMobile 
            ? Expanded(
                child: TextButton.icon(
                  onPressed: widget.onViewGraduates,
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text("GRADUATES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: kBrandBrown),
                ),
              )
            : TextButton.icon(
                onPressed: widget.onViewGraduates,
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text("GRADUATES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: kBrandBrown),
              ),
        if (isMobile && _selectedSchoolType != 'University' && !_isFieldOfficer) const SizedBox(width: 12),
        isMobile
          ? Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onRegisterScholar,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("REGISTER"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: widget.onRegisterScholar,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("NEW REGISTRATION"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
      ],
    );
  }

  Widget _buildFilterArchitecture(List<String> availableSchools, List<String> availableClasses, bool isMobile) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF9FAFB),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _compactSearchField(isMobile)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onRegisterScholar,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: kBrandOlive),
                  style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _compactFilterDropdown("District", _selectedDistrict, kMalawiDistricts, (v) => setState(() => _selectedDistrict = v ?? 'All')),
                  const SizedBox(width: 8),
                  _compactFilterDropdown("Institution", _selectedSchoolName, availableSchools, (v) => setState(() => _selectedSchoolName = v ?? 'All')),
                  const SizedBox(width: 8),
                  _compactFilterDropdown("Level", _selectedClass, availableClasses, (v) => setState(() => _selectedClass = v ?? 'All')),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _compactSearchField(false),
                const SizedBox(width: 16),
                _compactFilterDropdown("District", _selectedDistrict, kMalawiDistricts, (v) => setState(() => _selectedDistrict = v ?? 'All')),
                const SizedBox(width: 12),
                _compactFilterDropdown("Institution", _selectedSchoolName, availableSchools, (v) => setState(() => _selectedSchoolName = v ?? 'All')),
                const SizedBox(width: 12),
                _compactFilterDropdown("Level", _selectedClass, availableClasses, (v) => setState(() => _selectedClass = v ?? 'All')),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _exportButton(Icons.description_outlined, "PDF", _exportToPDF),
          const SizedBox(width: 8),
          _exportButton(Icons.table_view_outlined, "EXCEL", _exportToExcel),
        ],
      ),
    );
  }

  Widget _compactSearchField(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: "Search by scholar name...",
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }


  Widget _compactFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: value == 'All' ? null : value,
        hint: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        items: [
          DropdownMenuItem(value: null, child: Text("All $label", style: const TextStyle(fontSize: 13))),
          ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _exportButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: kBrandBrown),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kBrandBrown)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        padding: EdgeInsets.zero,
        tabs: const [
          Tab(text: "ACTIVE REGISTRY", height: 48),
          Tab(text: "PENDING APPROVAL", height: 48),
        ],
      ),
    );
  }

  Widget _buildRegistrySurface(List<Map<String, String>> filteredScholars, bool isMobile) {
    if (filteredScholars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: isMobile ? 48 : 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text("No scholars found matching criteria.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: filteredScholars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildMobileScholarCard(filteredScholars[index]),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            headingRowHeight: 52,
            dataRowMaxHeight: 64,
            columnSpacing: 24,
            horizontalMargin: 24,
            showCheckboxColumn: false,
            columns: [
              _headerCell("ID"),
              _headerCell("FULL NAME"),
              _headerCell("INSTITUTION"),
              _headerCell("ACADEMIC YEAR"),
              _headerCell("REMAINING"),
              _headerCell("PROGRESSION"),
              _headerCell("STATUS"),
              _headerCell("ACTIONS"),
            ],
            rows: filteredScholars.map((s) => _buildDataRow(s)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileScholarCard(Map<String, String> s) {
    final isActive = s['status'] == 'Active';
    final moving = s['progressionStatus'] == 'Moved';
    final failed = s['progressionStatus'] == 'Failed';
    final remaining = int.tryParse(s['yearsRemaining'] ?? '0') ?? 0;

    return InkWell(
      onTap: () => _showScholarProfileDialog(context, s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: kBrandOlive.withOpacity(0.1), child: Text(_initialsOf(s['name']!), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14)),
                      Text("${s['scholarId']} • ${s['class']}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                _badge(s['status']!, isActive ? kBrandOlive : Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("INSTITUTION", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(s['school']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("PROGRESSION", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(moving ? Icons.arrow_upward : (failed ? Icons.warning_rounded : Icons.remove), size: 12, color: moving ? kBrandOlive : (failed ? Colors.red : Colors.grey)),
                        const SizedBox(width: 4),
                        Text(s['progressionStatus']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: moving ? kBrandOlive : (failed ? Colors.red : Colors.grey))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _headerCell(String label) {
    return DataColumn(label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1)));
  }

  DataRow _buildDataRow(Map<String, String> s) {
    final isActive = s['status'] == 'Active';
    final moving = s['progressionStatus'] == 'Moved';
    final failed = s['progressionStatus'] == 'Failed';
    final remaining = int.tryParse(s['yearsRemaining'] ?? '0') ?? 0;

    return DataRow(
      onSelectChanged: (_) => _showScholarProfileDialog(context, s),
      cells: [
        DataCell(Text(s['scholarId']!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey))),
        DataCell(
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: kBrandOlive.withOpacity(0.1), child: Text(_initialsOf(s['name']!), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kBrandBrown))),
              const SizedBox(width: 12),
              Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandBrown, fontSize: 13)),
            ],
          ),
        ),
        DataCell(Text(s['school']!, style: const TextStyle(fontSize: 13))),
        DataCell(Text(s['class']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: remaining <= 1 ? Colors.red.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
            child: Text("$remaining Years", style: TextStyle(color: remaining <= 1 ? Colors.red.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(moving ? Icons.arrow_upward : (failed ? Icons.warning_rounded : Icons.remove), size: 14, color: moving ? kBrandOlive : (failed ? Colors.red : Colors.grey)),
              const SizedBox(width: 8),
              Text(s['progressionStatus']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: moving ? kBrandOlive : (failed ? Colors.red : Colors.grey))),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? kBrandOlive.withOpacity(0.1) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(s['status']!.toUpperCase(), style: TextStyle(color: isActive ? kBrandOlive : Colors.red.shade700, fontWeight: FontWeight.w900, fontSize: 9)),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(icon: const Icon(Icons.person_search_outlined, size: 18), onPressed: () => _showScholarProfileDialog(context, s), tooltip: "Quick View"),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => showEditScholarDialog(context, s).then((_) => _fetchScholars())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showScholarProfileDialog(BuildContext context, Map<String, String> s) {
    if (widget.onViewProfile != null) {
      widget.onViewProfile!(s['id']!);
      return;
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Profile",
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
                constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Scaffold(
                    body: ScholarProfileComponent(
                      scholarId: s['id'],
                      onBack: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportToPDF() async {
    final scholars = _getFilteredScholars();
    if (scholars.isEmpty) return;

    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
      
      PdfTextElement(
        text: 'AGE AFRICA - SCHOLAR REGISTRY REPORT',
        font: titleFont,
        brush: PdfSolidBrush(PdfColor(76, 60, 50)), // kBrandBrown
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(0, 10, pageSize.width, 25),
      );

      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 6);
      grid.headers.add(1);
      
      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'Scholar ID';
      header.cells[1].value = 'Full Name';
      header.cells[2].value = 'Sex';
      header.cells[3].value = 'Institution';
      header.cells[4].value = 'Class';
      header.cells[5].value = 'Status';

      for (var s in scholars) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = s['scholarId'] ?? '';
        row.cells[1].value = s['name'] ?? '';
        row.cells[2].value = s['sex'] ?? '';
        row.cells[3].value = s['school'] ?? '';
        row.cells[4].value = s['class'] ?? '';
        row.cells[5].value = s['status'] ?? '';
      }

      for (int i = 0; i < grid.headers.count; i++) {
        final PdfGridRow headerRow = grid.headers[i];
        for (int j = 0; j < headerRow.cells.count; j++) {
          headerRow.cells[j].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(PdfColor(76, 60, 50)), // kBrandBrown
            textBrush: PdfBrushes.white,
            font: PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
          );
        }
      }

      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 50, pageSize.width, pageSize.height - 70),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      await FileDownloadService.downloadFile(
        bytes: bytes,
        fileName: 'scholar_registry_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
    }
  }

  Future<void> _exportToExcel() async {
    final scholars = _getFilteredScholars();
    if (scholars.isEmpty) return;

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Scholar Registry'];
      excel.delete('Sheet1');

      sheetObject.appendRow([
        TextCellValue('Scholar ID'),
        TextCellValue('Full Name'),
        TextCellValue('Sex'),
        TextCellValue('Institution'),
        TextCellValue('Class'),
        TextCellValue('Status'),
      ]);

      for (var s in scholars) {
        sheetObject.appendRow([
          TextCellValue(s['scholarId'] ?? ''),
          TextCellValue(s['name'] ?? ''),
          TextCellValue(s['sex'] ?? ''),
          TextCellValue(s['school'] ?? ''),
          TextCellValue(s['class'] ?? ''),
          TextCellValue(s['status'] ?? ''),
        ]);
      }

      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await FileDownloadService.downloadFile(
          bytes: Uint8List.fromList(fileBytes),
          fileName: 'scholar_registry_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        );
      }
    } catch (e) {
      debugPrint('Excel Export Error: $e');
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoItem(this.icon, this.label, this.value, {this.valueColor});
}


// ============================================================
// EDIT SCHOLAR POP-UP
// ============================================================

/// Call this to open the Edit Scholar form as a beautiful popup dialog.
/// Pass the scholar map (e.g. from a table row) or leave null to use
/// fallback demo data.
Future<void> showEditScholarDialog(
    BuildContext context,
    Map<String, String>? scholar,
    ) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Edit Scholar",
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
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
              child: EditScholarComponent(scholarData: scholar),
            ),
          ),
        ),
      );
    },
  );
}

class EditScholarComponent extends StatefulWidget {
  final Map<String, String>? scholarData;

  const EditScholarComponent({super.key, this.scholarData});

  @override
  State<EditScholarComponent> createState() => _EditScholarComponentState();
}

class _EditScholarComponentState extends State<EditScholarComponent> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _isLoadingSponsors = false;
  bool _isLoadingSchools = false;
  List<String> _registeredSponsors = [];
  List<Map<String, dynamic>> _registeredSchools = [];
  String? _selectedSchoolId;

  // Form Field States
  String? _selectedDistrict;
  String? _selectedSchoolType;
  String? _selectedSchool;
  String? _selectedProgramType;
  String? _selectedDonor;
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  String? _selectedStartYear;
  String? _selectedEndYear;
  int? _selectedDuration;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _homeVillageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _previousSchoolController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  // Data lists
  final List<String> _districts = [
    'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa',
    'Dedza', 'Dowa', 'Karonga', 'Kasungu', 'Likoma',
    'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji', 'Mulanje',
    'Mwanza', 'Mzimba', 'Neno', 'Nkhata Bay', 'Nkhotakota',
    'Nsanje', 'Ntcheu', 'Ntchisi', 'Phalombe', 'Rumphi',
    'Salima', 'Thyolo', 'Zomba'
  ];

  final List<String> _schoolTypes = ['Secondary', 'University'];
  final List<String> _sexOptions = ['Female', 'Male', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchSponsors();
    _fetchSchools();
  }

  Future<void> _fetchSponsors() async {
    setState(() => _isLoadingSponsors = true);
    try {
      final response = await ApiService.getAllSponsors();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSponsors = data.map((s) => s['name'].toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching sponsors: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSponsors = false);
    }
  }

  Future<void> _fetchSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSchools = data.map((s) => Map<String, dynamic>.from(s)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSchools = false);
    }
  }

  List<Map<String, dynamic>> _getAvailableSchoolsForScholar() {
    if (_selectedSchoolType == null) return [];

    final typeLower = _selectedSchoolType!.toLowerCase();
    return _registeredSchools.where((school) {
      final level = (school['level'] ?? '').toString().toLowerCase();

      if (typeLower == 'secondary') {
        return level.contains('secondary') || level.contains('high');
      } else if (typeLower == 'university') {
        return level.contains('university') || level.contains('tertiary') || level.contains('college');
      }
      return false;
    }).toList();
  }

  void _updateGraduationYear() {
    if (_selectedStartYear != null && _selectedDuration != null) {
      final start = int.parse(_selectedStartYear!);
      setState(() {
        _selectedEndYear = (start + _selectedDuration! - 1).toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = widget.scholarData;

      if (args != null) {
        _selectedDistrict = args['district'];
        _selectedSchoolType = args['schoolType'];
        _selectedSchool = args['school'];
        _selectedProgramType = (args['programType'] != null && args['programType']!.isNotEmpty)
            ? args['programType']
            : null;
        _selectedDonor = args['donor'];
        _selectedSex = args['sex'];
        _selectedStartYear = args['startYear'];
        _selectedEndYear = args['endYear'];

        // Calculate initial duration
        if (_selectedStartYear != null && _selectedEndYear != null) {
          try {
            final start = int.parse(_selectedStartYear!);
            final end = int.parse(_selectedEndYear!);
            _selectedDuration = (end - start) + 1;
            if (_selectedDuration! < 1 || _selectedDuration! > 6) _selectedDuration = null;
          } catch (_) {}
        }

        _fullNameController.text = args['name'] ?? '';
        _yearController.text = args['class'] ?? '';
        _homeVillageController.text = args['village'] ?? '';
        _phoneController.text = args['phone'] ?? '';
        _emailController.text = args['email'] ?? '';
        _dobController.text = args['dob'] ?? '';
        _previousSchoolController.text = args['previousSchool'] ?? '';
        _programNameController.text = args['programName'] ?? '';

        if (args['dob'] != null && args['dob']!.isNotEmpty) {
          try {
            _selectedDateOfBirth = DateTime.parse(args['dob']!);
          } catch (_) {}
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _yearController.dispose();
    _homeVillageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _previousSchoolController.dispose();
    _programNameController.dispose();
    super.dispose();
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_kEmailRegex.hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandOlive,
              onPrimary: Colors.white,
              onSurface: kBrandBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'fullName': _fullNameController.text.trim(),
        'schoolType': _selectedSchoolType,
        'schoolName': _selectedSchool,
        'schoolId': _selectedSchoolId,
        'sex': _selectedSex,
        'dob': _dobController.text.trim(),
        'currentClass': _yearController.text.trim(),
        'district': _selectedDistrict,
        'village': _homeVillageController.text.trim(),
        'donor': _selectedDonor,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'programType': _selectedProgramType ?? '',
        'programName': _programNameController.text.trim(),
        'previousSchool': _previousSchoolController.text.trim(),
        'startYear': _selectedStartYear,
        'endYear': _selectedEndYear,
      };

      try {
        final response = await ApiService.updateScholar(widget.scholarData!['id']!, updatedData);
        if (response.statusCode == 200) {
          final index = kStudents.indexWhere((s) => s.id == widget.scholarData?['id']);
          if (index != -1) {
            kStudents[index] = kStudents[index].copyWith(
              name: _fullNameController.text.trim(),
              schoolType: _selectedSchoolType == 'University' ? SchoolType.university : SchoolType.secondary,
              schoolName: _selectedSchool ?? 'N/A',
              sex: _selectedSex ?? 'Female',
              dob: _dobController.text.trim(),
              currentClass: _yearController.text.trim(),
              district: _selectedDistrict ?? 'Lilongwe',
              village: _homeVillageController.text.trim(),
              donor: _selectedDonor ?? 'General Fund',
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              programType: _selectedProgramType ?? '',
              programName: _programNameController.text.trim(),
              previousSchool: _previousSchoolController.text.trim(),
              startYear: _selectedStartYear ?? '2026',
              endYear: _selectedEndYear ?? '2030',
            );
          }
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Scholar profile updated successfully!"),
                  ],
                ),
                backgroundColor: kBrandOlive,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          final errorMsg = response.data['message'] ?? "Unknown validation error.";
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to save: $errorMsg"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Critical error: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      enabled: enabled,
      isDense: true,
      filled: true,
      fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBrandOlive, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: kBrandBrown,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> yearsList = List.generate(21, (index) => (DateTime.now().year - 5 + index).toString());
    if (_selectedStartYear != null && !yearsList.contains(_selectedStartYear)) {
      yearsList.add(_selectedStartYear!);
      yearsList.sort();
    }
    if (_selectedEndYear != null && !yearsList.contains(_selectedEndYear)) {
      yearsList.add(_selectedEndYear!);
      yearsList.sort();
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------- Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBrandBrown, kBrandOlive],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Edit Scholar Profile",
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullNameController.text.isEmpty
                              ? "Update the scholar's information"
                              : "Updating ${_fullNameController.text}",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Body ----------------
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle("Academic Information"),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      decoration: _fieldDecoration(label: "District", icon: Icons.map_outlined, helperText: "Select district in Malawi"),
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _selectedDistrict = value),
                      validator: (value) => value == null ? "Please select a district" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSchoolType,
                      decoration: _fieldDecoration(label: "School Type", icon: Icons.category_outlined),
                      items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolType = value;
                          _selectedSchool = null;
                        });
                      },
                      validator: (value) => value == null ? "Please select a school type" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _previousSchoolController,
                      decoration: _fieldDecoration(
                        label: _selectedSchoolType == 'University' ? "Previous Secondary School" : "Previous Primary School",
                        icon: Icons.history_edu_outlined,
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('school_name_$_selectedSchoolType'),
                      initialValue: _selectedSchool,
                      isExpanded: true,
                      decoration: _fieldDecoration(
                        label: _isLoadingSchools
                          ? "Loading Institutions..."
                          : (_getAvailableSchoolsForScholar().isEmpty && _selectedSchoolType != null ? "No matching schools found" : "School Name"),
                        icon: Icons.school_outlined
                      ),
                      items: _getAvailableSchoolsForScholar().map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSchool = value;
                          try {
                            final found = _registeredSchools.firstWhere((s) => s['name'] == value);
                            _selectedSchoolId = (found['id'] ?? found['_id']).toString();
                          } catch (_) {
                            _selectedSchoolId = null;
                          }
                        });
                      },
                      validator: (value) => value == null ? "Please select a school" : null,
                    ),
                    if (_selectedSchoolType == 'University') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('programType_$_selectedSchoolType'),
                        initialValue: _selectedProgramType,
                        decoration: _fieldDecoration(label: "Program Type", icon: Icons.bookmark_outline),
                        items: const [
                          DropdownMenuItem(value: "Degree", child: Text("Degree")),
                          DropdownMenuItem(value: "Diploma", child: Text("Diploma")),
                          DropdownMenuItem(value: "Certificate", child: Text("Certificate")),
                        ],
                        onChanged: (value) => setState(() => _selectedProgramType = value),
                        validator: (value) => value == null ? "Please select a program type" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _programNameController,
                        decoration: _fieldDecoration(label: "Program of Study", icon: Icons.assignment_outlined),
                        validator: (value) => (_selectedSchoolType == 'University' && (value == null || value.trim().isEmpty)) ? "Required" : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: _fieldDecoration(label: "Year / Form", icon: Icons.calendar_today_outlined, helperText: "e.g., Form 3, Year 2"),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the academic year or form" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStartYear,
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == 'University' ? "Start Year" : "Session Start",
                              icon: Icons.event_outlined,
                            ),
                            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStartYear = value;
                                _updateGraduationYear();
                              });
                            },
                            validator: (value) => value == null ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedDuration,
                            decoration: _fieldDecoration(label: "Duration", icon: Icons.timer_outlined),
                            items: [1, 2, 3, 4, 5, 6].map((d) => DropdownMenuItem(value: d, child: Text("$d Years"))).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedDuration = v;
                                _updateGraduationYear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('end_year_${_selectedStartYear}_$_selectedDuration'),
                            initialValue: _selectedEndYear,
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == 'University' ? "End Year" : "Session End",
                              icon: Icons.event_available_outlined,
                            ),
                            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (value) => setState(() => _selectedEndYear = value),
                            validator: (value) {
                              if (value == null) return "Required";
                              if (_selectedStartYear != null) {
                                final start = int.parse(_selectedStartYear!);
                                final end = int.parse(value);
                                if (end < start) return "Must be ≥ start";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle("Personal Information"),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: _fieldDecoration(label: "Full Name", icon: Icons.person_outline),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the scholar's full name" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSex,
                            decoration: _fieldDecoration(label: "Sex", icon: Icons.wc_outlined),
                            items: _sexOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (value) => setState(() => _selectedSex = value),
                            validator: (value) => value == null ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDateOfBirth(context),
                            decoration: _fieldDecoration(
                              label: "Date of Birth",
                              icon: Icons.cake_outlined,
                              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _homeVillageController,
                      decoration: _fieldDecoration(label: "Home Village", icon: Icons.home_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the home village" : null,
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle("Contact & Sponsorship"),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(label: "Phone Number", icon: Icons.phone_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the phone number" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(label: "Email Address (optional)", icon: Icons.email_outlined),
                      validator: _validateOptionalEmail,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDonor,
                      decoration: _fieldDecoration(label: "Donor / Sponsor", icon: Icons.volunteer_activism_outlined),
                      items: _registeredSponsors.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _selectedDonor = value),
                      validator: (value) => value == null ? "Please select a donor" : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ---------------- Footer Actions ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: kBrandOlive,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
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
}
