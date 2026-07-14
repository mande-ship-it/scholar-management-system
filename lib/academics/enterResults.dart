import 'package:flutter/material.dart';
import 'academicsUtils.dart';

class ResultEntry {
  ResultEntry({SchoolType type = SchoolType.secondary})
      : subjectController = TextEditingController(),
        marksController = TextEditingController(),
        gpaController = TextEditingController(),
        pointsController = TextEditingController(),
        yearController = TextEditingController(text: DateTime.now().year.toString()),
        term = 'Term 1',
        semester = 'Semester 1',
        schoolType = type;

  SchoolType schoolType;
  final TextEditingController subjectController;
  final TextEditingController marksController;
  final TextEditingController gpaController;
  final TextEditingController pointsController;
  final TextEditingController yearController;
  String term;
  String semester;

  void dispose() {
    subjectController.dispose();
    marksController.dispose();
    gpaController.dispose();
    pointsController.dispose();
    yearController.dispose();
  }
}

/// ---------------------------------------------------------------------
/// SAMPLE DATA
/// ---------------------------------------------------------------------

const List<String> kSecondarySchools = [
  'Kamuzu Academy',
  'Chichiri Secondary School',
  'St. Andrews International High School',
  'Providence High School',
];

const List<String> kUniversities = [
  'University of Malawi',
  'Mzuzu University',
  'Malawi University of Business and Applied Sciences',
  'Lilongwe University of Agriculture and Natural Resources',
];

const List<String> kTerms = ['Term 1', 'Term 2', 'Term 3'];
const List<String> kSemesters = ['Semester 1', 'Semester 2'];

/// ---------------------------------------------------------------------
/// COMPONENT
/// ---------------------------------------------------------------------

class EnterResultsComponent extends StatefulWidget {
  const EnterResultsComponent({super.key});

  @override
  State<EnterResultsComponent> createState() => _EnterResultsComponentState();
}

class _EnterResultsComponentState extends State<EnterResultsComponent> {
  final _formKey = GlobalKey<FormState>();

  SchoolType _schoolType = SchoolType.secondary;
  String? _selectedSchool;
  Student? _selectedStudent;

  final List<ResultEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _entries.add(ResultEntry(type: _schoolType));
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  List<String> get _schoolOptions =>
      _schoolType == SchoolType.secondary ? kSecondarySchools : kUniversities;

  void _onSchoolTypeChanged(SchoolType type) {
    setState(() {
      _schoolType = type;
      _selectedSchool = null;
      _selectedStudent = null;
      for (final e in _entries) {
        e.dispose();
      }
      _entries
        ..clear()
        ..add(ResultEntry(type: _schoolType));
    });
  }

  void _addEntryRow() {
    setState(() {
      _entries.add(ResultEntry(type: _schoolType));
    });
  }

  void _removeEntryRow(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  void _saveResults() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSchool == null) {
      _showSnack('Please select a school.', isError: true);
      return;
    }
    if (_selectedStudent == null) {
      _showSnack('Please select a student.', isError: true);
      return;
    }

    // Add entries to the global list kResults
    for (final e in _entries) {
      final subjectName = e.subjectController.text.trim();
      final yearVal = e.yearController.text.trim();
      final marksVal = double.tryParse(e.marksController.text.trim()) ?? 0;
      
      // Determine code
      String codeVal = '';
      final existingSub = kSubjects.firstWhere(
        (s) => s['name'].toString().toLowerCase() == subjectName.toLowerCase(),
        orElse: () => {},
      );
      if (existingSub.isNotEmpty) {
        codeVal = existingSub['code'] ?? (subjectName.length >= 4 ? subjectName.substring(0, 4).toUpperCase() + '101' : 'SUBJ101');
      } else {
        codeVal = subjectName.length >= 4 ? subjectName.substring(0, 4).toUpperCase() + '101' : 'SUBJ101';
      }

      final record = ResultRecord(
        studentId: _selectedStudent!.id,
        code: codeVal,
        subject: subjectName,
        marks: marksVal,
        gpa: _schoolType == SchoolType.university ? (double.tryParse(e.gpaController.text.trim()) ?? 0) : null,
        points: _schoolType == SchoolType.secondary ? (double.tryParse(e.pointsController.text.trim()) ?? 0) : null,
        year: yearVal,
        term: _schoolType == SchoolType.secondary ? e.term : null,
        semester: _schoolType == SchoolType.university ? e.semester : null,
      );

      kResults.add(record);

      // Add to global subjects list kSubjects if it doesn't already exist for this level
      final levelVal = _schoolType == SchoolType.secondary ? SubjectLevel.secondary : SubjectLevel.university;
      final subjectExists = kSubjects.any((sub) =>
          sub['name'].toString().toLowerCase() == subjectName.toLowerCase() &&
          sub['level'] == levelVal);
      if (!subjectExists) {
        kSubjects.add({
          'name': subjectName,
          'details': 'Added from exam results entry.',
          'notes': 'Automatically registered.',
          'level': levelVal,
          'code': codeVal,
        });
      }
    }

