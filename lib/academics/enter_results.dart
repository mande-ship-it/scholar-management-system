import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

// ============================================================
// Professional Academic Results Entry Portal
// ============================================================

class AcademicsManagementComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  const AcademicsManagementComponent({super.key, this.forcedSchoolType});

  @override
  State<AcademicsManagementComponent> createState() => _AcademicsManagementComponentState();
}

class _AcademicsManagementComponentState extends State<AcademicsManagementComponent> {
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
        final role = (res.data['data']['role_name'] ?? '').toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isFieldOfficer = role.contains('field');
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: EnterResultsComponent(forcedSchoolType: widget.forcedSchoolType)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandBrown.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_isFieldOfficer ? Icons.edit_note_rounded : Icons.visibility_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isFieldOfficer ? "Academic Results Entry" : "View Academic Records", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.8)),
                Text(_isFieldOfficer 
                    ? "Digitize and record scholar examination scores with automated grading."
                    : "Analyze and review official scholar performance records. Modification restricted.", 
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!_isFieldOfficer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("READ-ONLY ACCESS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EnterResultsComponent extends StatefulWidget {
  final SchoolType? forcedSchoolType;
  const EnterResultsComponent({super.key, this.forcedSchoolType});

  @override
  State<EnterResultsComponent> createState() => _EnterResultsComponentState();
}

class _EnterResultsComponentState extends State<EnterResultsComponent> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isFieldOfficer = false;

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
    _selectedYear = _academicYears.first;
    _addRow();
    _fetchBaseData();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final res = await ApiService.getAccountProfile();
      if (res.statusCode == 200) {
        final role = (res.data['data']['role_name'] ?? '').toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isFieldOfficer = role.contains('field');
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
      final subjectsRes = await ApiService.getSubjects();

      if (mounted) {
        setState(() {
          _registeredSchools = List<Map<String, dynamic>>.from(schoolsRes.data['data'] ?? []);
          
          final List<dynamic> scholarData = scholarsRes.data['data'] ?? [];
          _allScholars = scholarData.map((s) => Student(
            id: (s['id'] ?? s['_id'] ?? '').toString(),
            scholarId: s['scholar_id'] ?? 'N/A',
            name: s['full_name'] ?? 'N/A',
            status: s['status'] ?? 'Active',
            age: s['dob'] != null ? DateTime.now().year - DateTime.parse(s['dob']).year : 16,
            schoolType: s['school_type'] == 'University' || s['schoolType'] == 'University' ? SchoolType.university : SchoolType.secondary,
            schoolName: s['display_school_name'] ?? 'N/A',
            currentClass: s['academic_year'] ?? '',
          )).toList();

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

  bool _isPeriodDisabled = false;
  List<String> _recordedPeriods = [];

  Future<void> _checkCompleteness(String scholarId, int year) async {
    try {
      final res = await ApiService.checkResultCompleteness(scholarId, year);
      if (res.statusCode == 200) {
        final data = res.data['data'];
        setState(() {
          _recordedPeriods = List<String>.from(isUniversity ? (data['semestersRecorded'] ?? []) : (data['termsRecorded'] ?? []));
          if (data['isComplete'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("All academic results for this year have already been recorded."),
                backgroundColor: Colors.blue,
              ),
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

    final int minSubjects = _isFieldOfficer ? 8 : (isUniversity ? 5 : 6);
    final int maxSubjects = _isFieldOfficer ? 10 : (isUniversity ? 8 : 12);

    if (validResults.length < minSubjects) {
      _showError("Please enter at least $minSubjects ${isUniversity ? 'courses' : 'subjects'}.");
      return;
    }

    if (validResults.length > maxSubjects) {
      _showError("Maximum allowed is $maxSubjects ${isUniversity ? 'courses' : 'subjects'}.");
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
        // Sync the global kResults list with the new data from server
        try {
          final resultsRes = await ApiService.getResultsBySchool(null);
          if (resultsRes.statusCode == 200) {
            final List<dynamic> data = resultsRes.data['data'] ?? [];
            debugPrint('Synced ${data.length} results to global state.');
            kResults.clear();
            for (var item in data) {
              kResults.add(ResultRecord.fromMap(item));
            }
          }
        } catch (e) {
          debugPrint('Error syncing kResults: $e');
        }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectionPanel(),
          const SizedBox(height: 32),
          if (_selectedStudent != null && _selectedPeriod != null) ...[
            _buildResultsTable(),
            const SizedBox(height: 48),
            _buildActionFooter(),
          ] else
            _buildMissingSelectionHint(),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SCHOLAR & SESSION CONFIGURATION", 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
              if (_isFieldOfficer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.security_rounded, size: 14, color: kBrandOlive),
                      SizedBox(width: 8),
                      Text("VERIFIED ENTRY MODE", style: TextStyle(color: kBrandOlive, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Institution Level", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 12),
                    if (_isFieldOfficer)
                      Container(
                        height: 52,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: kBrandBrown.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBrandBrown.withOpacity(0.1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.school_rounded, size: 18, color: kBrandBrown),
                            SizedBox(width: 12),
                            Text("Secondary School Operations", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                          ],
                        ),
                      )
                    else
                      IgnorePointer(
                        ignoring: widget.forcedSchoolType != null,
                        child: Opacity(
                          opacity: widget.forcedSchoolType != null ? 0.6 : 1.0,
                          child: SegmentedButton<SchoolType>(
                            segments: const [
                              ButtonSegment(value: SchoolType.secondary, label: Text("Secondary"), icon: Icon(Icons.school_outlined, size: 18)),
                              ButtonSegment(value: SchoolType.university, label: Text("University"), icon: Icon(Icons.account_balance_outlined, size: 18)),
                            ],
                            selected: {_schoolType},
                            onSelectionChanged: (s) => _onTypeChanged(s.first),
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: kBrandOlive,
                              selectedForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
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
                  onChanged: (v) => setState(() => _selectedYear = v)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
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
                flex: 2,
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
      ),
    );
  }

  Widget _buildResultsTable() {
    final avg = _currentAverage;
    final avgColor = _getScoreColor(avg);
    final avgLabel = _getScoreLabel(avg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("EXAMINATION SCORECARD", 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: avgColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: avgColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(isUniversity ? "SEMESTER AVERAGE: ${avg.toStringAsFixed(1)}%" : "TERM AVERAGE: ${avg.toStringAsFixed(1)}%",
                    style: TextStyle(fontWeight: FontWeight.w900, color: avgColor, fontSize: 14)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: avgColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(avgLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Colors.grey.shade50,
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _tableHeader("SUBJECT / COURSE")),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _tableHeader("SCORE (0-100)")),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _tableHeader("STANDING")),
                    const SizedBox(width: 48), // Space for delete button
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rows.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _buildRow(_rows[index], index),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _isFieldOfficer ? OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Add Subject Row"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ) : const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_ResultInputRow row, int index) {
    final score = double.tryParse(row.scoreController.text) ?? 0;
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);
    final hasScore = row.scoreController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _subjectOptions.any((s) => s.name == row.subjectController.text) ? row.subjectController.text : null,
              hint: const Text("Select subject..."),
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none),
              items: _subjectOptions.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => row.subjectController.text = v ?? ''),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: TextField(
              controller: row.scoreController,
              enabled: _isFieldOfficer,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: hasScore ? color : kBrandBrown),
              decoration: InputDecoration(
                hintText: "0",
                filled: true,
                fillColor: hasScore ? color.withValues(alpha: 0.05) : Colors.transparent,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 2)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: hasScore 
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeRow(index),
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey),
            tooltip: "Remove Row",
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kBrandBrown.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: kBrandBrown, size: 20),
          const SizedBox(width: 16),
          const Expanded(child: Text("Ensure all examination data is verified against physical marksheets before authorizing submission to the central database.", 
            style: TextStyle(fontSize: 13, color: kBrandBrown, fontWeight: FontWeight.w500))),
          const SizedBox(width: 32),
          SizedBox(
            width: 280,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.verified_user_rounded),
              label: Text(_isSaving ? "AUTHORIZED SYNC..." : "AUTHORIZE & SAVE", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingSelectionHint() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.fact_check_rounded, size: 64, color: kBrandOlive),
          ),
          const SizedBox(height: 32),
          const Text("Secure Result Entry Portal", 
            style: TextStyle(color: kBrandBrown, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text("Select a scholar and specify the academic period above\nto initialize the examination scorecard.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5)),
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
    // If it's Term or Semester selection, filter out recorded ones
    List<T> filteredItems = items;
    if (label.contains("Term") || label.contains("Semester")) {
      filteredItems = items.where((item) => !_recordedPeriods.contains(item as String)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButton<T>(
            value: filteredItems.contains(value) ? value : null,
            isExpanded: true,
            hint: const Text("Select...", style: TextStyle(fontSize: 14)),
            underline: const SizedBox(),
            items: filteredItems.map((e) => DropdownMenuItem<T>(
              value: e, 
              child: Text(itemLabel != null ? itemLabel(e) : e.toString(), style: const TextStyle(fontSize: 14))
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _datePickerField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _resultsDate, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (picked != null) setState(() => _resultsDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20, color: kBrandBrown),
                const SizedBox(width: 12),
                Text(DateFormat('dd/MM/yyyy').format(_resultsDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
