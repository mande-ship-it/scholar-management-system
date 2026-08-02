import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';

// ============================================================
// MODELS & ENUMS
// ============================================================

enum AttendanceModuleType { chats, studyCircle }

extension AttendanceModuleTypeLabel on AttendanceModuleType {
  String get label => this == AttendanceModuleType.chats ? 'CHATs' : 'Study Circle';
  IconData get icon => this == AttendanceModuleType.chats ? Icons.forum_rounded : Icons.groups_rounded;
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
  const ScholarAttendanceComponent({super.key});

  @override
  State<ScholarAttendanceComponent> createState() => _ScholarAttendanceComponentState();
}

class _ScholarAttendanceComponentState extends State<ScholarAttendanceComponent> {
  // Session Configuration
  AttendanceModuleType _moduleType = AttendanceModuleType.chats;
  SchoolType _schoolType = SchoolType.secondary;
  Map<String, dynamic>? _selectedSchool;
  DateTime _selectedDate = DateTime.now();

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

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = _schoolType == SchoolType.secondary ? kTerms.first : kSemesters.first;
    _fetchSchools();
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
                schoolType: item['school_type'] == 'University' || item['schoolType'] == 'University' ? SchoolType.university : SchoolType.secondary,
                schoolName: item['display_school_name'] ?? _selectedSchool!['name'],
                currentClass: item['academic_year'] ?? 'N/A',
              ),
            )).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading scholars: $e');
    } finally {
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
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigSection(),
                  const SizedBox(height: 32),
                  if (_isLoadingScholars)
                    const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: kBrandOlive)))
                  else if (_entries.isNotEmpty) ...[
                    _buildFacilitatorSection(),
                    const SizedBox(height: 32),
                    _buildAttendanceTable()
                  ] else
                    _buildPlaceholder(),
                ],
              ),
            ),
          ),
          if (_entries.isNotEmpty) _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String targetText = _schoolType == SchoolType.university
        ? "Target: 1 Session / Week (3 months per semester)"
        : "Target: 1 Session / Week (2 months per term)";

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: Icon(_moduleType.icon, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Attendance Management",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Row(
                  children: [
                    Text("Recording ${_moduleType.label} sessions.",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(targetText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandOlive)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_entries.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  for (var e in _entries) e.status = AttendanceStatus.present;
                });
              },
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text("MARK ALL PRESENT", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigSection() {
    final periodLabel = _schoolType == SchoolType.secondary ? "Term Period" : "Semester Period";
    final periods = _schoolType == SchoolType.secondary ? kTerms : kSemesters;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SESSION PARAMETERS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _configColumn(
                  label: "Education Level",
                  child: SegmentedButton<SchoolType>(
                    segments: const [
                      ButtonSegment(value: SchoolType.secondary, label: Text("Secondary"), icon: Icon(Icons.school_outlined, size: 18)),
                      ButtonSegment(value: SchoolType.university, label: Text("University"), icon: Icon(Icons.account_balance_outlined, size: 18)),
                    ],
                    selected: {_schoolType},
                    onSelectionChanged: (s) => setState(() {
                      _schoolType = s.first;
                      _selectedSchool = null;
                      _entries = [];
                      _selectedPeriod = _schoolType == SchoolType.secondary ? kTerms.first : kSemesters.first;
                      if (_schoolType == SchoolType.university) _moduleType = AttendanceModuleType.chats;
                    }),
                    style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandBrown, selectedForegroundColor: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _configColumn(
                  label: "Program Module",
                  child: SegmentedButton<AttendanceModuleType>(
                    segments: [
                      const ButtonSegment(value: AttendanceModuleType.chats, label: Text("CHATs"), icon: Icon(Icons.forum_rounded, size: 18)),
                      if (_schoolType == SchoolType.secondary)
                        const ButtonSegment(value: AttendanceModuleType.studyCircle, label: Text("Study Circle"), icon: Icon(Icons.groups_rounded, size: 18)),
                    ],
                    selected: {_moduleType},
                    onSelectionChanged: (s) => setState(() {
                      _moduleType = s.first;
                      if (_selectedSchool != null) _loadRegister();
                    }),
                    style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandOlive, selectedForegroundColor: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
              const SizedBox(width: 20),
              Expanded(
                child: _dropdownFieldString(periodLabel, _selectedPeriod, periods, (v) => setState(() => _selectedPeriod = v!)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _dropdownFieldString("Academic Year", _selectedYear, academicYearOptions(), (v) => setState(() => _selectedYear = v!)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _datePickerField(),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _configColumn(
                  label: "Automatic Metadata Detection",
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kBrandOlive.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBrandOlive.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16, color: kBrandOlive),
                        const SizedBox(width: 12),
                        Text(
                          "Cycle: $_selectedMonth, Week $_selectedWeek",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandOlive),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitatorSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LOGISTICS & FACILITATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _textField(_facilitatorController, "Session Facilitator", Icons.person_pin_rounded, "Enter full name...")),
              const SizedBox(width: 24),
              Expanded(child: _textField(_locationController, "Venue / Location", Icons.place_rounded, "Physical meeting point...")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Text("ATTENDANCE REGISTER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
                const Spacer(),
                Text("${_entries.where((e) => e.status == AttendanceStatus.present).length} PRESENT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                const SizedBox(width: 16),
                Text("${_entries.where((e) => e.status == AttendanceStatus.absent).length} ABSENT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 400),
              child: DataTable(
                headingRowHeight: 50,
                dataRowMaxHeight: 70,
                horizontalMargin: 24,
                columnSpacing: 24,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text("SCHOLAR ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandBrown))),
                  DataColumn(label: Text("FULL NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandBrown))),
                  DataColumn(label: Text("MARK ATTENDANCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandBrown))),
                  DataColumn(label: Text("SESSION NOTES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandBrown))),
                ],
                rows: _entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.scholar.scholarId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13))),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.scholar.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kBrandBrown)),
                            Text(entry.scholar.currentClass, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        )
                      ),
                      DataCell(_buildStatusPicker(entry)),
                      DataCell(
                        TextField(
                          onChanged: (v) => entry.note = v,
                          decoration: InputDecoration(
                            hintText: "Add remarks...",
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
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

  Widget _buildStatusPicker(AttendanceEntry entry) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AttendanceStatus.values.map((status) {
        final isSelected = entry.status == status;
        final bool isPresent = status == AttendanceStatus.present;
        final bool isAbsent = status == AttendanceStatus.absent;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: status.label,
            child: InkWell(
              onTap: () => setState(() => entry.status = status),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? status.color : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? status.color : Colors.grey.shade200, 
                    width: 1.5
                  ),
                  boxShadow: isSelected ? [BoxShadow(color: status.color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade400),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        status.label.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "By saving, you confirm that this attendance record is accurate and adheres to the program's weekly and monthly engagement restrictions.",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 40),
          SizedBox(
            width: 320,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveRegister,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.verified_user_rounded),
              label: Text(_isSaving ? "SYNCING..." : "AUTHORIZE & SAVE REGISTER", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
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

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.assignment_ind_rounded, size: 80, color: Colors.grey.shade100),
          const SizedBox(height: 20),
          Text(_selectedSchool == null ? "Select a school to load the scholar registry." : "No scholars found for the selected criteria.",
            style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _configColumn({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _dropdownField(String label, dynamic value, List<Map<String, dynamic>> items, ValueChanged<Map<String, dynamic>?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButton<Map<String, dynamic>>(
            value: value,
            isExpanded: true,
            hint: const Text("Select option...", style: TextStyle(fontSize: 14)),
            underline: const SizedBox(),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _dropdownFieldString(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _textField(TextEditingController controller, String label, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              border: InputBorder.none,
              icon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.6)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SESSION DATE", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20, color: kBrandBrown),
                const SizedBox(width: 12),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text("Week $_selectedWeek, $_selectedMonth", style: TextStyle(fontSize: 11, color: kBrandOlive, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
