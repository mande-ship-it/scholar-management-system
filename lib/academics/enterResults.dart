import 'package:flutter/material.dart';
import 'academicsUtils.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

enum EntryMode { byScholar, bySubject }

class AcademicsManagementComponent extends StatefulWidget {
  const AcademicsManagementComponent({super.key});

  @override
  State<AcademicsManagementComponent> createState() => _AcademicsManagementComponentState();
}

class _AcademicsManagementComponentState extends State<AcademicsManagementComponent> {
  int _tabIndex = 0; // 0 = Enter Results, 1 = Add Subjects

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildTabToggle(),
        const SizedBox(height: 20),
        Expanded(
          child: _tabIndex == 0 ? const _EnterResultsSection() : const _AddSubjectsSection(),
        ),
      ],
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
              color: kBrandOlive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_rounded, color: kBrandOlive, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Academics Management",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandBrown),
                ),
                const SizedBox(height: 4),
                Text(
                  "Record scholar exam results and manage the subjects / courses registry.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Enter Results'), icon: Icon(Icons.post_add_rounded)),
        ButtonSegment(value: 1, label: Text('Add Subjects'), icon: Icon(Icons.library_books_rounded)),
      ],
      selected: {_tabIndex},
      onSelectionChanged: (selection) => setState(() => _tabIndex = selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kBrandOlive,
        selectedForegroundColor: Colors.white,
      ),
    );
  }
}

// ============================================================
// SECTION 1: ENTER RESULTS (Dynamic Mode)
// ============================================================

class _EnterResultsSection extends StatefulWidget {
  const _EnterResultsSection();

  @override
  State<_EnterResultsSection> createState() => _EnterResultsSectionState();
}

class _EnterResultsSectionState extends State<_EnterResultsSection> {
  EntryMode _mode = EntryMode.byScholar;
  SchoolType _schoolType = SchoolType.secondary;
  String? _selectedSchool;
  
  // Filters for "By Subject" mode
  final TextEditingController _subjectSearchController = TextEditingController();
  Subject? _matchedSubject;
  
  // Filters for "By Scholar" mode
  Student? _selectedStudent;

  final TextEditingController _yearController = TextEditingController(text: DateTime.now().year.toString());
  String? _selectedPeriod; // Term or Semester

  // Data for "By Subject" entry
  final Map<String, TextEditingController> _subjectMarksControllers = {};

  // Data for "By Scholar" entry
  List<_ScholarResultEntry> _scholarEntries = [];

  @override
  void initState() {
    super.initState();
    _scholarEntries.add(_ScholarResultEntry());
  }

