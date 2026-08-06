import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';
import '../widgets/custom_loaders.dart';

// ============================================================
// MODELS & ENUMS
// ============================================================

enum AttendanceModuleType { chats, studyCircle, classAttendance }

extension AttendanceModuleTypeLabel on AttendanceModuleType {
  String get label {
    switch (this) {
      case AttendanceModuleType.chats: return 'CHATs';
      case AttendanceModuleType.studyCircle: return 'Study Circle';
      case AttendanceModuleType.classAttendance: return 'Class Attendance';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceModuleType.chats: return Icons.forum_rounded;
      case AttendanceModuleType.studyCircle: return Icons.groups_rounded;
      case AttendanceModuleType.classAttendance: return Icons.how_to_reg_rounded;
    }
  }
}

enum AttendanceStatus { present, absent, excused }

extension AttendanceStatusData on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.excused: return 'Excused';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present: return Icons.check_circle_rounded;
      case AttendanceStatus.absent: return Icons.cancel_rounded;
      case AttendanceStatus.excused: return Icons.event_busy_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present: return const Color(0xFF2E7D32);
      case AttendanceStatus.absent: return const Color(0xFFC62828);
      case AttendanceStatus.excused: return const Color(0xFF455A64);
    }
  }
}

class AttendanceEntry {
  final Student scholar;
  AttendanceStatus status;
  String note;

  AttendanceEntry({
    required this.scholar,
    this.status = AttendanceStatus.present,
    this.note = '',
  });
}

class ScholarAttendanceComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  final AttendanceModuleType? forcedModuleType;
  const ScholarAttendanceComponent({super.key, this.forcedSchoolType, this.forcedModuleType});

  @override
  State<ScholarAttendanceComponent> createState() => _ScholarAttendanceComponentState();
}

class _ScholarAttendanceComponentState extends State<ScholarAttendanceComponent> {
  // Session Configuration
  late AttendanceModuleType _moduleType;
  late SchoolType _schoolType;
  Map<String, dynamic>? _selectedSchool;
  DateTime _selectedDate = DateTime.now();
  bool _isFieldOfficer = false;

  String _selectedYear = DateTime.now().year.toString();
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedWeek = 1;
  String? _selectedPeriod; // Term or Semester

  // State
  final TextEditingController _facilitatorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<AttendanceEntry> _entries = [];
  bool _isSaving = false;
  bool _isLoadingScholars = false;
  List<Map<String, dynamic>> _registeredSchools = [];

