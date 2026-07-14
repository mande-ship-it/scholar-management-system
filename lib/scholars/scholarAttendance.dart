import 'package:flutter/material.dart';

// ============================================================
// MODELS
// ============================================================

enum SchoolType { secondary, university }

extension SchoolTypeLabel on SchoolType {
  String get label {
    switch (this) {
      case SchoolType.secondary:
        return 'Secondary School';
      case SchoolType.university:
        return 'University';
    }
  }
}

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusData on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.excused:
        return Icons.event_busy;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF2E7D32); // Green
      case AttendanceStatus.absent:
        return const Color(0xFFC62828); // Red
      case AttendanceStatus.late:
        return const Color(0xFFE65100); // Orange
      case AttendanceStatus.excused:
        return const Color(0xFF455A64); // Slate Gray
    }
  }
}

class Scholar {
  final String id;
  final String scholarNumber;
  final String name;
  final SchoolType schoolType;
  final String schoolName;
  final String programOrGrade;

  const Scholar({
    required this.id,
    required this.scholarNumber,
    required this.name,
    required this.schoolType,
    required this.schoolName,
    required this.programOrGrade,
  });
}

class AttendanceEntry {
  final Scholar scholar;
  AttendanceStatus status;
  String note;

  AttendanceEntry({
    required this.scholar,
    this.status = AttendanceStatus.present,
    this.note = '',
  });
}

// ============================================================
// MOCK DATA SOURCE
// ============================================================

class ScholarDataSource {
  static const Map<SchoolType, List<String>> schoolsByType = {
    SchoolType.secondary: [
      'Kamuzu Academy',
      'St. Andrews International High School',
      'Bishop Mackenzie International School',
      'Providence High School',
    ],
    SchoolType.university: [
      'University of Malawi',
      'Malawi University of Science and Technology',
      'Mzuzu University',
      'Malawi University of Business and Applied Sciences',
    ],
  };