  @override
  void dispose() {
    _yearController.dispose();
    _subjectSearchController.dispose();
    for (var c in _subjectMarksControllers.values) {
      c.dispose();
    }
    for (var e in _scholarEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _onModeChanged(Set<EntryMode> selection) {
    setState(() {
      _mode = selection.first;
      _resetData();
    });
  }

  void _onSchoolTypeChanged(SchoolType type) {
    setState(() {
      _schoolType = type;
      _selectedSchool = null;
      _matchedSubject = null;
      _subjectSearchController.clear();
      _selectedStudent = null;
      _selectedPeriod = null;
      _resetData();
    });
  }

  void _resetData() {
    for (var c in _subjectMarksControllers.values) {
      c.dispose();
    }
    _subjectMarksControllers.clear();
    for (var e in _scholarEntries) {
      e.dispose();
    }
    _scholarEntries = [_ScholarResultEntry()];
  }

  List<String> get _schoolOptions {
    final students = kStudents.where((s) => s.schoolType == _schoolType).toList();
    return students.map((s) => s.schoolName).toSet().toList()..sort();
  }

  List<Subject> get _subjectOptions {
    final level = _schoolType == SchoolType.secondary ? SubjectLevel.secondary : SubjectLevel.university;
    return kSubjects.where((s) => s.level == level).toList();
  }

  List<String> get _periodOptions => _schoolType == SchoolType.secondary 
      ? kTerms 
      : kSemesters;

  void _loadSubjectEntryData() {
    if (_subjectSearchController.text.isEmpty || _selectedSchool == null || _selectedPeriod == null || _yearController.text.isEmpty) return;
    
    final students = kStudents.where((s) => s.schoolType == _schoolType && s.schoolName == _selectedSchool).toList();
    
    // Clear old controllers
    for (var c in _subjectMarksControllers.values) {
      c.dispose();
    }
    _subjectMarksControllers.clear();

    final subjectName = _subjectSearchController.text.trim();

    for (var student in students) {
      final existing = kResults.firstWhere(
        (r) => r.studentId == student.id && 
               r.subject.toLowerCase() == subjectName.toLowerCase() && 
               r.year == _yearController.text &&
               (_schoolType == SchoolType.secondary ? r.term == _selectedPeriod : r.semester == _selectedPeriod),
        orElse: () => const ResultRecord(studentId: '', code: '', subject: '', marks: -1, year: ''),
      );

      final controller = TextEditingController();
      if (existing.marks != -1) {
        controller.text = existing.marks.toStringAsFixed(0);
      }
      _subjectMarksControllers[student.id] = controller;
    }
    setState(() {});
  }

  void _saveAll() {
    if (_mode == EntryMode.bySubject) {
      _saveBySubject();
    } else {
      _saveByScholar();
    }
  }

  Subject _getOrRegisterSubject(String name) {
    final level = _schoolType == SchoolType.secondary ? SubjectLevel.secondary : SubjectLevel.university;
    final existing = kSubjects.firstWhere(
      (s) => s.name.toLowerCase() == name.toLowerCase() && s.level == level,
      orElse: () => const Subject(name: '', code: '', details: '', notes: '', level: SubjectLevel.secondary),
    );
    
    if (existing.name.isNotEmpty) return existing;

    // Auto-register new subject
    final newSub = Subject(
      name: name,
      code: name.length >= 4 ? name.substring(0, 4).toUpperCase() + '101' : '${name.toUpperCase()}101',
      details: 'Auto-registered during results entry.',
      notes: '',
      level: level,
    );
    kSubjects.add(newSub);
    return newSub;
  }

  void _saveBySubject() {
    final subjectName = _subjectSearchController.text.trim();
    if (subjectName.isEmpty || _selectedSchool == null || _selectedPeriod == null || _yearController.text.isEmpty) {
      _showSnack('Please fill in all filters.', isError: true);
      return;
    }

    final subject = _getOrRegisterSubject(subjectName);
    int savedCount = 0;
    
    _subjectMarksControllers.forEach((studentId, controller) {
      final marksText = controller.text.trim();
      if (marksText.isNotEmpty) {
        final marks = double.tryParse(marksText);
        if (marks != null) {
          _updateOrAddResult(
            studentId: studentId,
            subject: subject,
            marks: marks,
            year: _yearController.text,
            period: _selectedPeriod!,
          );
          savedCount++;
        }
      }
    });

    _showSnack('Saved $savedCount result(s) for ${subject.name}.', isError: false);
  }

  void _saveByScholar() {
    if (_selectedStudent == null || _selectedPeriod == null || _yearController.text.isEmpty) {
      _showSnack('Please fill in all scholar details.', isError: true);
      return;
    }

    int savedCount = 0;
    for (var entry in _scholarEntries) {
      final subjectName = entry.subjectController.text.trim();
      if (subjectName.isNotEmpty && entry.marksController.text.isNotEmpty) {
        final marks = double.tryParse(entry.marksController.text);
        if (marks != null) {
          final subject = _getOrRegisterSubject(subjectName);
          _updateOrAddResult(
            studentId: _selectedStudent!.id,
            subject: subject,
            marks: marks,
            year: _yearController.text,
            period: _selectedPeriod!,
          );
          savedCount++;
        }
      }
    }
    _showSnack('Saved $savedCount result(s) for ${_selectedStudent!.name}.', isError: false);
    setState(() {
      _resetData();
      _selectedStudent = null;
    });
  }

  void _updateOrAddResult({
    required String studentId,
    required Subject subject,
    required double marks,
    required String year,
    required String period,
  }) {
    final isUni = _schoolType == SchoolType.university;
    final graded = gradeFromMarks(marks, isUniversity: isUni);

    final index = kResults.indexWhere(
      (r) => r.studentId == studentId && 
             r.subject.toLowerCase() == subject.name.toLowerCase() && 
             r.year == year &&
             (isUni ? r.semester == period : r.term == period),
    );

    final record = ResultRecord(
      studentId: studentId,
      code: subject.code,
      subject: subject.name,
      marks: marks,
      gpa: isUni ? graded.point : null,
      points: !isUni ? graded.point : null,
      year: year,
      term: !isUni ? period : null,
      semester: isUni ? period : null,
    );

    if (index != -1) {
      kResults[index] = record;
    } else {
      kResults.add(record);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? kBrandOrange : kBrandOlive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterCard(),
          const SizedBox(height: 16),
          if (_mode == EntryMode.bySubject) _buildBySubjectEntry() else _buildByScholarEntry(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveAll,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save All Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Entry Configuration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SegmentedButton<EntryMode>(
                segments: const [
                  ButtonSegment(value: EntryMode.byScholar, label: Text('By Scholar'), icon: Icon(Icons.person_outline)),
                  ButtonSegment(value: EntryMode.bySubject, label: Text('By Subject'), icon: Icon(Icons.subject_outlined)),
                ],
                selected: {_mode},
                onSelectionChanged: _onModeChanged,
                style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandOlive, selectedForegroundColor: Colors.white, visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<SchoolType>(
                  initialValue: _schoolType,
                  decoration: _inputDeco("School Type", Icons.category_outlined),
                  items: const [
                    DropdownMenuItem(value: SchoolType.secondary, child: Text('Secondary')),
                    DropdownMenuItem(value: SchoolType.university, child: Text('University')),
                  ],
                  onChanged: (v) => _onSchoolTypeChanged(v!),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSchool,
                  isExpanded: true,
                  decoration: _inputDeco("Select School", Icons.apartment_rounded),
                  items: _schoolOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() {
                    _selectedSchool = v;
                    if (_mode == EntryMode.bySubject) _loadSubjectEntryData();
                  }),
                ),
              ),
              if (_mode == EntryMode.bySubject)
                SizedBox(
                  width: 260,
                  child: Autocomplete<Subject>(
                    initialValue: TextEditingValue(text: _subjectSearchController.text),
                    optionsBuilder: (textValue) {
                      final options = _subjectOptions;
                      if (textValue.text.isEmpty) return options;
                      return options.where((s) => s.name.toLowerCase().contains(textValue.text.toLowerCase()));
                    },
                    displayStringForOption: (s) => s.name,
                    onSelected: (s) => setState(() {
                      _matchedSubject = s;
                      _subjectSearchController.text = s.name;
                      _loadSubjectEntryData();
                    }),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text != _subjectSearchController.text) {
                        // Ensure sync
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onFieldSubmitted: (v) => onFieldSubmitted(),
                        decoration: _inputDeco(_schoolType == SchoolType.university ? "Course Name" : "Subject Name", Icons.book_outlined).copyWith(
                          helperText: "Type to select or add new",
                        ),
                        onChanged: (v) {
                          _subjectSearchController.text = v;
                           _loadSubjectEntryData();
                        },
                      );
                    },
                  ),
                )
              else
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<Student>(
                    initialValue: _selectedStudent,
                    isExpanded: true,
                    decoration: _inputDeco("Select Scholar", Icons.person_search_rounded),
                    items: kStudents
                        .where((s) => s.schoolType == _schoolType && (_selectedSchool == null || s.schoolName == _selectedSchool))
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStudent = v),
                  ),
                ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco("Year", Icons.calendar_today_rounded),
                  onChanged: (_) {
                     if (_mode == EntryMode.bySubject) _loadSubjectEntryData();
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPeriod,
                  decoration: _inputDeco(_schoolType == SchoolType.secondary ? "Term" : "Semester", Icons.event_note_rounded),
                  items: _periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() {
                    _selectedPeriod = v;
                    if (_mode == EntryMode.bySubject) _loadSubjectEntryData();
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBySubjectEntry() {
    if (_subjectSearchController.text.isEmpty || _selectedSchool == null || _selectedPeriod == null) {
      return _buildPlaceholder("Enter course/subject name, select school, and period to begin entering marks.");
    }

    final students = kStudents.where((s) => s.schoolType == _schoolType && s.schoolName == _selectedSchool).toList();
    
    if (students.isEmpty) {
      return _buildPlaceholder("No students found for the selected school.");
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(kBrandCream),
        columnSpacing: 24,
        columns: [
          const DataColumn(label: Text('Scholar Name', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
          const DataColumn(label: Text('Marks (/100)', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
          const DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
          DataColumn(label: Text(_schoolType == SchoolType.university ? 'GPA' : 'GP', style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
        ],
        rows: students.map((s) {
          final controller = _subjectMarksControllers[s.id];
          if (controller == null) return const DataRow(cells: [DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text(''))]);
          
          final marks = double.tryParse(controller.text);
          final graded = marks != null ? gradeFromMarks(marks, isUniversity: _schoolType == SchoolType.university) : null;

          return DataRow(cells: [
            DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            DataCell(Text(graded?.letter ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandOrange))),
            DataCell(Text(graded?.point.toStringAsFixed(2) ?? '—')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildByScholarEntry() {
    if (_selectedStudent == null) {
      return _buildPlaceholder("Select a scholar to enter their results.");
    }

    final isUni = _schoolType == SchoolType.university;
    return Column(
      children: [
        const SizedBox(height: 16),
        ..._scholarEntries.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ScholarEntryRow(
              entry: item,
              subjects: _subjectOptions,
              onRemove: _scholarEntries.length > 1 ? () => setState(() => _scholarEntries.removeAt(index)) : null,
              isUniversity: isUni,
              onChanged: () => setState(() {}),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() => _scholarEntries.add(_ScholarResultEntry())),
          icon: const Icon(Icons.add),
          label: Text(isUni ? "Add Another Course" : "Add Another Subject"),
          style: OutlinedButton.styleFrom(foregroundColor: kBrandOlive, side: const BorderSide(color: kBrandOlive)),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
      child: Center(child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }
}

class _ScholarResultEntry {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController marksController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    marksController.dispose();
  }
}

class _ScholarEntryRow extends StatelessWidget {
  const _ScholarEntryRow({required this.entry, required this.subjects, this.onRemove, required this.isUniversity, required this.onChanged});
  
  final _ScholarResultEntry entry;
  final List<Subject> subjects;
  final VoidCallback? onRemove;
  final bool isUniversity;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final marks = double.tryParse(entry.marksController.text);
    final graded = marks != null ? gradeFromMarks(marks, isUniversity: isUniversity) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<Subject>(
              optionsBuilder: (textValue) {
                if (textValue.text.isEmpty) return subjects;
                return subjects.where((s) => s.name.toLowerCase().contains(textValue.text.toLowerCase()));
              },
              displayStringForOption: (s) => s.name,
              onSelected: (s) {
                entry.subjectController.text = s.name;
                onChanged();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text != entry.subjectController.text && entry.subjectController.text.isNotEmpty && controller.text.isEmpty) {
                   controller.text = entry.subjectController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: (v) => onFieldSubmitted(),
                  decoration: InputDecoration(
                    labelText: isUniversity ? "Course" : "Subject",
                    border: const OutlineInputBorder(),
                    helperText: "Type to select or add new",
                    isDense: true,
                  ),
                  onChanged: (v) {
                    entry.subjectController.text = v;
                    onChanged();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: entry.marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Marks", border: OutlineInputBorder(), isDense: true),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: kBrandCream, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(graded?.letter ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                if (graded != null)
                  Text(
                    isUniversity ? "GPA: ${graded.point.toStringAsFixed(2)}" : "GP: ${graded.point.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 9, color: kBrandBrown, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.delete_outline, color: kBrandOrange), onPressed: onRemove),
          ]
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 2: ADD SUBJECTS ( Registry Management )
// ============================================================

class _AddSubjectsSection extends StatefulWidget {
  const _AddSubjectsSection();

  @override
  State<_AddSubjectsSection> createState() => _AddSubjectsSectionState();
}

class _AddSubjectsSectionState extends State<_AddSubjectsSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _detailsController = TextEditingController();
  final _notesController = TextEditingController();
  SubjectLevel _level = SubjectLevel.secondary;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveSubject() {
    if (!_formKey.currentState!.validate()) return;
    
    final sub = Subject(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      details: _detailsController.text.trim(),
      notes: _notesController.text.trim(),
      level: _level,
    );
    
    setState(() {
      kSubjects.add(sub);
      _nameController.clear();
      _codeController.clear();
      _detailsController.clear();
      _notesController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject registered successfully.'), backgroundColor: kBrandOlive));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Form
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_level == SubjectLevel.university ? "Register New Course" : "Register New Subject", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 20),
                    SegmentedButton<SubjectLevel>(
                      segments: const [
                        ButtonSegment(value: SubjectLevel.secondary, label: Text('Secondary'), icon: Icon(Icons.school)),
                        ButtonSegment(value: SubjectLevel.university, label: Text('University'), icon: Icon(Icons.account_balance)),
                      ],
                      selected: {_level},
                      onSelectionChanged: (s) => setState(() => _level = s.first),
                      style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandOlive, selectedForegroundColor: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController, 
                      decoration: InputDecoration(
                        labelText: _level == SubjectLevel.university ? "Course Name" : "Subject Name", 
                        border: const OutlineInputBorder()
                      ), 
                      validator: (v) => v!.isEmpty ? 'Required' : null
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController, 
                      decoration: InputDecoration(
                        labelText: _level == SubjectLevel.university ? "Course Code (e.g. COM315)" : "Subject Code (e.g. MATH101)", 
                        border: const OutlineInputBorder()
                      ), 
                      validator: (v) => v!.isEmpty ? 'Required' : null
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _detailsController, maxLines: 2, decoration: const InputDecoration(labelText: "Details", border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder())),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveSubject, style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(_level == SubjectLevel.university ? "Register Course" : "Register Subject"))),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right: List
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Registry Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: kSubjects.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final s = kSubjects[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: s.level == SubjectLevel.secondary ? kBrandOlive : kBrandBrown, foregroundColor: Colors.white, child: Text(s.name[0])),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${s.code} • ${s.level.label}"),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: kBrandOrange), onPressed: () => setState(() => kSubjects.removeAt(index))),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
