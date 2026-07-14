import 'package:flutter/material.dart';
import 'academicsUtils.dart';

/// ---------------------------------------------------------------------
/// MODELS
/// ---------------------------------------------------------------------

enum SchoolType { secondary, university }

class Student {
  final String id;
  final String name;
  final int age;
  final SchoolType schoolType;
  final String schoolName;

  const Student({
    required this.id,
    required this.name,
    required this.age,
    required this.schoolType,
    required this.schoolName,
  });
}

class ResultRecord {
  final String studentId;
  final String subject;
  final double marks;
  final double? gpa; // university only
  final double? points; // secondary only
  final String year;
  final String? term;
  final String? semester;

  const ResultRecord({
    required this.studentId,
    required this.subject,
    required this.marks,
    this.gpa,
    this.points,
    required this.year,
    this.term,
    this.semester,
  });
}

/// ---------------------------------------------------------------------
/// SAMPLE DATA
/// ---------------------------------------------------------------------

const List<Student> kStudents = [
  Student(id: 's1', name: 'Chisomo Banda', age: 16, schoolType: SchoolType.secondary, schoolName: 'Kamuzu Academy'),
  Student(id: 's2', name: 'Thandiwe Phiri', age: 20, schoolType: SchoolType.university, schoolName: 'University of Malawi'),
  Student(id: 's3', name: 'Takondwa Mwale', age: 17, schoolType: SchoolType.secondary, schoolName: 'Chichiri Secondary School'),
  Student(id: 's4', name: 'Kondwani Nyirenda', age: 22, schoolType: SchoolType.university, schoolName: 'Mzuzu University'),
  Student(id: 's5', name: 'Chimwemwe Kaunda', age: 15, schoolType: SchoolType.secondary, schoolName: 'Providence High School'),
  Student(id: 's6', name: 'Tendai Chirwa', age: 21, schoolType: SchoolType.university, schoolName: 'Malawi University of Business and Applied Sciences'),
  Student(id: 's7', name: 'Mphatso Gondwe', age: 16, schoolType: SchoolType.secondary, schoolName: 'Kamuzu Academy'),
  Student(id: 's8', name: 'Yamikani Mbewe', age: 19, schoolType: SchoolType.university, schoolName: 'University of Malawi'),
];

const List<ResultRecord> kResults = [
  ResultRecord(studentId: 's1', subject: 'Mathematics', marks: 78, points: 6, year: '2026', term: 'Term 1'),
  ResultRecord(studentId: 's1', subject: 'English', marks: 65, points: 5, year: '2026', term: 'Term 1'),
  ResultRecord(studentId: 's1', subject: 'Biology', marks: 82, points: 7, year: '2026', term: 'Term 1'),
  ResultRecord(studentId: 's1', subject: 'Chichewa', marks: 74, points: 6, year: '2026', term: 'Term 1'),

  ResultRecord(studentId: 's2', subject: 'Data Structures', marks: 74, gpa: 3.6, year: '2026', semester: 'Semester 1'),
  ResultRecord(studentId: 's2', subject: 'Calculus II', marks: 68, gpa: 3.1, year: '2026', semester: 'Semester 1'),
  ResultRecord(studentId: 's2', subject: 'Database Systems', marks: 88, gpa: 4.0, year: '2026', semester: 'Semester 2'),

  ResultRecord(studentId: 's3', subject: 'Physical Science', marks: 71, points: 6, year: '2025', term: 'Term 3'),
  ResultRecord(studentId: 's3', subject: 'Chichewa', marks: 90, points: 8, year: '2025', term: 'Term 3'),

  ResultRecord(studentId: 's4', subject: 'Software Engineering', marks: 80, gpa: 3.8, year: '2026', semester: 'Semester 1'),
  ResultRecord(studentId: 's4', subject: 'Operating Systems', marks: 63, gpa: 2.9, year: '2026', semester: 'Semester 1'),

  ResultRecord(studentId: 's5', subject: 'Agriculture', marks: 85, points: 7, year: '2026', term: 'Term 1'),
  ResultRecord(studentId: 's5', subject: 'Chichewa', marks: 58, points: 4, year: '2026', term: 'Term 1'),

  ResultRecord(studentId: 's6', subject: 'Accounting', marks: 76, gpa: 3.4, year: '2026', semester: 'Semester 2'),
  ResultRecord(studentId: 's6', subject: 'Business Statistics', marks: 91, gpa: 4.0, year: '2026', semester: 'Semester 2'),

  ResultRecord(studentId: 's7', subject: 'Mathematics', marks: 93, points: 8, year: '2026', term: 'Term 1'),
  ResultRecord(studentId: 's7', subject: 'Physics', marks: 88, points: 8, year: '2026', term: 'Term 1'),
  ResultRecord(studentId: 's7', subject: 'Chichewa', marks: 70, points: 6, year: '2026', term: 'Term 1'),

  ResultRecord(studentId: 's8', subject: 'Microeconomics', marks: 95, gpa: 4.0, year: '2026', semester: 'Semester 1'),
  ResultRecord(studentId: 's8', subject: 'Statistics', marks: 89, gpa: 3.9, year: '2026', semester: 'Semester 1'),
];