  static final List<Scholar> _allScholars = [
    // ---- Kamuzu Academy (Secondary) ----
    const Scholar(
        id: 's1',
        scholarNumber: 'AGE-2024-001',
        name: 'Chisomo Banda',
        schoolType: SchoolType.secondary,
        schoolName: 'Kamuzu Academy',
        programOrGrade: 'Form 3'),
    const Scholar(
        id: 's2',
        scholarNumber: 'AGE-2024-002',
        name: 'Thandiwe Phiri',
        schoolType: SchoolType.secondary,
        schoolName: 'Kamuzu Academy',
        programOrGrade: 'Form 4'),
    const Scholar(
        id: 's8',
        scholarNumber: 'AGE-2024-008',
        name: 'Wongani Kaunda',
        schoolType: SchoolType.secondary,
        schoolName: 'Kamuzu Academy',
        programOrGrade: 'Form 2'),
    const Scholar(
        id: 's9',
        scholarNumber: 'AGE-2024-009',
        name: 'Esnart Mwale',
        schoolType: SchoolType.secondary,
        schoolName: 'Kamuzu Academy',
        programOrGrade: 'Form 1'),
    const Scholar(
        id: 's10',
        scholarNumber: 'AGE-2024-010',
        name: 'Mphatso Gondwe',
        schoolType: SchoolType.secondary,
        schoolName: 'Kamuzu Academy',
        programOrGrade: 'Form 4'),

    // ---- St. Andrews International High School (Secondary) ----
    const Scholar(
        id: 's3',
        scholarNumber: 'AGE-2024-003',
        name: 'Yamikani Mvula',
        schoolType: SchoolType.secondary,
        schoolName: 'St. Andrews International High School',
        programOrGrade: 'Form 2'),
    const Scholar(
        id: 's11',
        scholarNumber: 'AGE-2024-011',
        name: 'Rachel Kamanga',
        schoolType: SchoolType.secondary,
        schoolName: 'St. Andrews International High School',
        programOrGrade: 'Form 3'),
    const Scholar(
        id: 's12',
        scholarNumber: 'AGE-2024-012',
        name: 'Isaac Chikondi',
        schoolType: SchoolType.secondary,
        schoolName: 'St. Andrews International High School',
        programOrGrade: 'Form 1'),
    const Scholar(
        id: 's13',
        scholarNumber: 'AGE-2024-013',
        name: 'Faith Nkhoma',
        schoolType: SchoolType.secondary,
        schoolName: 'St. Andrews International High School',
        programOrGrade: 'Form 4'),

    // ---- Bishop Mackenzie International School (Secondary) ----
    const Scholar(
        id: 's4',
        scholarNumber: 'AGE-2024-004',
        name: 'Grace Chirwa',
        schoolType: SchoolType.secondary,
        schoolName: 'Bishop Mackenzie International School',
        programOrGrade: 'Form 1'),
    const Scholar(
        id: 's14',
        scholarNumber: 'AGE-2024-014',
        name: 'Andrew Mbewe',
        schoolType: SchoolType.secondary,
        schoolName: 'Bishop Mackenzie International School',
        programOrGrade: 'Form 2'),
    const Scholar(
        id: 's15',
        scholarNumber: 'AGE-2024-015',
        name: 'Loveness Tembo',
        schoolType: SchoolType.secondary,
        schoolName: 'Bishop Mackenzie International School',
        programOrGrade: 'Form 3'),
    const Scholar(
        id: 's16',
        scholarNumber: 'AGE-2024-016',
        name: 'Patrick Msiska',
        schoolType: SchoolType.secondary,
        schoolName: 'Bishop Mackenzie International School',
        programOrGrade: 'Form 4'),

    // ---- Providence High School (Secondary) ----
    const Scholar(
        id: 's17',
        scholarNumber: 'AGE-2024-017',
        name: 'Ethel Kaira',
        schoolType: SchoolType.secondary,
        schoolName: 'Providence High School',
        programOrGrade: 'Form 1'),
    const Scholar(
        id: 's18',
        scholarNumber: 'AGE-2024-018',
        name: 'Robert Chiumia',
        schoolType: SchoolType.secondary,
        schoolName: 'Providence High School',
        programOrGrade: 'Form 2'),
    const Scholar(
        id: 's19',
        scholarNumber: 'AGE-2024-019',
        name: 'Mercy Kalulu',
        schoolType: SchoolType.secondary,
        schoolName: 'Providence High School',
        programOrGrade: 'Form 3'),
    const Scholar(
        id: 's20',
        scholarNumber: 'AGE-2024-020',
        name: 'Joseph Nyasulu',
        schoolType: SchoolType.secondary,
        schoolName: 'Providence High School',
        programOrGrade: 'Form 4'),

    // ---- University of Malawi (University) ----
    const Scholar(
        id: 's5',
        scholarNumber: 'AGE-2024-005',
        name: 'Blessings Nyirenda',
        schoolType: SchoolType.university,
        schoolName: 'University of Malawi',
        programOrGrade: 'BSc Computer Science, Year 2'),
    const Scholar(
        id: 's6',
        scholarNumber: 'AGE-2024-006',
        name: 'Precious Kachale',
        schoolType: SchoolType.university,
        schoolName: 'University of Malawi',
        programOrGrade: 'BA Economics, Year 3'),
    const Scholar(
        id: 's21',
        scholarNumber: 'AGE-2024-021',
        name: 'Felix Manda',
        schoolType: SchoolType.university,
        schoolName: 'University of Malawi',
        programOrGrade: 'LLB Law, Year 1'),
    const Scholar(
        id: 's22',
        scholarNumber: 'AGE-2024-022',
        name: 'Sarah Kambewa',
        schoolType: SchoolType.university,
        schoolName: 'University of Malawi',
        programOrGrade: 'BSc Nursing, Year 4'),
    const Scholar(
        id: 's23',
        scholarNumber: 'AGE-2024-023',
        name: 'Emmanuel Chirambo',
        schoolType: SchoolType.university,
        schoolName: 'University of Malawi',
        programOrGrade: 'BA Public Administration, Year 2'),

    // ---- Malawi University of Science and Technology (University) ----
    const Scholar(
        id: 's7',
        scholarNumber: 'AGE-2024-007',
        name: 'Dumisani Zulu',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Science and Technology',
        programOrGrade: 'BEng Civil Engineering, Year 1'),
    const Scholar(
        id: 's24',
        scholarNumber: 'AGE-2024-024',
        name: 'Angela Chiwaya',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Science and Technology',
        programOrGrade: 'BSc Biomedical Sciences, Year 3'),
    const Scholar(
        id: 's25',
        scholarNumber: 'AGE-2024-025',
        name: 'Christopher Mhone',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Science and Technology',
        programOrGrade: 'BEng Mechanical Engineering, Year 2'),
    const Scholar(
        id: 's26',
        scholarNumber: 'AGE-2024-026',
        name: 'Ruth Mkandawire',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Science and Technology',
        programOrGrade: 'BSc Information Technology, Year 4'),

    // ---- Mzuzu University (University) ----
    const Scholar(
        id: 's27',
        scholarNumber: 'AGE-2024-027',
        name: 'Vitumbiko Kanjo',
        schoolType: SchoolType.university,
        schoolName: 'Mzuzu University',
        programOrGrade: 'BEd Science, Year 2'),
    const Scholar(
        id: 's28',
        scholarNumber: 'AGE-2024-028',
        name: 'Catherine Longwe',
        schoolType: SchoolType.university,
        schoolName: 'Mzuzu University',
        programOrGrade: 'BSc Environmental Health, Year 1'),
    const Scholar(
        id: 's29',
        scholarNumber: 'AGE-2024-029',
        name: 'Steven Mvula',
        schoolType: SchoolType.university,
        schoolName: 'Mzuzu University',
        programOrGrade: 'BA Tourism, Year 3'),
    const Scholar(
        id: 's30',
        scholarNumber: 'AGE-2024-030',
        name: 'Alinane Phekani',
        schoolType: SchoolType.university,
        schoolName: 'Mzuzu University',
        programOrGrade: 'BSc Agribusiness, Year 4'),

    // ---- Malawi University of Business and Applied Sciences (University) ----
    const Scholar(
        id: 's31',
        scholarNumber: 'AGE-2024-031',
        name: 'Hastings Chatepa',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Business and Applied Sciences',
        programOrGrade: 'BSc Accounting, Year 2'),
    const Scholar(
        id: 's32',
        scholarNumber: 'AGE-2024-032',
        name: 'Josephine Kalua',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Business and Applied Sciences',
        programOrGrade: 'BSc Software Engineering, Year 1'),
    const Scholar(
        id: 's33',
        scholarNumber: 'AGE-2024-033',
        name: 'Peter Chunga',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Business and Applied Sciences',
        programOrGrade: 'BSc Marketing, Year 3'),
    const Scholar(
        id: 's34',
        scholarNumber: 'AGE-2024-034',
        name: 'Nellie Mtambalika',
        schoolType: SchoolType.university,
        schoolName: 'Malawi University of Business and Applied Sciences',
        programOrGrade: 'BSc Actuarial Science, Year 4'),
  ];