  @override
  void initState() {
    super.initState();
    // Default config
    _schoolType = widget.forcedSchoolType ?? SchoolType.university;
    _moduleType = widget.forcedModuleType ?? AttendanceModuleType.chats;
    
    _selectedPeriod = _schoolType == SchoolType.university ? kSemesters.first : kTerms.first;
    _fetchSchools();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final res = await ApiService.getAccountProfile();
      if (res.statusCode == 200) {
        final role = (res.data['data']['role_name'] ?? '').toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isFieldOfficer = role.contains('field') || role.contains('admin') || role.contains('manager');
          });
        }
      }
    } catch (e) {
      debugPrint('Role check error: $e');
    }
  }

  @override
  void dispose() {
    _facilitatorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
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
    }
  }

  List<Map<String, dynamic>> get _schoolOptions {
    final filtered = _registeredSchools.where((s) {
      final level = (s['level'] ?? '').toString().toLowerCase();
      if (_schoolType == SchoolType.secondary) {
        return level.contains('secondary') || level.contains('high');
      } else {
        return level.contains('university') || level.contains('tertiary');
      }
    }).toList();
    filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return filtered;
  }

  void _loadRegister() async {
    if (_selectedSchool == null) return;
    
    setState(() => _isLoadingScholars = true);
    try {
      final response = await ApiService.getScholarsBySchool(
        schoolId: _selectedSchool!['id'].toString(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _entries = data
                .where((item) => (item['status'] ?? 'Active') == 'Active')
                .map((item) => AttendanceEntry(
              scholar: Student(
                id: item['id'].toString(),
                scholarId: item['scholar_id'] ?? 'N/A',
                name: item['full_name'] ?? 'N/A',
                age: item['age'] ?? 18,
                schoolType: (item['school_type']?.toString().toLowerCase() == 'university') ? SchoolType.university : SchoolType.secondary,
                schoolName: item['display_school_name'] ?? _selectedSchool!['name'],
                currentClass: item['academic_year'] ?? 'N/A',
              ),
            )).toList();
            _isLoadingScholars = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading scholars: $e');
      if (mounted) setState(() => _isLoadingScholars = false);
    }
  }

  void _saveRegister() async {
    if (_entries.isEmpty || _selectedSchool == null) return;

    if (_facilitatorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the session facilitator name.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final attendanceData = {
        'type': _moduleType.label,
        'sessionDate': _selectedDate.toIso8601String().split('T')[0],
        'schoolId': _selectedSchool!['id'],
        'year': _selectedYear,
        'month': _selectedMonth,
        'week_number': _selectedWeek,
        'term': _schoolType == SchoolType.secondary ? _selectedPeriod : null,
        'semester': _schoolType == SchoolType.university ? _selectedPeriod : null,
        'facilitator': _facilitatorController.text.trim(),
        'location': _locationController.text.trim(),
        'entries': _entries.map((e) => {
          'scholarId': e.scholar.id,
          'status': e.status.label.toLowerCase(),
          'notes': e.note,
        }).toList(),
      };

      final response = await ApiService.saveAttendance(attendanceData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance for ${_moduleType.label} session saved successfully.'),
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() {
            _entries = [];
            _selectedSchool = null;
            _facilitatorController.clear();
            _locationController.clear();
          });
        }
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save attendance.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 40, isMobile ? 12 : 32, isMobile ? 12 : 40, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConfigSection(isMobile),
                      const SizedBox(height: 32),
                      if (_isLoadingScholars)
                        const Center(child: Padding(padding: EdgeInsets.all(100), child: BeautifulLoader(isOverlay: false, message: "Opening School Registry")))
                      else if (_entries.isNotEmpty) ...[
                        if (isMobile && _isFieldOfficer) 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    for (var e in _entries) e.status = AttendanceStatus.present;
                                  });
                                },
                                icon: const Icon(Icons.done_all_rounded, size: 16),
                                label: const Text("MARK ALL PRESENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        _buildFacilitatorSection(isMobile),
                        const SizedBox(height: 32),
                        if (isMobile) 
                          _buildMobileAttendanceList()
                        else 
                          _buildAttendanceTable()
                      ] else
                        _buildPlaceholder(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_entries.isNotEmpty) _buildFooterActions(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrandBrown.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_moduleType.icon, color: kBrandBrown, size: 18),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isFieldOfficer ? "Attendance Management" : "Attendance Records",
                  style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.2)),
                Row(
                  children: [
                    Text(_isFieldOfficer ? "Recording ${_moduleType.label}" : "Telemetry",
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text("Target: 1 Session / Week", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kBrandOlive, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!_isFieldOfficer && !isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3))
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("READ-ONLY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 0.5)),
                ],
              ),
            ),
          if (_entries.isNotEmpty && _isFieldOfficer)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  for (var e in _entries) e.status = AttendanceStatus.present;
                });
              },
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: Text(isMobile ? "ALL PRESENT" : "MARK ALL PRESENT", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(bool isMobile) {
    final periodLabel = _schoolType == SchoolType.university ? "Academic Semester" : "School Term";
    final periods = _schoolType == SchoolType.university ? kSemesters : kTerms;

    if (isMobile) {
      return Column(
        children: [
          _dropdownField("Partner Institution", _selectedSchool, _schoolOptions, (v) {
            setState(() {
              _selectedSchool = v;
              _loadRegister();
            });
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dropdownFieldString(periodLabel, _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!))),
              const SizedBox(width: 12),
              Expanded(child: _dropdownFieldString("Year", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!))),
            ],
          ),
          const SizedBox(height: 16),
          _datePickerField(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _dropdownField("Partner Institution", _selectedSchool, _schoolOptions, (v) {
                setState(() {
                  _selectedSchool = v;
                  _loadRegister();
                });
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dropdownFieldString(periodLabel, _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dropdownFieldString("Year", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _datePickerField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _configColumn(
                label: "METADATA",
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                        "Cycle: $_selectedMonth | Week $_selectedWeek",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilitatorSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SESSION LOGISTICS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        if (isMobile) ...[
          _textField(_facilitatorController, "Primary Facilitator", Icons.person_pin_rounded, "Name..."),
          const SizedBox(height: 16),
          _textField(_locationController, "Venue", Icons.place_rounded, "e.g. Science Lab..."),
        ] else
          Row(
            children: [
              Expanded(child: _textField(_facilitatorController, "Primary Facilitator", Icons.person_pin_rounded, "Name...")),
              const SizedBox(width: 16),
              Expanded(child: _textField(_locationController, "Venue", Icons.place_rounded, "e.g. Science Lab...")),
            ],
          ),
      ],
    );
  }

  Widget _buildMobileAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("REGISTER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
            _countBadge("${_entries.where((e) => e.status == AttendanceStatus.present).length} P / ${_entries.where((e) => e.status == AttendanceStatus.absent).length} A", kBrandOlive),
          ],
        ),
        const SizedBox(height: 16),
        ..._entries.map((entry) => _buildMobileAttendanceCard(entry)),
      ],
    );
  }

  Widget _buildMobileAttendanceCard(AttendanceEntry entry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kBrandOlive.withOpacity(0.1),
                child: Text(getInitials(entry.scholar.name), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.scholar.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : kBrandBrown)),
                    Text("${entry.scholar.scholarId} • ${entry.scholar.currentClass}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusPicker(entry, isMobile: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: (v) => entry.note = v,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : kBrandBrown),
              decoration: InputDecoration(
                hintText: "Add specific remarks...",
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPicker(AttendanceEntry entry, {bool isMobile = false}) {
    return IgnorePointer(
      ignoring: !_isFieldOfficer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: AttendanceStatus.values.map((status) {
          final isSelected = entry.status == status;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
              child: InkWell(
                onTap: () => setState(() => entry.status = status),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? status.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? status.color : Colors.grey.shade300,
                      width: 1.2
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(status.icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade400),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          status.label.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooterActions(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: isMobile 
        ? Column(
            children: [
              Text(
                "AUDIT DECLARATION: By authorizing, you certify that the telemetry recorded is accurate.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (_isFieldOfficer)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveRegister,
                    icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_isSaving ? "SYNCING..." : "VALIDATE & SAVE",
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          )
        : Row(
            children: [
              Icon(Icons.verified_user_rounded, color: kBrandOlive.withOpacity(0.6), size: 24),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  "AUDIT DECLARATION: By authorizing, you certify that the telemetry recorded for this session is accurate and consistent with program engagement standards.",
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600, height: 1.5),
                ),
              ),
              const SizedBox(width: 60),
              if (_isFieldOfficer)
                SizedBox(
                  width: 380,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveRegister,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_isSaving ? "SYNCHRONIZING..." : "VALIDATE & SAVE REGISTER",
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildPlaceholder(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          SizedBox(height: isMobile ? 60 : 120),
          Container(
            padding: EdgeInsets.all(isMobile ? 32 : 48),
            decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(Icons.assignment_ind_rounded, size: isMobile ? 60 : 80, color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          const SizedBox(height: 32),
          Text(_selectedSchool == null ? "Select an institution" : "No active scholars found",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
            child: Row(
              children: [
                Text("SCHOLAR ATTENDANCE REGISTER",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isDark ? Colors.white70 : Colors.grey, letterSpacing: 1.2)),
                const Spacer(),
                _countBadge("${_entries.where((e) => e.status == AttendanceStatus.present).length} PRESENT", Colors.green),
                const SizedBox(width: 20),
                _countBadge("${_entries.where((e) => e.status == AttendanceStatus.absent).length} ABSENT", Colors.red),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 200),
              child: DataTable(
                headingRowHeight: 64,
                dataRowMaxHeight: 80,
                horizontalMargin: 32,
                columnSpacing: 32,
                dividerThickness: 0.5,
                columns: [
                  DataColumn(label: Text("IDENTIFIER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : kBrandBrown, letterSpacing: 1))),
                  DataColumn(label: Text("SCHOLAR IDENTITY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : kBrandBrown, letterSpacing: 1))),
                  DataColumn(label: Text("PARTICIPATION STATUS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : kBrandBrown, letterSpacing: 1))),
                  DataColumn(label: Text("SITTING REMARKS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : kBrandBrown, letterSpacing: 1))),
                ],
                rows: _entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.scholar.scholarId, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? kBrandOrange : Colors.blueGrey, fontSize: 13))),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: kBrandOlive.withOpacity(0.1),
                              child: Text(getInitials(entry.scholar.name), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive)),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.scholar.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : kBrandBrown)),
                                Text(entry.scholar.currentClass, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
                      ),
                      DataCell(_buildStatusPicker(entry)),
                      DataCell(
                        TextField(
                          onChanged: (v) => entry.note = v,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : kBrandBrown),
                          decoration: InputDecoration(
                            hintText: "Add specific sitting notes...",
                            hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.grey.shade400),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _configColumn({required String label, required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _dropdownField(String label, dynamic value, List<Map<String, dynamic>> items, ValueChanged<Map<String, dynamic>?> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
          child: DropdownButton<Map<String, dynamic>>(
            value: value,
            isExpanded: true,
            dropdownColor: theme.cardColor,
            hint: const Text("Select institution...", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            underline: const SizedBox(),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s['name'] ?? '',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _dropdownFieldString(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: theme.cardColor,
            underline: const SizedBox(),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _textField(TextEditingController controller, String label, IconData icon, String hint) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: controller,
            enabled: _isFieldOfficer,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : kBrandBrown, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white24 : Colors.grey),
              border: InputBorder.none,
              icon: Icon(icon, size: 20, color: kBrandOlive),
            ),
          ),
        ),
      ],
    );
  }

  void _updateMetadata(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedYear = date.year.toString();
      _selectedMonth = DateFormat('MMMM').format(date);
      _selectedWeek = ((date.day - 1) / 7).floor() + 1;
    });
  }

  Widget _datePickerField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SESSION DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
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
            if (picked != null) _updateMetadata(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20, color: kBrandOlive),
                const SizedBox(width: 16),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : kBrandBrown)),
                const Spacer(),
                Text("Cycle: $_selectedMonth", style: const TextStyle(fontSize: 11, color: kBrandOlive, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