const List<String> kTerms = ['Term 1', 'Term 2', 'Term 3'];
const List<String> kSemesters = ['Semester 1', 'Semester 2'];

/// ---------------------------------------------------------------------
/// HELPERS
/// ---------------------------------------------------------------------

enum ReportMode { student, school }

List<String> _allYears() => kResults.map((r) => r.year).toSet().toList()..sort();

List<ResultRecord> _resultsForStudent(
    String studentId, {
      String? year,
      String? period,
      required bool isUniversity,
    }) {
  return kResults.where((r) {
    if (r.studentId != studentId) return false;
    if (year != null && r.year != year) return false;
    if (period != null) {
      final p = isUniversity ? r.semester : r.term;
      if (p != period) return false;
    }
    return true;
  }).toList();
}

double _averageMarks(List<ResultRecord> records) {
  if (records.isEmpty) return 0;
  return records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
}

String _letterGrade(double marks) {
  if (marks >= 80) return 'A (Distinction)';
  if (marks >= 70) return 'B (Merit)';
  if (marks >= 60) return 'C (Credit)';
  if (marks >= 50) return 'D (Pass)';
  return 'F (Fail)';
}

String _remarkFor(double avg) {
  if (avg >= 80) return 'Excellent performance. Keep up the outstanding work.';
  if (avg >= 65) return 'Good performance overall, with room to push further.';
  if (avg >= 50) return 'Satisfactory performance. More effort is encouraged.';
  return 'Below expectation. Additional support is recommended.';
}