  static List<Scholar> getScholars(SchoolType type, String schoolName) {
    return _allScholars
        .where((s) => s.schoolType == type && s.schoolName == schoolName)
        .toList();
  }
}

// ============================================================
// MAIN COMPONENT
// ============================================================

class ScholarAttendanceComponent extends StatefulWidget {
  final Future<void> Function(
      SchoolType schoolType,
      String schoolName,
      DateTime date,
      List<AttendanceEntry> entries,
      )? onSubmitRegister;

  const ScholarAttendanceComponent({super.key, this.onSubmitRegister});

  @override
  State<ScholarAttendanceComponent> createState() =>
      _ScholarAttendanceComponentState();
}

class _ScholarAttendanceComponentState extends State<ScholarAttendanceComponent> {
  // Brand color scheme matching the portal system
  static const Color brandBrown = Color(0xFF4C3C32);
  static const Color brandCream = Color(0xFFFAF2DB);
  static const Color brandCreamDark = Color(0xFFF3E7C4);
  static const Color brandOlive = Color(0xFF9AB334);
  static const Color brandOrange = Color(0xFFE05B1C);

  SchoolType? _selectedType;
  String? _selectedSchool;
  DateTime? _selectedDate = DateTime.now();

  List<AttendanceEntry> _entries = [];
  String _searchQuery = '';
  bool _isSaving = false;
  bool _registerLoaded = false;

  static const List<String> _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _formatDate(DateTime date) {
    final weekday = _weekdayNames[date.weekday - 1];
    final month = _monthNames[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  List<String> get _availableSchools {
    if (_selectedType == null) return [];
    return ScholarDataSource.schoolsByType[_selectedType!] ?? [];
  }

  void _onSchoolTypeChanged(SchoolType? type) {
    setState(() {
      _selectedType = type;
      _selectedSchool = null;
      _entries = [];
      _registerLoaded = false;
    });
  }

  void _onSchoolChanged(String? school) {
    setState(() {
      _selectedSchool = school;
      _entries = [];
      _registerLoaded = false;
    });
    _maybeAutoLoad();
  }

  void _maybeAutoLoad() {
    if (_selectedType != null && _selectedSchool != null && _selectedDate != null) {
      _loadRegister();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: brandBrown,
              onPrimary: Colors.white,
              onSurface: brandBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _registerLoaded = false;
      });
      _maybeAutoLoad();
    }
  }

