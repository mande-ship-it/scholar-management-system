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

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionPortalLabel("Session configuration", Icons.settings_input_composite_rounded),
                      const SizedBox(height: 24),
                      _buildPortalConfigPanel(isMobile),
                      const SizedBox(height: 48),
                      
                      if (_isLoadingScholars)
                        const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: kBrandOlive)))
                      else if (_entries.isNotEmpty) ...[
                        _sectionPortalLabel("Sitting logistics", Icons.local_shipping_rounded),
                        const SizedBox(height: 24),
                        _buildPortalLogisticsPanel(isMobile),
                        const SizedBox(height: 48),

                        _sectionPortalLabel("Attendance register", Icons.fact_check_rounded),
                        const SizedBox(height: 24),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isFieldOfficer ? "Session Telemetry" : "Attendance Audit",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16, 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF4C3C32), 
                    letterSpacing: -0.2
                  ),
                ),
              ],
            ),
          ),
          if (_entries.isNotEmpty && _isFieldOfficer)
            isMobile 
              ? IconButton(
                  onPressed: () => setState(() {
                    for (var e in _entries) e.status = AttendanceStatus.present;
                  }),
                  icon: const Icon(Icons.done_all_rounded, color: Color(0xFF9AB334)),
                  tooltip: "Mark All Present",
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var e in _entries) e.status = AttendanceStatus.present;
                    });
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text("Mark all present"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9AB334),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
        ],
      ),
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

  Widget _buildPortalConfigPanel(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: isMobile ? _buildMobileConfig() : _buildDesktopConfig(),
    );
  }

  Widget _buildMobileConfig() {
    final periods = _schoolType == SchoolType.university ? kSemesters : kTerms;
    return Column(
      children: [
        _portalDropdown("Partner Institution", _selectedSchool, _schoolOptions, (v) {
          setState(() {
            _selectedSchool = v;
            _loadRegister();
          });
        }),
        const SizedBox(height: 16),
        _portalDropdown("Academic Cycle", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!)),
        const SizedBox(height: 16),
        _portalDropdown("Period / Term", _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!)),
        const SizedBox(height: 16),
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
            const SizedBox(width: 24),
            Expanded(
              child: _portalDropdown("Academic Cycle", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!)),
            ),
            const SizedBox(width: 24),
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
                    Text("Telemetry Log: $_selectedMonth | Week $_selectedWeek", 
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
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            _portalTextField(_facilitatorController, "Session Facilitator", Icons.person_pin_rounded),
            const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildPortalAttendanceTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                const Text("Nominal roll", 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1.0)),
                const Spacer(),
                _countBadge("${_entries.where((e) => e.status == AttendanceStatus.present).length} present", Colors.green),
                const SizedBox(width: 16),
                _countBadge("${_entries.where((e) => e.status == AttendanceStatus.absent).length} absent", Colors.red),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 60,
              dataRowMaxHeight: 80,
              horizontalMargin: 32,
              columnSpacing: 24,
              columns: [
                const DataColumn(label: Text("IDENTIFIER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                const DataColumn(label: Text("SCHOLAR IDENTITY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                const DataColumn(label: Text("TELEMETRY STATUS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                const DataColumn(label: Text("FIELD NOTES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
              ],
              rows: _entries.map((entry) => _buildPortalDataRow(entry)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildPortalDataRow(AttendanceEntry entry) {
    return DataRow(
      cells: [
        DataCell(Text(entry.scholar.scholarId, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12))),
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2DB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(getInitials(entry.scholar.name), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 12)),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.scholar.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF4C3C32), letterSpacing: -0.2)),
                  Text(entry.scholar.currentClass, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ),
        DataCell(_buildStatusPicker(entry)),
        DataCell(
          TextField(
            onChanged: (v) => entry.note = v,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4C3C32)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                radius: 18,
                backgroundColor: const Color(0xFFFAF2DB),
                child: Text(getInitials(entry.scholar.name), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.scholar.name.toUpperCase(), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF4C3C32))),
                    Text(entry.scholar.scholarId, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: "Specific session notes...",
                hintStyle: TextStyle(fontSize: 11),
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
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 4),
              child: InkWell(
                onTap: () => setState(() => entry.status = status),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? status.color : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? status.color : const Color(0xFFEEEEEE),
                      width: 1.5
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(status.icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade300),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          status.label,
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

  Widget _buildPortalPlaceholder(bool isMobile) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40, 
        vertical: isMobile ? 12 : 20
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
              const Text(
                "Audit declaration: Securely synchronize recorded telemetry.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (_isFieldOfficer)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveRegister,
                    icon: _isSaving 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(_isSaving ? "Syncing..." : "Finalize & sync", 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
              if (_isFieldOfficer)
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

  Widget _portalDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
            items: items.map((i) {
              String text = "";
              if (i is Map) text = i['name'] ?? '';
              else text = i.toString();
              return DropdownMenuItem(value: i, child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4C3C32))));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _portalTextField(TextEditingController ctrl, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4C3C32)),
            decoration: InputDecoration(
              icon: Icon(icon, size: 18, color: const Color(0xFF9AB334)),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _portalDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SITTING DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.0)),
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
                _selectedMonth = DateFormat('MMMM').format(picked);
                _selectedWeek = ((picked.day - 1) / 7).floor() + 1;
              });
            }
          },
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
                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF9AB334)),
                const SizedBox(width: 16),
                Text(DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4C3C32))),
              ],
            ),
          ),
        ),
      ],
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