({int rank, int total}) _rankInSchool(
    String studentId,
    String schoolName, {
      String? year,
      String? period,
    }) {
  final peers = kStudents.where((s) => s.schoolName == schoolName).toList();
  final ranked = peers
      .map((s) => MapEntry(
    s.id,
    _averageMarks(_resultsForStudent(
      s.id,
      year: year,
      period: period,
      isUniversity: s.schoolType == SchoolType.university,
    )),
  ))
      .where((e) => e.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final index = ranked.indexWhere((e) => e.key == studentId);
  return (rank: index == -1 ? 0 : index + 1, total: ranked.length);
}

String _today() {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

/// ---------------------------------------------------------------------
/// COMPONENT
/// ---------------------------------------------------------------------

class ReportCardsComponent extends StatefulWidget {
  const ReportCardsComponent({super.key});

  @override
  State<ReportCardsComponent> createState() => _ReportCardsComponentState();
}

class _ReportCardsComponentState extends State<ReportCardsComponent> {
  ReportMode _mode = ReportMode.student;
  String? _selectedStudentId;
  String? _selectedSchool;
  String? _yearFilter;
  String? _periodFilter;

  List<String> get _schoolOptions =>
      kStudents.map((s) => s.schoolName).toSet().toList()..sort();

  bool get _isUniversitySelection {
    if (_mode == ReportMode.student && _selectedStudentId != null) {
      final s = kStudents.firstWhere((s) => s.id == _selectedStudentId);
      return s.schoolType == SchoolType.university;
    }
    if (_mode == ReportMode.school && _selectedSchool != null) {
      final s = kStudents.firstWhere((s) => s.schoolName == _selectedSchool);
      return s.schoolType == SchoolType.university;
    }
    return false;
  }

  void _onModeChanged(Set<ReportMode> selection) {
    setState(() {
      _mode = selection.first;
      _selectedStudentId = null;
      _selectedSchool = null;
      _yearFilter = null;
      _periodFilter = null;
    });
  }

  void _showExportNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Connecting to PDF printer... Transcript ready for download.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _mode == ReportMode.student
        ? _selectedStudentId != null
        : _selectedSchool != null;
    final periodOptions = _isUniversitySelection ? kSemesters : kTerms;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.picture_as_pdf_rounded, color: Colors.green.shade700, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Academic Report Cards',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            'Generate official student transcripts and school summaries.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (hasSelection)
                    ElevatedButton.icon(
                      onPressed: _showExportNotice,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
              const Divider(height: 32, thickness: 1.2),

              // Mode toggle
              SegmentedButton<ReportMode>(
                segments: const [
                  ButtonSegment(
                    value: ReportMode.student,
                    label: Text('Student Transcript'),
                    icon: Icon(Icons.badge_outlined),
                  ),
                  ButtonSegment(
                    value: ReportMode.school,
                    label: Text('School Summary'),
                    icon: Icon(Icons.apartment_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _onModeChanged,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.green.shade700,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Searchable selector
              if (_mode == ReportMode.student)
                Autocomplete<Student>(
                  displayStringForOption: (s) => s.name,
                  optionsBuilder: (textValue) {
                    final query = textValue.text.trim().toLowerCase();
                    if (query.isEmpty) return kStudents;
                    return kStudents.where(
                          (s) =>
                      s.name.toLowerCase().contains(query) ||
                          s.schoolName.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (s) => setState(() {
                    _selectedStudentId = s.id;
                    _yearFilter = null;
                    _periodFilter = null;
                  }),
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 320,
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final s = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.person, color: Colors.green.shade700),
                                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(s.schoolName),
                                onTap: () => onSelected(s),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Search for scholar...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            controller.clear();
                            setState(() => _selectedStudentId = null);
                          },
                        ),
                      ),
                    );
                  },
                )
              else
                Autocomplete<String>(
                  optionsBuilder: (textValue) {
                    final query = textValue.text.trim().toLowerCase();
                    if (query.isEmpty) return _schoolOptions;
                    return _schoolOptions
                        .where((name) => name.toLowerCase().contains(query));
                  },
                  onSelected: (name) => setState(() {
                    _selectedSchool = name;
                    _yearFilter = null;
                    _periodFilter = null;
                  }),
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 320,
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final name = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.apartment, color: Colors.blue.shade700),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                onTap: () => onSelected(name),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Search for school...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            controller.clear();
                            setState(() => _selectedSchool = null);
                          },
                        ),
                      ),
                    );
                  },
                ),

              // Year / Term filters
              if (hasSelection) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _yearFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter Academic Year',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Years')),
                          ..._allYears().map(
                                (y) => DropdownMenuItem(value: y, child: Text(y)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _yearFilter = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _periodFilter,
                        decoration: InputDecoration(
                          labelText: _isUniversitySelection ? 'Filter Semester' : 'Filter Term',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              _isUniversitySelection ? 'All Semesters' : 'All Terms',
                            ),
                          ),
                          ...periodOptions.map(
                                (p) => DropdownMenuItem(value: p, child: Text(p)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _periodFilter = v),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Report body
              if (!hasSelection)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.text_snippet_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _mode == ReportMode.student
                              ? 'Search for a scholar to generate their official transcript card.'
                              : 'Search for a school to generate school-wide exam results reports.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_mode == ReportMode.student)
                _StudentReportCard(
                  studentId: _selectedStudentId!,
                  year: _yearFilter,
                  period: _periodFilter,
                )
              else
                _SchoolReportCard(
                  schoolName: _selectedSchool!,
                  year: _yearFilter,
                  period: _periodFilter,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Student report card - Certificate/Official Transcript Style
/// ---------------------------------------------------------------------

class _StudentReportCard extends StatelessWidget {
  const _StudentReportCard({
    required this.studentId,
    this.year,
    this.period,
  });

  final String studentId;
  final String? year;
  final String? period;

  @override
  Widget build(BuildContext context) {
    final student = kStudents.firstWhere((s) => s.id == studentId);
    final isUniversity = student.schoolType == SchoolType.university;
    final records = _resultsForStudent(
      studentId,
      year: year,
      period: period,
      isUniversity: isUniversity,
    );
    final avgMarks = _averageMarks(records);
    final avgGpa = records.where((r) => r.gpa != null).isEmpty
        ? null
        : records.where((r) => r.gpa != null).map((r) => r.gpa!).reduce((a, b) => a + b) /
        records.where((r) => r.gpa != null).length;
    final totalPoints = records
        .where((r) => r.points != null)
        .fold<double>(0, (sum, r) => sum + (r.points ?? 0));
    final position = _rankInSchool(
      studentId,
      student.schoolName,
      year: year,
      period: period,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7), // Certificate warm paper color
        border: Border.all(color: const Color(0xFFC5A880), width: 3), // Goldish border
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo & Crest
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.schoolName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B4C3F), // Forest green school title
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AGE Africa Education Scholarship Program',
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC5A880), width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFFC5A880), size: 28), // crest icon placeholder
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFC5A880), thickness: 1.5),
          const SizedBox(height: 12),

          Center(
            child: Text(
              isUniversity ? 'OFFICIAL ACADEMIC TRANSCRIPT' : 'OFFICIAL ACADEMIC REPORT CARD',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Student Details Table
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _InfoLine(label: 'Full Name', value: student.name),
                _InfoLine(label: 'Scholar ID', value: student.id.toUpperCase()),
                _InfoLine(label: 'Scholar Age', value: '${student.age} Years'),
                _InfoLine(label: 'Institution Level', value: isUniversity ? 'University' : 'Secondary School'),
                _InfoLine(label: 'Academic Year', value: year ?? 'All Recorded Years'),
                _InfoLine(
                  label: isUniversity ? 'Academic Semester' : 'School Term',
                  value: period ?? (isUniversity ? 'All Semesters' : 'All Terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Text(
                'No exam scores recorded for the selected query filters.',
                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            )
          else ...[
            // Exam Table
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF2B4C3F)),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    return Colors.white;
                  }),
                  columns: [
                    DataColumn(label: Text(isUniversity ? 'Course Name' : 'Subject Name')),
                    const DataColumn(label: Text('Marks'), numeric: true),
                    DataColumn(label: Text(isUniversity ? 'GPA' : 'Points'), numeric: true),
                    if (!isUniversity) const DataColumn(label: Text('Letter Grade')),
                    const DataColumn(label: Text('Year')),
                    DataColumn(label: Text(isUniversity ? 'Semester' : 'Term')),
                  ],
                  rows: records.map((r) {
                    return DataRow(cells: [
                      DataCell(Text(r.subject, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${r.marks.toStringAsFixed(0)}%')),
                      DataCell(Text(isUniversity
                          ? (r.gpa ?? 0).toStringAsFixed(2)
                          : (r.points ?? 0).toStringAsFixed(0))),
                      if (!isUniversity)
                        DataCell(Text(_letterGrade(r.marks))),
                      DataCell(Text(r.year)),
                      DataCell(Text((isUniversity ? r.semester : r.term) ?? '-')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stat Summary Cards Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B4C3F), Color(0xFF3F6F5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))
                ],
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 14,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _SummaryStat(label: 'Subjects Enrolled', value: '${records.length}'),
                  _SummaryStat(label: 'Average Score', value: '${avgMarks.toStringAsFixed(1)}%'),
                  if (isUniversity)
                    _SummaryStat(
                      label: 'Cumulative GPA',
                      value: (avgGpa ?? 0).toStringAsFixed(2),
                    )
                  else
                    _SummaryStat(
                      label: 'Aggregate Points',
                      value: totalPoints.toStringAsFixed(0),
                    ),
                  _SummaryStat(
                    label: 'Overall Grade',
                    value: isUniversity ? (avgGpa ?? 0).toStringAsFixed(2) : _letterGrade(avgMarks).split(' ')[0],
                  ),
                  _SummaryStat(
                    label: 'School Ranking',
                    value: position.rank == 0 ? '—' : '${position.rank} / ${position.total}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Remarks section
            const Text(
              'Academic Faculty Remarks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              _remarkFor(avgMarks),
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 28),

            // Signatures block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Issued officially on ${_today()}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Row(
                  children: [
                    _SignatureLine(
                      name: 'Prof. E. Chimphamba',
                      label: isUniversity ? 'University Registrar' : 'Class Teacher',
                    ),
                    const SizedBox(width: 32),
                    _SignatureLine(
                      name: 'Dr. M. Nyasulu',
                      label: isUniversity ? 'Dean of Academics' : 'Head Teacher',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SchoolReportCard extends StatelessWidget {
  const _SchoolReportCard({
    required this.schoolName,
    this.year,
    this.period,
  });

  final String schoolName;
  final String? year;
  final String? period;

  @override
  Widget build(BuildContext context) {
    final students =
    kStudents.where((s) => s.schoolName == schoolName).toList();
    final isUniversity =
        students.isNotEmpty && students.first.schoolType == SchoolType.university;

    final rows = students.map((s) {
      final records = _resultsForStudent(
        s.id,
        year: year,
        period: period,
        isUniversity: isUniversity,
      );
      final avg = _averageMarks(records);
      return (student: s, records: records, average: avg);
    }).where((r) => r.records.isNotEmpty).toList()
      ..sort((a, b) => b.average.compareTo(a.average));

    final schoolAverage = rows.isEmpty
        ? 0.0
        : rows.map((r) => r.average).reduce((a, b) => a + b) / rows.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFA),
        border: Border.all(color: Colors.green.shade700, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  schoolName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SCHOOL EXAM RESULTS SUMMARY REPORT',
                  style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1.2),
          const SizedBox(height: 12),

          // Metadata block
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _InfoLine(label: 'Report Year', value: year ?? 'All Years'),
              _InfoLine(
                label: isUniversity ? 'Semester' : 'Term',
                value: period ?? (isUniversity ? 'All Semesters' : 'All Terms'),
              ),
              _InfoLine(label: 'Total Tested Students', value: '${rows.length}'),
              _InfoLine(label: 'Overall School Average', value: '${schoolAverage.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 20),

          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No results found matching this filter query.',
                  style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
                  columns: const [
                    DataColumn(label: Text('Rank')),
                    DataColumn(label: Text('Student ID')),
                    DataColumn(label: Text('Student Name')),
                    DataColumn(label: Text('Average Marks'), numeric: true),
                    DataColumn(label: Text('Performance Band')),
                  ],
                  rows: List.generate(rows.length, (index) {
                    final r = rows[index];
                    final band = performanceBand(r.average);
                    return DataRow(cells: [
                      DataCell(Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(r.student.id.toUpperCase())),
                      DataCell(Text(r.student.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${r.average.toStringAsFixed(1)}%')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: band.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            band.label,
                            style: TextStyle(color: band.color, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated on ${_today()}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                _SignatureLine(
                  name: 'Dr. G. Phiri',
                  label: 'AGE Africa Program Officer',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Reusable helper blocks
/// ---------------------------------------------------------------------

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.name, required this.label});

  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fake visual signature font styling (Courier / Italic)
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Courier',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2A4A),
          ),
        ),
        Container(
          width: 140,
          height: 1,
          color: Colors.grey.shade400,
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}