  void _loadRegister() {
    if (_selectedType == null || _selectedSchool == null) return;
    final scholars = ScholarDataSource.getScholars(_selectedType!, _selectedSchool!);
    setState(() {
      _entries = scholars.map((s) => AttendanceEntry(scholar: s)).toList();
      _registerLoaded = true;
    });
  }

  void _setStatus(AttendanceEntry entry, AttendanceStatus status) {
    setState(() => entry.status = status);
  }

  void _markAllPresent() {
    setState(() {
      for (final e in _entries) {
        e.status = AttendanceStatus.present;
      }
    });
  }

  Map<AttendanceStatus, int> get _statusCounts {
    final counts = {
      for (final s in AttendanceStatus.values) s: 0,
    };
    for (final e in _entries) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }
    return counts;
  }

  double _calculateAttendanceRate() {
    if (_entries.isEmpty) return 0.0;
    final counts = _statusCounts;
    final present = counts[AttendanceStatus.present] ?? 0;
    final lateCount = counts[AttendanceStatus.late] ?? 0;
    final excused = counts[AttendanceStatus.excused] ?? 0;
    return (present + lateCount + excused) / _entries.length;
  }

  List<AttendanceEntry> get _filteredEntries {
    if (_searchQuery.trim().isEmpty) return _entries;
    final q = _searchQuery.toLowerCase();
    return _entries
        .where((e) =>
            e.scholar.name.toLowerCase().contains(q) ||
            e.scholar.scholarNumber.toLowerCase().contains(q))
        .toList();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "NS";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: brandBrown.withValues(alpha: 0.7)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: brandOlive, width: 2),
      ),
    );
  }

  Future<void> _saveRegister() async {
    if (_entries.isEmpty || _selectedType == null || _selectedSchool == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (widget.onSubmitRegister != null) {
        await widget.onSubmitRegister!(
          _selectedType!,
          _selectedSchool!,
          _selectedDate!,
          _entries,
        );
      }
      if (!mounted) return;
      final counts = _statusCounts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Register saved for $_selectedSchool on ${_formatDate(_selectedDate!)} '
            '(Present: ${counts[AttendanceStatus.present]}, '
            'Absent: ${counts[AttendanceStatus.absent]}, '
            'Late: ${counts[AttendanceStatus.late]}, '
            'Excused: ${counts[AttendanceStatus.excused]})',
          ),
          backgroundColor: brandOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save register: $e'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 950;

        final Widget leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFilterCard(),
            const SizedBox(height: 16),
            if (_registerLoaded && _entries.isNotEmpty) ...[
              _buildRegisterCard(),
            ] else if (_registerLoaded && _entries.isEmpty)
              _buildEmptyState(),
          ],
        );

        final Widget rightColumn = _registerLoaded && _entries.isNotEmpty
            ? _buildStatsSidebar()
            : const SizedBox();

        if (isWide) {
          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: leftColumn,
                  ),
                ),
                if (_registerLoaded && _entries.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 78), // Align with filters card
                      child: rightColumn,
                    ),
                  ),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftColumn,
                if (_registerLoaded && _entries.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  rightColumn,
                ],
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brandOlive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: brandOlive,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scholar Attendance Register",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Onboard daily attendance records for program cohort scholars.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.tune_outlined, color: brandOrange, size: 18),
                SizedBox(width: 8),
                Text(
                  'Select Register Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandBrown),
                ),
              ],
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, filterConstraints) {
                final bool isWideFilters = filterConstraints.maxWidth > 850;

                final Widget schoolTypeDropdown = DropdownButtonFormField<SchoolType>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: _getInputDecoration(
                    labelText: 'School Type',
                    prefixIcon: Icons.category_outlined,
                  ),
                  items: SchoolType.values
                      .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ))
                      .toList(),
                  onChanged: _onSchoolTypeChanged,
                );

                final Widget schoolNameDropdown = DropdownButtonFormField<String>(
                  initialValue: _selectedSchool,
                  isExpanded: true,
                  decoration: _getInputDecoration(
                    labelText: 'School Name',
                    prefixIcon: Icons.school_outlined,
                  ),
                  items: _availableSchools
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ))
                      .toList(),
                  onChanged: _selectedType == null ? null : _onSchoolChanged,
                  disabledHint: const Text('Select school type first'),
                );

                final Widget datePickerField = InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: _getInputDecoration(
                      labelText: 'Day / Date',
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : _formatDate(_selectedDate!),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );

                if (isWideFilters) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: schoolTypeDropdown),
                      const SizedBox(width: 16),
                      Expanded(child: schoolNameDropdown),
                      const SizedBox(width: 16),
                      Expanded(child: datePickerField),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      schoolTypeDropdown,
                      const SizedBox(height: 16),
                      schoolNameDropdown,
                      const SizedBox(height: 16),
                      datePickerField,
                    ],
                  );
                }
              }
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!(_selectedType != null && _selectedSchool != null && _selectedDate != null))
                  Expanded(
                    child: Text(
                      'Please select the school type, school name, and a date to load the attendance register.',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _loadRegister,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reload Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOlive,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 40, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              'No scholars found for $_selectedSchool.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Row: Search + Mark All Present
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search scholar by name or number...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: brandBrown),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: brandOlive, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _markAllPresent,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark All Present'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List of scholars
        _buildRegisterList(),
        const SizedBox(height: 24),

        // Save register button
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveRegister,
          icon: _isSaving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Saving...' : 'Save Attendance Register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            shadowColor: brandOrange.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterList() {
    final filtered = _filteredEntries;
    if (filtered.isEmpty) {
      return Card(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No scholars match your search query.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return _buildScholarAttendanceCard(entry);
      },
    );
  }

  Widget _buildScholarAttendanceCard(AttendanceEntry entry) {
    final String initials = _getInitials(entry.scholar.name);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final bool isWideCard = cardConstraints.maxWidth > 650;

            final Widget scholarInfo = Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: brandBrown.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: brandBrown,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.scholar.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: brandBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: brandCreamDark.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.scholar.scholarNumber,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandBrown),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.school, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.scholar.programOrGrade,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final Widget statusSelector = Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: AttendanceStatus.values.map((status) {
                final bool isSelected = entry.status == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => _setStatus(entry, status),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? status.color.withValues(alpha: 0.15)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? status.color : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status.icon,
                              size: 16,
                              color: isSelected ? status.color : Colors.grey.shade500,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? status.color : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );

            final Widget noteInput = TextFormField(
              initialValue: entry.note,
              decoration: InputDecoration(
                hintText: 'Add an optional note (e.g. sick leave, late due to transport)...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: brandOlive, width: 1.5),
                ),
              ),
              onChanged: (v) => entry.note = v,
              style: const TextStyle(fontSize: 12),
            );

            if (isWideCard) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 3, child: scholarInfo),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: statusSelector),
                    ],
                  ),
                  const SizedBox(height: 12),
                  noteInput,
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  scholarInfo,
                  const SizedBox(height: 12),
                  statusSelector,
                  const SizedBox(height: 12),
                  noteInput,
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsSidebar() {
    final double rate = _calculateAttendanceRate();
    final counts = _statusCounts;
    final int total = _entries.length;

    Color rateColor = brandOrange;
    if (rate >= 0.90) {
      rateColor = brandOlive;
    } else if (rate >= 0.75) {
      rateColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attendance Pulse Card
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Attendance Pulse",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${(rate * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: rateColor,
                          ),
                        ),
                        const Text(
                          "Rate",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Overview of today's attendance metrics for selected institution.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Breakdowns Card
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Status Summary",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
                const Divider(height: 24),
                _buildStatItem("Present", counts[AttendanceStatus.present] ?? 0, total, AttendanceStatus.present.color, AttendanceStatus.present.icon),
                _buildStatItem("Absent", counts[AttendanceStatus.absent] ?? 0, total, AttendanceStatus.absent.color, AttendanceStatus.absent.icon),
                _buildStatItem("Late", counts[AttendanceStatus.late] ?? 0, total, AttendanceStatus.late.color, AttendanceStatus.late.icon),
                _buildStatItem("Excused", counts[AttendanceStatus.excused] ?? 0, total, AttendanceStatus.excused.color, AttendanceStatus.excused.icon),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, int total, Color color, IconData icon) {
    final double percent = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: brandBrown),
              ),
              const Spacer(),
              Text(
                "$count ($total)",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}