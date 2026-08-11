import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

// ============================================================
// Professional Academic Results Entry Portal
// ============================================================

class AcademicsManagementComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  final VoidCallback? onBack;
  final Function(String)? onPush;
  const AcademicsManagementComponent({super.key, this.forcedSchoolType, this.onBack, this.onPush});

  @override
  State<AcademicsManagementComponent> createState() => _AcademicsManagementComponentState();
}

class _AcademicsManagementComponentState extends State<AcademicsManagementComponent> {
  bool _canEdit = false;
  bool _isFieldOfficer = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final res = await ApiService.getAccountProfile();
      if (res.statusCode == 200) {
        final data = res.data['data'];
        final role = (data['role_name'] ?? '').toString().toLowerCase().trim();
        
        final List<String> fieldRoles = ['field officer', 'field coordinator', 'field operations', 'operational officer'];
        final List<String> managementRoles = ['administrator', 'admin', 'program coordinator', 'country director', 'program manager', 'data officer'];
        
        if (mounted) {
          setState(() {
            _isFieldOfficer = fieldRoles.contains(role);
            _canEdit = fieldRoles.contains(role) || managementRoles.contains(role);
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(isMobile),
          const Divider(height: 1),
          Expanded(child: EnterResultsComponent(forcedSchoolType: widget.forcedSchoolType, onPush: widget.onPush)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return const SizedBox.shrink();
  }
}

class EnterResultsComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  final Function(String)? onPush;
  const EnterResultsComponent({super.key, this.forcedSchoolType, this.onPush});

  @override
  State<EnterResultsComponent> createState() => _EnterResultsComponentState();
}

class _EnterResultsComponentState extends State<EnterResultsComponent> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _canEdit = false;
  bool _isStrictFieldOfficer = false;

  // Selection State
  late SchoolType _schoolType;
  Map<String, dynamic>? _selectedSchool;
  Student? _selectedStudent;

  // Session State
  String? _selectedYear;
  String? _selectedPeriod; // Term or Semester
  String? _selectedClass; // For Secondary (Form 1, 2, etc.)
  DateTime _resultsDate = DateTime.now();

  final List<String> _secondaryClasses = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];
  final List<String> _academicYears = academicYearOptions();

  // Results Table State
  final List<_ResultInputRow> _rows = [];

  bool get isUniversity => _schoolType == SchoolType.university;

  // Data pools
  List<Map<String, dynamic>> _registeredSchools = [];
  List<Student> _allScholars = [];
  List<Subject> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _schoolType = widget.forcedSchoolType ?? SchoolType.secondary;
    // User Spec: Automatically be the current year
    _selectedYear = DateTime.now().year.toString();
    if (!_academicYears.contains(_selectedYear)) {
      _academicYears.insert(0, _selectedYear!);
    }
    _addRow();
    _fetchBaseData();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final res = await ApiService.getAccountProfile();
      if (res.statusCode == 200) {
        final data = res.data['data'];
        final role = (data['role_name'] ?? '').toString().toLowerCase().trim();
        
        final List<String> fieldRoles = ['field officer', 'field coordinator', 'field operations', 'operational officer'];
        final List<String> managementRoles = ['administrator', 'admin', 'program coordinator', 'country director', 'program manager', 'data officer'];
        
        if (mounted) {
          setState(() {
            _isStrictFieldOfficer = fieldRoles.contains(role);
            _canEdit = fieldRoles.contains(role) || managementRoles.contains(role);
            
            if (_isStrictFieldOfficer) {
              _schoolType = SchoolType.secondary;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Role check error: $e');
    }
  }

  Future<void> _fetchBaseData() async {
    setState(() => _isLoading = true);
    try {
      final schoolsRes = await ApiService.getAllSchools();
      final scholarsRes = await ApiService.getAllScholars();
      final subjectsRes = await ApiService.getSubjectRegistry(); // Use Registry

      if (mounted) {
        setState(() {
          _registeredSchools = List<Map<String, dynamic>>.from(schoolsRes.data['data'] ?? []);
          
          final List<dynamic> scholarData = scholarsRes.data['data'] ?? [];
          _allScholars = scholarData.map((s) => Student.fromMap(s)).toList();

          final List<dynamic> subjectData = subjectsRes.data['data'] ?? [];
          _availableSubjects = subjectData.map((sub) => Subject(
            name: sub['name'],
            code: sub['code'],
            details: sub['details'] ?? '',
            notes: sub['notes'] ?? '',
            level: sub['level'].toString().toLowerCase() == 'university'
                ? SubjectLevel.university
                : SubjectLevel.secondary,
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching base data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScholarChanged(String? id) async {
    if (id == null) return;
    try {
      final student = _scholarOptions.firstWhere((s) => s.id == id);
      setState(() {
        _selectedStudent = student;
        _selectedPeriod = null;
        _recordedPeriods = [];
      });

      if (_selectedYear != null) {
        _checkCompleteness(student.id, int.parse(_selectedYear!));
      }
    } catch (e) {
      debugPrint('Scholar selection error: $e');
    }
  }

  List<String> _recordedPeriods = [];

  Future<void> _checkCompleteness(String scholarId, int year) async {
    try {
      final res = await ApiService.checkResultCompleteness(scholarId, year);
      if (res.statusCode == 200) {
        final data = res.data['data'];
        setState(() {
          _recordedPeriods = List<String>.from(isUniversity ? (data['semestersRecorded'] ?? []) : (data['termsRecorded'] ?? []));
        });
      }
    } catch (e) {
      debugPrint('Completeness check error: $e');
    }
  }

  void _onTypeChanged(SchoolType? type) {
    if (type == null) return;
    setState(() {
      _schoolType = type;
      _selectedSchool = null;
      _selectedStudent = null;
      _selectedPeriod = null;
      _selectedClass = null;
      _rows.clear();
      _addRow();
      _recordedPeriods = [];
    });
  }

  void _addRow() {
    setState(() {
      _rows.add(_ResultInputRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() => _rows.removeAt(index));
    }
  }

  List<Map<String, dynamic>> get _schoolOptions {
    return _registeredSchools.where((s) {
      final level = (s['level'] ?? '').toString().toLowerCase();
      if (_schoolType == SchoolType.secondary) {
        return level.contains('secondary') || level.contains('high');
      } else {
        return level.contains('university') || level.contains('tertiary');
      }
    }).toList();
  }

  List<Student> get _scholarOptions {
    if (_selectedSchool == null) return [];
    return _allScholars
        .where((s) => s.schoolName == _selectedSchool!['name'] && s.status == 'Active')
        .toList();
  }

  List<Subject> get _subjectOptions {
    final targetLevel = _schoolType == SchoolType.secondary ? SubjectLevel.secondary : SubjectLevel.university;
    return _availableSubjects.where((s) => s.level == targetLevel).toList();
  }

  double get _currentAverage {
    double total = 0;
    int count = 0;
    for (var row in _rows) {
      final score = double.tryParse(row.scoreController.text);
      if (score != null) {
        total += score;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  Color _getScoreColor(double score) {
    if (_schoolType == SchoolType.secondary) {
      if (score <= 39) return Colors.red.shade700;
      if (score <= 59) return Colors.amber.shade900; 
      return Colors.green.shade700;
    } else {
      if (score <= 49) return Colors.red.shade700;
      if (score <= 69) return Colors.amber.shade900;
      return Colors.green.shade700;
    }
  }

  String _getScoreLabel(double score) {
    if (_schoolType == SchoolType.secondary) {
      if (score <= 39) return "Fail";
      if (score <= 59) return "Pass";
      return "Distinction";
    } else {
      if (score <= 49) return "Fail";
      if (score <= 69) return "Pass";
      return "Distinction";
    }
  }

  Future<void> _save() async {
    if (_selectedStudent == null || _selectedPeriod == null || _selectedYear == null) {
      _showError("Please complete the scholar and period selection.");
      return;
    }

    final List<Map<String, dynamic>> validResults = [];
    for (var row in _rows) {
      final name = row.subjectController.text.trim();
      final scoreStr = row.scoreController.text.trim();
      if (name.isNotEmpty && scoreStr.isNotEmpty) {
        final score = double.tryParse(scoreStr);
        if (score == null || score < 0 || score > 100) {
          _showError("Invalid score for $name. Must be 0-100.");
          return;
        }
        validResults.add({
          'subjectName': name,
          'marks': score,
        });
      }
    }

    if (validResults.isEmpty) {
      _showError("Please enter results for at least one subject/course.");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'scholarId': _selectedStudent!.id,
        'results': validResults,
        'year': int.parse(_selectedYear!),
        'schoolType': _schoolType == SchoolType.secondary ? 'Secondary' : 'University',
        if (_schoolType == SchoolType.secondary) 'term': _selectedPeriod else 'semester': _selectedPeriod,
        if (_schoolType == SchoolType.secondary) 'currentClass': _selectedClass,
        if (_schoolType == SchoolType.university) 'date': _resultsDate.toIso8601String(),
      };

      final response = await ApiService.recordResults(payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Academic results recorded for ${_selectedStudent!.name}"),
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _resetForm();
        }
      }
    } catch (e) {
      _showError("Failed to save results. Backend error.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedStudent = null;
      _selectedPeriod = null;
      _selectedClass = null;
      _rows.clear();
      _addRow();
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel("SESSION CONFIGURATION", Icons.settings_input_component_rounded),
                const SizedBox(height: 20),
                _buildSelectionPanel(isMobile),
                const SizedBox(height: 48),
                if (_selectedStudent != null && _selectedPeriod != null) ...[
                  _sectionLabel("EXAMINATION SCORECARD", Icons.fact_check_rounded),
                  const SizedBox(height: 20),
                  _buildResultsTable(isMobile),
                  const SizedBox(height: 60),
                  _buildActionFooter(isMobile),
                ] else
                  _buildMissingSelectionHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
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

  Widget _buildSelectionPanel(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: EdgeInsets.all(isVerySmall ? 16 : (isMobile ? 20 : 32)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _portalSelectionLabel("Institution Level"),
                if (!isUniversity)
                  TextButton.icon(
                    onPressed: () => widget.onPush?.call("Subject Registry"),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 14),
                    label: const Text("MANAGE SUBJECTS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(foregroundColor: kBrandOlive),
                  ),
              ],
            ),
            if (_isStrictFieldOfficer)
              _compactStaticField("Secondary School", Icons.school_rounded)
            else
              _buildTypeSelector(),
            SizedBox(height: isVerySmall ? 16 : 24),
            _dropdownField<String>(
              label: "Academic Year", 
              value: _selectedYear, 
              items: _academicYears, 
              icon: Icons.calendar_today_rounded, 
              onChanged: (v) {
                setState(() {
                  _selectedYear = v;
                  _recordedPeriods = [];
                  _selectedPeriod = null;
                });
                if (_selectedStudent != null && v != null) {
                  _checkCompleteness(_selectedStudent!.id, int.parse(v));
                }
              }
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            _dropdownField<String>(
              label: "Partner Institution", 
              value: _selectedSchool?['name'], 
              items: _schoolOptions.map((s) => s['name'] as String).toList(), 
              icon: Icons.apartment_rounded, 
              onChanged: (v) {
                setState(() {
                  _selectedSchool = _registeredSchools.firstWhere((s) => s['name'] == v);
                  _selectedStudent = null;
                });
              }
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            _dropdownField<String>(
              label: "Selected Scholar", 
              value: _selectedStudent?.id, 
              items: _scholarOptions.map((s) => s.id).toList(), 
              icon: Icons.person_search_rounded, 
              onChanged: _onScholarChanged,
              itemLabel: (id) => _scholarOptions.firstWhere((s) => s.id == id).name,
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            _dropdownField<String>(
              label: _schoolType == SchoolType.secondary ? "Academic Term" : "Academic Semester",
              value: _selectedPeriod,
              items: _schoolType == SchoolType.secondary ? kTerms : kSemesters,
              icon: Icons.event_note_rounded,
              onChanged: (v) => setState(() => _selectedPeriod = v),
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            if (_schoolType == SchoolType.secondary)
              _dropdownField<String>(
                label: "Current Class", 
                value: _selectedClass, 
                items: _secondaryClasses, 
                icon: Icons.class_outlined, 
                onChanged: (v) => setState(() => _selectedClass = v)
              )
            else
              _datePickerField("Results Date"),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _portalSelectionLabel("Institution Level"),
                          if (!isUniversity)
                            TextButton.icon(
                              onPressed: () => widget.onPush?.call("Subject Registry"),
                              icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                              label: const Text("MANAGE SUBJECT REGISTRY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(foregroundColor: kBrandOlive),
                            ),
                        ],
                      ),
                      if (_isStrictFieldOfficer)
                        _compactStaticField("Secondary School", Icons.school_rounded)
                      else
                        _buildTypeSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _dropdownField<String>(
                    label: "Academic Year", 
                    value: _selectedYear, 
                    items: _academicYears, 
                    icon: Icons.calendar_today_rounded, 
                    onChanged: (v) {
                      setState(() {
                        _selectedYear = v;
                        _recordedPeriods = [];
                        _selectedPeriod = null;
                      });
                      if (_selectedStudent != null && v != null) {
                        _checkCompleteness(_selectedStudent!.id, int.parse(v));
                      }
                    }
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _dropdownField<String>(
                    label: "Partner Institution", 
                    value: _selectedSchool?['name'], 
                    items: _schoolOptions.map((s) => s['name'] as String).toList(), 
                    icon: Icons.apartment_rounded, 
                    onChanged: (v) {
                      setState(() {
                        _selectedSchool = _registeredSchools.firstWhere((s) => s['name'] == v);
                        _selectedStudent = null;
                      });
                    }
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _dropdownField<String>(
                    label: "Selected Scholar", 
                    value: _selectedStudent?.id, 
                    items: _scholarOptions.map((s) => s.id).toList(), 
                    icon: Icons.person_search_rounded, 
                    onChanged: _onScholarChanged,
                    itemLabel: (id) => _scholarOptions.firstWhere((s) => s.id == id).name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _dropdownField<String>(
                    label: _schoolType == SchoolType.secondary ? "Academic Term" : "Academic Semester",
                    value: _selectedPeriod,
                    items: _schoolType == SchoolType.secondary ? kTerms : kSemesters,
                    icon: Icons.event_note_rounded,
                    onChanged: (v) => setState(() => _selectedPeriod = v),
                  ),
                ),
                const SizedBox(width: 24),
                if (_schoolType == SchoolType.secondary)
                  Expanded(
                    child: _dropdownField<String>(
                      label: "Current Class", 
                      value: _selectedClass, 
                      items: _secondaryClasses, 
                      icon: Icons.class_outlined, 
                      onChanged: (v) => setState(() => _selectedClass = v)
                    ),
                  )
                else
                  Expanded(
                    child: _datePickerField("Results Date"),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _portalSelectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.0)),
    );
  }

  Widget _buildTypeSelector() {
    return IgnorePointer(
      ignoring: widget.forcedSchoolType != null,
      child: Opacity(
        opacity: widget.forcedSchoolType != null ? 0.6 : 1.0,
        child: SegmentedButton<SchoolType>(
          segments: const [
            ButtonSegment(value: SchoolType.secondary, label: Text("Secondary"), icon: Icon(Icons.school_outlined, size: 16)),
            ButtonSegment(value: SchoolType.university, label: Text("University"), icon: Icon(Icons.account_balance_outlined, size: 16)),
          ],
          selected: {_schoolType},
          onSelectionChanged: (s) => _onTypeChanged(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: const Color(0xFF9AB334),
            selectedForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
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

  Widget _buildResultsTable(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final avg = _currentAverage;
    final avgColor = _getScoreColor(avg);
    final avgLabel = _getScoreLabel(avg);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmall ? 16 : 24),
            decoration: BoxDecoration(
              color: avgColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PERFORMANCE SUMMARY", 
                        style: TextStyle(fontSize: isVerySmall ? 8 : 10, fontWeight: FontWeight.w900, color: avgColor, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text("${avg.toStringAsFixed(1)}% AVERAGE", 
                        style: TextStyle(fontSize: isVerySmall ? 15 : 18, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), letterSpacing: -0.5)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 10 : 16, vertical: isVerySmall ? 6 : 8),
                  decoration: BoxDecoration(color: avgColor, borderRadius: BorderRadius.circular(10)),
                  child: Text(avgLabel.toUpperCase(), 
                    style: TextStyle(color: Colors.white, fontSize: isVerySmall ? 9 : 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFFF9FAFB),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _tableHeader(isUniversity ? "COURSE NAME" : "SUBJECT")),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _tableHeader("SCORE (0-100)")),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _tableHeader("GRADE STANDING")),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildRow(_rows[index], index, isMobile),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _canEdit ? _portalAddRowBtn() : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _portalAddRowBtn() {
    return InkWell(
      onTap: _addRow,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF9AB334)),
            const SizedBox(width: 12),
            Text(isUniversity ? "ADD ANOTHER COURSE" : "APPEND NEW SUBJECT RECORD", 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF9AB334), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_ResultInputRow row, int index, bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    final score = double.tryParse(row.scoreController.text) ?? 0;
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);
    final hasScore = row.scoreController.text.isNotEmpty;

    if (isMobile) {
      return Container(
        padding: EdgeInsets.all(isVerySmall ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: isUniversity 
                    ? TextField(
                        controller: row.subjectController,
                        decoration: InputDecoration(
                          hintText: "Enter course name...",
                          hintStyle: TextStyle(fontSize: isVerySmall ? 12 : 13),
                          border: InputBorder.none,
                          isDense: true
                        ),
                        onChanged: (_) => setState(() {}),
                      )
                    : DropdownButtonFormField<String>(
                        value: _subjectOptions.any((s) => s.name == row.subjectController.text) ? row.subjectController.text : null,
                        hint: Text("Select subject...", style: TextStyle(fontSize: isVerySmall ? 12 : 13)),
                        isExpanded: true,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        items: _subjectOptions.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name, style: TextStyle(fontSize: isVerySmall ? 12 : 13), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => row.subjectController.text = v ?? ''),
                      ),
                ),
                IconButton(
                  onPressed: () => _removeRow(index),
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.scoreController,
                    enabled: _canEdit,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isVerySmall ? 12 : 13, color: hasScore ? color : kBrandBrown),
                    decoration: InputDecoration(
                      labelText: "SCORE (0-100)",
                      labelStyle: TextStyle(fontSize: isVerySmall ? 9 : 10),
                      hintText: "0",
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                if (hasScore)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: isVerySmall ? 8 : 9)),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: isUniversity 
                ? TextField(
                    controller: row.subjectController,
                    decoration: const InputDecoration(
                      hintText: "Enter course name...",
                      hintStyle: TextStyle(fontSize: 13),
                      border: InputBorder.none,
                      isDense: true
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                : DropdownButtonFormField<String>(
                    value: _subjectOptions.any((s) => s.name == row.subjectController.text) ? row.subjectController.text : null,
                    hint: const Text("Select subject...", style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    items: _subjectOptions.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => row.subjectController.text = v ?? ''),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: row.scoreController,
                enabled: _canEdit,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hasScore ? color : kBrandBrown),
                decoration: InputDecoration(
                  hintText: "0",
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: hasScore ? color.withOpacity(0.05) : Colors.transparent,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: color, width: 1.5)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: hasScore 
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _removeRow(index),
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: "Remove Row",
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isVerySmall ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: isVerySmall 
        ? Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF4C3C32), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text("Ensure all data is verified against marksheets.", 
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.verified_user_rounded, size: 16),
                  label: Text(_isSaving ? "SYNCING..." : "AUTHORIZE & SYNC", 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("DATA INTEGRITY VERIFICATION", 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 1.0)),
                    SizedBox(height: 4),
                    Text("Ensure all examination data is verified against physical marksheets before submission.", 
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 240,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.verified_user_rounded, size: 18),
                  label: Text(_isSaving ? "AUDITING..." : "AUTHORIZE & SYNC", 
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

  Widget _buildMissingSelectionHint() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.fact_check_rounded, size: 48, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text("Secure Result Entry Portal", 
            style: TextStyle(color: kBrandBrown, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text("Select a scholar and specify the academic period above\nto initialize the examination scorecard.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1));
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    // If it's Term or Semester selection, filter out recorded ones
    List<T> filteredItems = items;
    if (label.contains("Term") || label.contains("Semester")) {
      filteredItems = items.where((item) => !_recordedPeriods.contains(item as String)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: isVerySmall ? 11 : 12, fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButton<T>(
            value: filteredItems.contains(value) ? value : null,
            isExpanded: true,
            hint: Text("Select...", style: TextStyle(fontSize: isVerySmall ? 12 : 13)),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            items: filteredItems.map((e) => DropdownMenuItem<T>(
              value: e, 
              child: Text(itemLabel != null ? itemLabel(e) : e.toString(), style: TextStyle(fontSize: isVerySmall ? 12 : 13), overflow: TextOverflow.ellipsis)
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _datePickerField(String label) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: isVerySmall ? 11 : 12, fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _resultsDate, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (picked != null) setState(() => _resultsDate = picked);
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: isVerySmall ? 14 : 16, color: kBrandBrown),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy').format(_resultsDate), style: TextStyle(fontSize: isVerySmall ? 12 : 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultInputRow {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    scoreController.dispose();
  }
}
