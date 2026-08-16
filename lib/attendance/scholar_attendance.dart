import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';

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
  final VoidCallback? onBack;
  final bool showBackButton;
  const ScholarAttendanceComponent({
    super.key,
    this.forcedSchoolType,
    this.forcedModuleType,
    this.onBack,
    this.showBackButton = true,
  });

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
  bool _canRecord = false;
  String? _officerDistrict;

  String _selectedYear = DateTime.now().year.toString();
  int _selectedMonth = DateTime.now().month;
  int _selectedWeek = 1;
  String? _selectedPeriod; // Term or Semester

  // State
  final TextEditingController _facilitatorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<AttendanceEntry> _entries = [];
  bool _isSaving = false;
  bool _isLoadingScholars = false;
  List<Map<String, dynamic>> _registeredSchools = [];

  List<AttendanceModuleType> get _moduleOptions {
    if (widget.forcedModuleType != null) {
      return [widget.forcedModuleType!];
    }
    if (_schoolType == SchoolType.university) {
      return [AttendanceModuleType.chats];
    } else {
      return [AttendanceModuleType.chats, AttendanceModuleType.classAttendance];
    }
  }

  @override
  void initState() {
    super.initState();
    _schoolType = widget.forcedSchoolType ?? SchoolType.university;
    _moduleType = widget.forcedModuleType ?? AttendanceModuleType.chats;
    
    _selectedPeriod = _schoolType == SchoolType.university ? kSemesters.first : kTerms.first;

    // Auto-calculate week, month and year
    final now = DateTime.now();
    _selectedDate = now;
    _selectedMonth = now.month;
    _selectedYear = now.year.toString();
    _selectedWeek = ((now.day - 1) / 7).floor() + 1;

    _fetchSchools();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final res = await ApiService.getAccountProfile();
      if (res.statusCode == 200) {
        final data = res.data['data'];
        final role = (data['role_name'] ?? '').toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isFieldOfficer = role.contains('field');
            _canRecord = _isFieldOfficer || role.contains('admin') || role.contains('manager') || role.contains('director') || role.contains('coordinator');
            _officerDistrict = data['assignedDistrict'] ?? data['district'];
            if (_isFieldOfficer) {
              _schoolType = SchoolType.secondary; // Force secondary for Field Officers
            }
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
      final district = (s['district'] ?? '').toString();

      bool matchesLevel = false;
      if (_schoolType == SchoolType.secondary) {
        matchesLevel = level.contains('secondary') || level.contains('high');
      } else {
        matchesLevel = level.contains('university') || level.contains('tertiary');
      }

      bool matchesDistrict = true;
      if (_isFieldOfficer && _officerDistrict != null) {
        matchesDistrict = district == _officerDistrict;
      }

      return matchesLevel && matchesDistrict;
    }).toList();
    filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return filtered;
  }

  void _loadRegister() async {
    if (_selectedSchool == null) return;
    
    setState(() => _isLoadingScholars = true);
    try {
      final schoolId = (_selectedSchool!['id'] ?? _selectedSchool!['_id']).toString();
      final response = await ApiService.getScholarsBySchool(
        schoolId: schoolId,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _entries = data
                .where((item) => (item['status'] ?? 'Active') == 'Active')
                .map((item) => AttendanceEntry(
              scholar: Student.fromMap(item),
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
      final schoolId = (_selectedSchool!['id'] ?? _selectedSchool!['_id']).toString();
      final attendanceData = {
        'type': _moduleType.label,
        'sessionDate': _selectedDate.toIso8601String().split('T')[0],
        'schoolId': schoolId,
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
            const SnackBar(
              content: Text('Attendance securely synchronized with the central repository.'),
              backgroundColor: Color(0xFF9AB334),
              behavior: SnackBarBehavior.floating,
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          _buildConfigBar(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoadingScholars)
                        const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: kBrandOlive)))
                      else if (_entries.isNotEmpty) ...[
                        _sectionPortalLabel("Sitting logistics", Icons.local_shipping_rounded),
                        const SizedBox(height: 16),
                        _buildPortalLogisticsPanel(isMobile),
                        const SizedBox(height: 40),

                        _sectionPortalLabel("Attendance register", Icons.fact_check_rounded),
                        const SizedBox(height: 16),
                        if (isMobile) 
                          _buildMobileAttendanceList()
                        else 
                          _buildPortalAttendanceTable(),
                        const SizedBox(height: 60),
                      ] else
                        _buildPortalPlaceholder(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_entries.isNotEmpty) _buildPortalFixedFooter(isMobile),
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
          if (widget.showBackButton) ...[
            IconButton(
              onPressed: widget.onBack ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              _isFieldOfficer ? "Session Telemetry" : "Attendance Audit",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_entries.isNotEmpty && _canRecord)
            IconButton(
              onPressed: () => setState(() {
                for (var e in _entries) e.status = AttendanceStatus.present;
              }),
              icon: Icon(Icons.done_all_rounded, color: const Color(0xFF9AB334), size: isVerySmall ? 20 : 24),
              tooltip: "Mark All Present",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _entries = [];
                _selectedSchool = null;
                _facilitatorController.clear();
                _locationController.clear();
              });
            },
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: isVerySmall ? 18 : 22),
            tooltip: "Reset",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigBar(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 12 : (isMobile ? 16 : 32),
        vertical: isVerySmall ? 8 : 12
      ),
      child: _buildPortalConfigPanel(isMobile),
    );
  }

  Widget _sectionPortalLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          title, 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            color: Colors.grey.shade500, 
            letterSpacing: 1.2
          )
        ),
      ],
    );
  }

  Widget _portalSelectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.0)),
    );
  }

  Widget _buildPortalConfigPanel(bool isMobile) {
    return isMobile ? _buildMobileConfig() : _buildDesktopConfig();
  }

  Widget _buildMobileConfig() {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final bool isExtremeSmall = MediaQuery.of(context).size.width < 400;
    final periods = _schoolType == SchoolType.university ? kSemesters : kTerms;

    return Column(
      children: [
        _portalDropdown("Institution", _selectedSchool, _schoolOptions, (v) {
          setState(() {
            _selectedSchool = v;
            _loadRegister();
          });
        }),
        SizedBox(height: isVerySmall ? 12 : 16),
        if (widget.forcedModuleType == null) ...[
          _portalDropdown<AttendanceModuleType>(
            "Attendance Type",
            _moduleType,
            _moduleOptions,
            (v) => setState(() => _moduleType = v!),
            itemLabel: (v) => v.label,
          ),
          SizedBox(height: isVerySmall ? 12 : 16),
        ],
        if (isExtremeSmall) ...[
          _portalDropdown("Cycle", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!)),
          const SizedBox(height: 12),
          _portalDropdown("Period", _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!)),
        ] else
          Row(
            children: [
              Expanded(child: _portalDropdown("Cycle", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!))),
              const SizedBox(width: 12),
              Expanded(child: _portalDropdown("Period", _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!))),
            ],
          ),
        SizedBox(height: isVerySmall ? 12 : 16),
        _portalDatePickerField(),
      ],
    );
  }

  Widget _buildDesktopConfig() {
    final periods = _schoolType == SchoolType.university ? kSemesters : kTerms;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _portalDropdown("Partner Institution", _selectedSchool, _schoolOptions, (v) {
                setState(() {
                  _selectedSchool = v;
                  _loadRegister();
                });
              }),
            ),
            if (widget.forcedModuleType == null) ...[
              const SizedBox(width: 20),
              Expanded(
                child: _portalDropdown<AttendanceModuleType>(
                  "Attendance Type",
                  _moduleType,
                  _moduleOptions,
                  (v) => setState(() => _moduleType = v!),
                  itemLabel: (v) => v.label,
                ),
              ),
            ],
            const SizedBox(width: 20),
            Expanded(
              child: _portalDropdown("Academic Cycle", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _portalDropdown("Period / Term", _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _portalDatePickerField()),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text("Telemetry Log: ${DateFormat('MMMM').format(DateTime(int.parse(_selectedYear), _selectedMonth))} | Week $_selectedWeek",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4C3C32))),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildPortalLogisticsPanel(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Column(
      children: [
        if (isMobile) ...[
          _portalTextField(_facilitatorController, "Session Facilitator", Icons.person_pin_rounded),
          SizedBox(height: isVerySmall ? 16 : 24),
          _portalTextField(_locationController, "Venue / Location", Icons.place_rounded),
        ] else
          Row(
            children: [
              Expanded(child: _portalTextField(_facilitatorController, "Session Facilitator", Icons.person_pin_rounded)),
              const SizedBox(width: 32),
              Expanded(child: _portalTextField(_locationController, "Venue / Location", Icons.place_rounded)),
            ],
          ),
      ],
    );
  }

  Widget _buildPortalAttendanceTable() {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: isVerySmall ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isVerySmall ? BorderRadius.zero : BorderRadius.circular(20),
        border: isVerySmall ? null : Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: isVerySmall ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 16 : 32, vertical: isVerySmall ? 16 : 24),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                Text(isVerySmall ? "REGISTER" : "Attendance Registry",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: isVerySmall ? 10 : 12, color: kBrandBrown, letterSpacing: 1.0)),
                const Spacer(),
                _countBadge("${_entries.where((e) => e.status == AttendanceStatus.present).length} P", Colors.green),
                const SizedBox(width: 8),
                _countBadge("${_entries.where((e) => e.status == AttendanceStatus.absent).length} A", Colors.red),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowHeight: isVerySmall ? 48 : 64,
                    dataRowMaxHeight: isVerySmall ? 72 : 88,
                    horizontalMargin: isVerySmall ? 16 : 32,
                    columnSpacing: isVerySmall ? 16 : 32,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.grey, letterSpacing: 1.2),
                    columns: const [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("SCHOLAR PROFILE")),
                      DataColumn(label: Text("STATUS")),
                      DataColumn(label: Text("FIELD NOTES")),
                    ],
                    rows: _entries.map((entry) => _buildPortalDataRow(entry, isVerySmall)).toList(),
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  DataRow _buildPortalDataRow(AttendanceEntry entry, bool isVerySmall) {
    return DataRow(
      cells: [
        DataCell(Text(entry.scholar.scholarId,
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: isVerySmall ? 10 : 12))),
        DataCell(
          Row(
            children: [
              Container(
                width: isVerySmall ? 32 : 40,
                height: isVerySmall ? 32 : 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF2DB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(getInitials(entry.scholar.name),
                  style: TextStyle(fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), fontSize: isVerySmall ? 10 : 12)),
              ),
              SizedBox(width: isVerySmall ? 8 : 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.scholar.name.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: isVerySmall ? 11 : 13, color: const Color(0xFF4C3C32), letterSpacing: -0.2)),
                  Text(entry.scholar.currentClass,
                    style: TextStyle(fontSize: isVerySmall ? 8 : 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ),
        DataCell(_buildStatusPicker(entry)),
        DataCell(
          TextField(
            onChanged: (v) => entry.note = v,
            style: TextStyle(fontSize: isVerySmall ? 11 : 13, fontWeight: FontWeight.w600, color: const Color(0xFF4C3C32)),
            decoration: const InputDecoration(
              hintText: "Add remarks...",
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAttendanceList() {
    return Column(
      children: _entries.map((entry) => _buildMobileAttendanceCard(entry)).toList(),
    );
  }

  Widget _buildMobileAttendanceCard(AttendanceEntry entry) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 400;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isVerySmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isVerySmall ? 16 : 18,
                backgroundColor: const Color(0xFFFAF2DB),
                child: Text(getInitials(entry.scholar.name), style: TextStyle(fontSize: isVerySmall ? 9 : 10, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.scholar.name.toUpperCase(), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: isVerySmall ? 12 : 13, color: const Color(0xFF4C3C32))),
                    Text("${entry.scholar.scholarId} • ${entry.scholar.currentClass}", 
                      style: TextStyle(fontSize: isVerySmall ? 9 : 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusPicker(entry, isMobile: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: (v) => entry.note = v,
              style: TextStyle(fontSize: isVerySmall ? 11 : 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: isVerySmall ? "Notes..." : "Specific session notes...",
                hintStyle: TextStyle(fontSize: isVerySmall ? 10 : 11),
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
    final bool isVerySmall = MediaQuery.of(context).size.width < 400;
    return IgnorePointer(
      ignoring: !_canRecord,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: AttendanceStatus.values.map((status) {
          final isSelected = entry.status == status;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => entry.status = status),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: isVerySmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: isSelected ? status.color : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? status.color : const Color(0xFFEEEEEE),
                      width: 1
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(status.icon, size: isVerySmall ? 10 : 12, color: isSelected ? Colors.white : Colors.grey.shade300),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isVerySmall ? status.label.substring(0, 1).toUpperCase() : (isMobile ? status.label.substring(0, 3).toUpperCase() : status.label.toUpperCase()),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Widget _buildPortalPlaceholder(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          if (!_isFieldOfficer && widget.forcedSchoolType == null) ...[
            _portalSelectionLabel("Select Institutional Level"),
            const SizedBox(height: 8),
            SizedBox(
              width: isMobile ? double.infinity : 400,
              child: SegmentedButton<SchoolType>(
                segments: const [
                  ButtonSegment(value: SchoolType.secondary, label: Text("Secondary"), icon: Icon(Icons.school_outlined, size: 16)),
                  ButtonSegment(value: SchoolType.university, label: Text("University"), icon: Icon(Icons.account_balance_outlined, size: 16)),
                ],
                selected: {_schoolType},
                onSelectionChanged: (s) => setState(() {
                  _schoolType = s.first;
                  _selectedSchool = null;
                  _entries = [];
                  if (_schoolType == SchoolType.university) {
                    _moduleType = AttendanceModuleType.chats;
                  }
                }),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: kBrandOlive,
                  selectedForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else if (widget.forcedSchoolType != null || _isFieldOfficer) ...[
             _portalSelectionLabel("Logging for: ${_schoolType == SchoolType.university ? 'University' : 'Secondary'} Scholars"),
             const SizedBox(height: 8),
             _compactStaticField(
               _schoolType == SchoolType.university ? "University Level" : "Secondary School",
               _schoolType == SchoolType.university ? Icons.account_balance_outlined : Icons.school_rounded
             ),
          ],
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.assignment_ind_rounded, size: 64, color: Colors.grey.shade100),
          ),
          const SizedBox(height: 24),
          const Text("SELECT INSTITUTION TO INITIALIZE REGISTER",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildPortalFixedFooter(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 16 : (isMobile ? 24 : 40),
        vertical: isVerySmall ? 12 : 20
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: isMobile 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVerySmall)
                const Text(
                  "Audit declaration: Securely synchronize recorded telemetry.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              if (!isVerySmall) const SizedBox(height: 12),
              if (_canRecord)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveRegister,
                    icon: _isSaving 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(_isSaving ? "Syncing..." : "Finalize & sync", 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: isVerySmall ? 11 : 12, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isVerySmall ? 12 : 16),
                      backgroundColor: const Color(0xFF4C3C32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          )
        : Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF4C3C32), size: 24),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  "Audit declaration: By authorizing, you certify that the session telemetry recorded is accurate and reflects actual engagement.",
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600, height: 1.5),
                ),
              ),
              const SizedBox(width: 32),
              if (_canRecord)
                SizedBox(
                  width: 280,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveRegister,
                    icon: _isSaving 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(_isSaving ? "Synchronizing..." : "Finalize & sync register",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFF4C3C32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _portalDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged, {String Function(T)? itemLabel}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
              items: items.map((i) {
                String text = "";
                if (itemLabel != null) text = itemLabel(i);
                else if (i is Map) text = i['name'] ?? '';
                else text = i.toString();
                return DropdownMenuItem(value: i, child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown)));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _portalTextField(TextEditingController ctrl, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: ctrl,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown),
            decoration: InputDecoration(
              icon: Icon(icon, size: 16, color: kBrandOlive),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _portalDatePickerField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SITTING DATE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
                _selectedMonth = picked.month;
                _selectedYear = picked.year.toString();
                _selectedWeek = ((picked.day - 1) / 7).floor() + 1;
              });
            }
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: kBrandOlive),
                const SizedBox(width: 12),
                Text(DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactStaticField(String text, IconData icon) {
    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4C3C32).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4C3C32).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4C3C32)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 13, letterSpacing: -0.2)),
        ],
      ),
    );
  }

  Widget _countBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 0.5)),
    );
  }
}
