import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          Expanded(
            child: Text(
              "Academic Recording",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              // Trigger reload in child if possible, or just re-init
              setState(() {});
            },
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Reset Form",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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

  // Quick Add Subject State
  final TextEditingController _newSubjectNameController = TextEditingController();
  final TextEditingController _newSubjectCodeController = TextEditingController();

  // Selection State
  late SchoolType _schoolType;
  Map<String, dynamic>? _selectedSchool;
  Student? _selectedStudent;

  // Session State
  String? _selectedYear;
  String? _selectedPeriod; // Term or Semester
  String? _selectedClass; // e.g. Form 1, Year 1
  DateTime _resultsDate = DateTime.now();

  final List<String> _secondaryClasses = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];
  final List<String> _universityClasses = ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5'];
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
          _availableSubjects = subjectData.map((sub) => Subject.fromMap(sub)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching base data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _quickAddSubject() async {
    if (_newSubjectNameController.text.isEmpty || _newSubjectCodeController.text.isEmpty) {
      _showError("Name and Code are required");
      return;
    }

    try {
      final res = await ApiService.createSubject({
        'name': _newSubjectNameController.text.trim(),
        'code': _newSubjectCodeController.text.trim().toUpperCase(),
        'level': _schoolType == SchoolType.secondary ? 'Secondary' : 'University',
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        _newSubjectNameController.clear();
        _newSubjectCodeController.clear();
        await _fetchBaseData();
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New subject added to registry."), backgroundColor: kBrandOlive),
        );
      } else {
        _showError(res.data['message'] ?? "Failed to add subject");
      }
    } catch (e) {
      _showError("Error adding subject: $e");
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Subject", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text("Are you sure you want to delete '${subject.name}'? This may affect existing academic records."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && subject.id != null) {
      try {
        final res = await ApiService.dio.delete('/academic/subjects/${subject.id}');
        if (res.statusCode == 200) {
          await _fetchBaseData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subject removed from registry."), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        _showError("Delete failed: $e");
      }
    }
  }

  void _showQuickAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Register New Subject", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newSubjectNameController,
              decoration: const InputDecoration(labelText: "Subject Name (e.g. Mathematics)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newSubjectCodeController,
              decoration: const InputDecoration(labelText: "Subject Code (e.g. MAT001)"),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: kBrandOlive),
                  const SizedBox(width: 8),
                  Text("Level: ${_schoolType == SchoolType.secondary ? 'Secondary' : 'University'}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandOlive)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _quickAddSubject,
            style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newSubjectNameController.dispose();
    _newSubjectCodeController.dispose();
    for (var row in _rows) row.dispose();
    super.dispose();
  }

  void _onScholarChanged(String? id) async {
    if (id == null) return;
    try {
      final student = _scholarOptions.firstWhere((s) => s.id == id);
      setState(() {
        _selectedStudent = student;
        _selectedPeriod = null;
        _recordedPeriods = [];
        _resultsByClass = {};
        
        // Auto-select the scholar's current class from database
        if (student.currentClass.isNotEmpty && student.currentClass != 'N/A') {
          _selectedClass = student.currentClass;
        }
      });

      if (_selectedYear != null) {
        _checkCompleteness(student.id, int.parse(_selectedYear!));
      }
    } catch (e) {
      debugPrint('Scholar selection error: $e');
    }
  }

  List<String> _recordedPeriods = [];
  Map<String, List<String>> _resultsByClass = {}; // For secondary: class -> recorded terms
  Map<String, List<String>> _failuresByClass = {}; // class -> terms/semesters with failures

  Future<void> _checkCompleteness(String scholarId, int year) async {
    try {
      final res = await ApiService.checkResultCompleteness(scholarId, year);
      if (res.statusCode == 200) {
        final data = res.data['data'];
        setState(() {
          _recordedPeriods = List<String>.from(isUniversity ? (data['semestersRecorded'] ?? []) : (data['termsRecorded'] ?? []));
          
          if (data['resultsByClass'] != null) {
            _resultsByClass = (data['resultsByClass'] as Map).map(
              (key, value) => MapEntry(key.toString(), List<String>.from(value))
            );
          }

          if (data['failuresByClass'] != null) {
            _failuresByClass = (data['failuresByClass'] as Map).map(
              (key, value) => MapEntry(key.toString(), List<String>.from(value))
            );
          }
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
    final grade = gradeFromMarks(score, isUniversity: isUniversity);
    if (grade.letter == 'Fail') return Colors.red.shade700;
    if (grade.letter == 'Pass') return Colors.blue.shade700;
    if (grade.letter == 'Credit') return Colors.orange.shade800;
    return Colors.green.shade700; // Distinction
  }

  String _getScoreLabel(double score) {
    return gradeFromMarks(score, isUniversity: isUniversity).letter;
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
        'currentClass': _selectedClass, // Send for both types now
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
          
          final String currentId = _selectedStudent!.id;
          final String? prevClass = _selectedClass;
          final String? prevYear = _selectedYear;

          // Re-fetch everything to see new progression state (backend calculates flags/history)
          await _fetchBaseData();
          
          if (mounted) {
            final updatedStudent = _allScholars.firstWhere((s) => s.id == currentId);
            setState(() {
              _selectedStudent = updatedStudent;
              _rows.clear();
              _addRow();
              _selectedPeriod = null;
              
              // --- Automatic Cycle Progression Logic (User Spec) ---
              if (prevClass != null && prevYear != null) {
                final allPossible = isUniversity ? _universityClasses : _secondaryClasses;
                final currentIdx = allPossible.indexOf(prevClass);
                
                // Get recorded periods for this SPECIFIC class after the save
                final List<String> recordedForPrev = (_resultsByClass[prevClass] ?? []);
                final bool isLastPeriod = isUniversity 
                    ? recordedForPrev.length >= 2 
                    : recordedForPrev.length >= 3;

                // Backend promotion check: check if history now contains 'Promoted' or 'Graduated' for this class
                final hasPassedThisClass = updatedStudent.progressionHistory.any((h) => 
                  h['from_class'].toString().trim().toLowerCase() == prevClass.trim().toLowerCase() && 
                  (h['result'].toString().toLowerCase().contains('promoted') || 
                   h['result'].toString().toLowerCase().contains('graduated'))
                );

                if (isLastPeriod && hasPassedThisClass && currentIdx < allPossible.length - 1) {
                  // Move UI forward: increment Year and Class
                  _selectedClass = allPossible[currentIdx + 1];
                  final int nextYearInt = int.parse(prevYear) + 1;
                  _selectedYear = nextYearInt.toString();
                  if (!_academicYears.contains(_selectedYear)) {
                    _academicYears.insert(0, _selectedYear!);
                  }
                } else {
                  _selectedClass = prevClass;
                  _selectedYear = prevYear;
                }
              }
            });
            
            if (_selectedYear != null) {
              await _checkCompleteness(currentId, int.parse(_selectedYear!));
            }
          }
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

  bool _isClassUnlocked(String className) {
    if (_selectedStudent == null) return false;
    
    final allPossible = isUniversity ? _universityClasses : _secondaryClasses;
    
    // Normalize function for robust comparison
    String norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final String target = norm(className);
    final String current = norm(_selectedStudent!.currentClass);
    final String registered = norm(_selectedStudent!.registeredClass ?? (isUniversity ? 'Year 1' : 'Form 1'));

    final int targetIdx = allPossible.indexWhere((c) => norm(c) == target);
    final int currentIdx = allPossible.indexWhere((c) => norm(c) == current);
    final int regIdx = allPossible.indexWhere((c) => norm(c) == registered);

    // 1. Any class at or before their current active class is always unlocked (Correction/Audit mode)
    if (currentIdx != -1 && targetIdx <= currentIdx) return true;

    // 2. Any class at or before their initial registration class is always unlocked
    if (regIdx != -1 && targetIdx <= regIdx) return true;

    // 3. The very first class in the sequence is always unlocked
    if (targetIdx == 0) return true;

    // 4. Future classes are unlocked if the immediate predecessor is in history as 'Promoted'
    if (targetIdx > 0) {
      final prevClass = norm(allPossible[targetIdx - 1]);
      final history = _selectedStudent!.progressionHistory;
      
      final passedPrev = history.any((h) {
        final fromClass = norm(h['from_class']?.toString() ?? '');
        final result = h['result']?.toString().toLowerCase() ?? '';
        return fromClass == prevClass && (result.contains('promoted') || result.contains('graduated'));
      });

      if (passedPrev) return true;
    }

    return false;
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
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showQuickAddSubjectDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 14),
                      label: const Text("QUICK ADD", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: kBrandOlive),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => widget.onPush?.call("Subject Registry"),
                      icon: const Icon(Icons.settings_suggest_rounded, size: 14),
                      label: const Text("MANAGE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: kBrandBrown),
                    ),
                  ],
                ),
              ],
            ),
            if (_isStrictFieldOfficer || widget.forcedSchoolType != null)
              _compactStaticField(
                widget.forcedSchoolType == SchoolType.university ? "University Level" : "Secondary School", 
                widget.forcedSchoolType == SchoolType.university ? Icons.account_balance_outlined : Icons.school_rounded
              )
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
              label: "Current Class", 
              value: _selectedClass, 
              items: isUniversity ? _universityClasses : _secondaryClasses, 
              icon: Icons.class_outlined, 
              onChanged: (v) {
                setState(() {
                  _selectedClass = v;
                  _selectedPeriod = null; // Reset term when class changes
                });
              }
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            _dropdownField<String>(
              label: isUniversity ? "Academic Semester" : "Academic Term",
              value: _selectedPeriod,
              items: isUniversity ? kSemesters : kTerms,
              icon: Icons.event_note_rounded,
              onChanged: (v) => setState(() => _selectedPeriod = v),
            ),
            if (isUniversity) ...[
              SizedBox(height: isVerySmall ? 16 : 24),
              _datePickerField("Results Date"),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _portalSelectionLabel("Institution Level"),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: _showQuickAddSubjectDialog,
                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                label: const Text("QUICK ADD SUBJECT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(foregroundColor: kBrandOlive),
                              ),
                              TextButton.icon(
                                onPressed: () => widget.onPush?.call("Subject Registry"),
                                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                                label: const Text("MANAGE REGISTRY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(foregroundColor: kBrandBrown),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_isStrictFieldOfficer || widget.forcedSchoolType != null)
                        _compactStaticField(
                          widget.forcedSchoolType == SchoolType.university ? "University Level" : "Secondary School", 
                          widget.forcedSchoolType == SchoolType.university ? Icons.account_balance_outlined : Icons.school_rounded
                        )
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
                    label: "Current Class", 
                    value: _selectedClass, 
                    items: isUniversity ? _universityClasses : _secondaryClasses, 
                    icon: Icons.class_outlined, 
                    onChanged: (v) {
                      setState(() {
                        _selectedClass = v;
                        _selectedPeriod = null; // Reset term when class changes
                      });
                    }
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _dropdownField<String>(
                    label: isUniversity ? "Academic Semester" : "Academic Term",
                    value: _selectedPeriod,
                    items: isUniversity ? kSemesters : kTerms,
                    icon: Icons.event_note_rounded,
                    onChanged: (v) => setState(() => _selectedPeriod = v),
                  ),
                ),
                if (isUniversity) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    child: _datePickerField("Results Date"),
                  ),
                ],
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
                    : Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _subjectOptions.any((s) => s.name == row.subjectController.text) ? row.subjectController.text : null,
                              hint: Text("Select subject...", style: TextStyle(fontSize: isVerySmall ? 12 : 13)),
                              isExpanded: true,
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                              items: _subjectOptions.map((s) => DropdownMenuItem<String>(
                          value: s.name, 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(s.name, style: TextStyle(fontSize: isVerySmall ? 12 : 13), overflow: TextOverflow.ellipsis)),
                              if (_canEdit)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context); // Close dropdown
                                    _deleteSubject(s);
                                  },
                                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                ),
                            ],
                          )
                        )).toList(),
                              onChanged: (v) => setState(() => row.subjectController.text = v ?? ''),
                            ),
                          ),
                          IconButton(
                            onPressed: _showQuickAddSubjectDialog,
                            icon: const Icon(Icons.add_circle_outline, color: kBrandOlive, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Quick add subject",
                          ),
                        ],
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        final val = double.tryParse(v);
                        if (val != null && val > 100) {
                          row.scoreController.text = "100";
                          row.scoreController.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                        }
                      }
                      setState(() {});
                    },
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
                : Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _subjectOptions.any((s) => s.name == row.subjectController.text) ? row.subjectController.text : null,
                          hint: const Text("Select subject...", style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          items: _subjectOptions.map((s) => DropdownMenuItem<String>(
                      value: s.name, 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          if (_canEdit)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context); // Close dropdown
                                _deleteSubject(s);
                              },
                              child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            ),
                        ],
                      )
                    )).toList(),
                          onChanged: (v) => setState(() => row.subjectController.text = v ?? ''),
                        ),
                      ),
                      IconButton(
                        onPressed: _showQuickAddSubjectDialog,
                        icon: const Icon(Icons.add_circle_outline, color: kBrandOlive, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Quick add subject",
                      ),
                    ],
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                onChanged: (v) {
                  if (v.isNotEmpty) {
                    final val = double.tryParse(v);
                    if (val != null && val > 100) {
                      row.scoreController.text = "100";
                      row.scoreController.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                    }
                  }
                  setState(() {});
                },
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
    
    // Logic for Term/Semester filtering and sequence enforcement
    List<T> filteredItems = items;
    bool isLocked = false;
    String lockReason = "";

    if (label.contains("Class")) {
      if (_selectedStudent == null) {
        isLocked = true;
        lockReason = "Select Scholar first";
        filteredItems = [];
      } else {
        filteredItems = items.where((item) => _isClassUnlocked(item as String)).toList();
      }
    }

    if (label.contains("Term") || label.contains("Semester")) {
      if (!isUniversity && _selectedClass == null) {
        isLocked = true;
        lockReason = "Select Class first";
        filteredItems = [];
      } else {
        // Find which periods are already recorded
        final targetClass = !isUniversity ? _selectedClass : _selectedClass;
        final List<String> recorded = (_resultsByClass[targetClass] ?? []);
        final List<String> failures = (_failuresByClass[targetClass] ?? []);

        // --- ENFORCEMENT LOGIC ---
        final List<String> available = [];
        
        if (!isUniversity) {
          // Secondary: Term 1 -> Term 2 -> Term 3
          if (!recorded.contains("Term 1") || failures.contains("Term 1")) {
            available.add("Term 1");
          } else if (!recorded.contains("Term 2") || failures.contains("Term 2")) {
            available.add("Term 2");
          } else if (!recorded.contains("Term 3") || failures.contains("Term 3")) {
            available.add("Term 3");
          } else {
            isLocked = true;
            lockReason = "All terms recorded";
          }
        } else {
          // University: Semester 1 -> Semester 2
          if (!recorded.contains("Semester 1") || failures.contains("Semester 1")) {
            available.add("Semester 1");
          } else if (!recorded.contains("Semester 2") || failures.contains("Semester 2")) {
            available.add("Semester 2");
          } else {
            isLocked = true;
            lockReason = "All semesters recorded";
          }
        }
        filteredItems = available.cast<T>();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: isVerySmall ? 11 : 12, fontWeight: FontWeight.bold, color: kBrandBrown)),
            if (isLocked)
              Text(lockReason.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey.shade100 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButton<T>(
            value: filteredItems.contains(value) ? value : null,
            isExpanded: true,
            disabledHint: Text(isLocked ? lockReason : "Select...", style: TextStyle(fontSize: isVerySmall ? 12 : 13, color: Colors.grey)),
            hint: Text("Select...", style: TextStyle(fontSize: isVerySmall ? 12 : 13)),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            items: filteredItems.map((e) => DropdownMenuItem<T>(
              value: e, 
              child: Text(itemLabel != null ? itemLabel(e) : e.toString(), style: TextStyle(fontSize: isVerySmall ? 12 : 13), overflow: TextOverflow.ellipsis)
            )).toList(),
            onChanged: isLocked ? null : onChanged,
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