    _showSnack(
      'Saved ${_entries.length} result(s) for ${_selectedStudent!.name} successfully.',
      isError: false,
    );

    setState(() {
      for (final e in _entries) {
        e.dispose();
      }
      _entries
        ..clear()
        ..add(ResultEntry(type: _schoolType));
      _selectedStudent = null;
    });
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: Colors.green.shade700),
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
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUniversity = _schoolType == SchoolType.university;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.post_add_rounded, color: Colors.green.shade700, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Exam Results',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          'Record test scores and grades for scholars.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1.2),

                // School Type Choice
                const Text(
                  'Institution Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                SegmentedButton<SchoolType>(
                  segments: const [
                    ButtonSegment(
                      value: SchoolType.secondary,
                      label: Text('Secondary School'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: SchoolType.university,
                      label: Text('University / College'),
                      icon: Icon(Icons.account_balance_outlined),
                    ),
                  ],
                  selected: {_schoolType},
                  onSelectionChanged: (selection) => _onSchoolTypeChanged(selection.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.green.shade700,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // School Name Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSchool,
                  decoration: _getInputDecoration(
                    labelText: 'School / Institution Name',
                    prefixIcon: Icons.apartment_rounded,
                  ),
                  items: _schoolOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedSchool = v;
                    _selectedStudent = null; // Clear selected student on school change
                  }),
                  validator: (v) => v == null || v.isEmpty ? 'Please select a school' : null,
                ),
                const SizedBox(height: 16),

                // Student Dropdown
                DropdownButtonFormField<Student>(
                  value: _selectedStudent,
                  isExpanded: true,
                  decoration: _getInputDecoration(
                    labelText: 'Select Scholar',
                    prefixIcon: Icons.person_search_rounded,
                  ),
                  items: kStudents
                      .where((s) => s.schoolType == _schoolType && (_selectedSchool == null || s.schoolName == _selectedSchool))
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name}  •  Age ${s.age}  •  ${s.schoolName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudent = v),
                  validator: (v) => v == null ? 'Please select a scholar' : null,
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUniversity ? 'Course Scores' : 'Subject Scores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addEntryRow,
                      icon: const Icon(Icons.add),
                      label: Text(isUniversity ? 'Add Course' : 'Add Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade800,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dynamic entry rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _ResultEntryCard(
                      entry: _entries[index],
                      isUniversity: isUniversity,
                      canRemove: _entries.length > 1,
                      onRemove: () => _removeEntryRow(index),
                    );
                  },
                ),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _saveResults,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'Save Results Record',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// A single subject / course result row card
/// ---------------------------------------------------------------------

class _ResultEntryCard extends StatefulWidget {
  const _ResultEntryCard({
    required this.entry,
    required this.isUniversity,
    required this.canRemove,
    required this.onRemove,
  });

  final ResultEntry entry;
  final bool isUniversity;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_ResultEntryCard> createState() => _ResultEntryCardState();
}

class _ResultEntryCardState extends State<_ResultEntryCard> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final themeColor = widget.isUniversity ? Colors.blue : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(color: themeColor.shade700, width: 4),
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  textEditingController: entry.subjectController,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    final level = widget.isUniversity ? SubjectLevel.university : SubjectLevel.secondary;
                    final options = kSubjects
                        .where((s) => s['level'] == level)
                        .map((s) => s['name'] as String)
                        .toList();
                    if (query.isEmpty) {
                      return options;
                    }
                    return options.where((opt) => opt.toLowerCase().contains(query));
                  },
                  onSelected: (String selection) {
                    entry.subjectController.text = selection;
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 250,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final opt = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.menu_book_rounded, color: themeColor.shade700, size: 18),
                                title: Text(opt, style: const TextStyle(fontWeight: FontWeight.bold)),
                                onTap: () => onSelected(opt),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: widget.isUniversity ? 'Course Name / Title' : 'Subject Name / Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.menu_book_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject name required' : null,
                    );
                  },
                ),
              ),
              if (widget.canRemove) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove Row',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: widget.onRemove,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.marksController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Marks (out of 100)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.grade_rounded),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Marks required';
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Enter a number';
                    if (n < 0 || n > 100) return 'Must be 0-100';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: widget.isUniversity ? entry.gpaController : entry.pointsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: widget.isUniversity ? 'GPA' : 'Points',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(
                      widget.isUniversity ? Icons.stacked_line_chart_rounded : Icons.star_border_rounded,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Grade point required';
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Enter a number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Academic Year',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Year required' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: widget.isUniversity
                    ? DropdownButtonFormField<String>(
                        initialValue: entry.semester,
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.event_note_rounded),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: kSemesters
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => entry.semester = v);
                        },
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: entry.term,
                        decoration: InputDecoration(
                          labelText: 'Term',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.event_note_rounded),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: kTerms
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => entry.term = v);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}