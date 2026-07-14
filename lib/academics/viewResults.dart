import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// MODELS
/// (In your real app these should be the same models used by
/// enterResults.dart / your backend — duplicated here only so this file
/// is self-contained and easy to preview.)
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
  final String code; // course/subject code e.g. "COM315"
  final String subject; // subject (secondary) or course title (university)
  final double marks;
  final double? gpa; // university only — grade point for this course
  final double? points; // secondary only — grade point for this course
  final String year; // e.g. "2026"
  final String? term; // secondary: "Term 1" / "Term 2" / "Term 3"
  final String? semester; // university: "Semester 1" / "Semester 2"

  const ResultRecord({
    required this.studentId,
    required this.code,
    required this.subject,
    required this.marks,
    this.gpa,
    this.points,
    required this.year,
    this.term,
    this.semester,
  });

  /// The grade point value regardless of secondary/university (whichever is set).
  double get gradePoint => gpa ?? points ?? 0;
}

/// ---------------------------------------------------------------------
/// SAMPLE DATA (replace with real data from your backend / database)
/// ---------------------------------------------------------------------

const List<Student> kStudents = [
  Student(
    id: 's1',
    name: 'Chisomo Banda',
    age: 16,
    schoolType: SchoolType.secondary,
    schoolName: 'Kamuzu Academy',
  ),
  Student(
    id: 's2',
    name: 'Thandiwe Phiri',
    age: 20,
    schoolType: SchoolType.university,
    schoolName: 'University of Malawi',
  ),
  Student(
    id: 's3',
    name: 'Takondwa Mwale',
    age: 17,
    schoolType: SchoolType.secondary,
    schoolName: 'Chichiri Secondary School',
  ),
  Student(
    id: 's4',
    name: 'Kondwani Nyirenda',
    age: 22,
    schoolType: SchoolType.university,
    schoolName: 'Mzuzu University',
  ),
  Student(
    id: 's5',
    name: 'Chimwemwe Kaunda',
    age: 15,
    schoolType: SchoolType.secondary,
    schoolName: 'Providence High School',
  ),
  Student(
    id: 's6',
    name: 'Tendai Chirwa',
    age: 21,
    schoolType: SchoolType.university,
    schoolName: 'Malawi University of Business and Applied Sciences',
  ),
];

const List<ResultRecord> kResults = [
  // Chisomo Banda — Kamuzu Academy (secondary)
  ResultRecord(
    studentId: 's1',
    code: 'MATH101',
    subject: 'Mathematics',
    marks: 78,
    points: 6,
    year: '2026',
    term: 'Term 1',
  ),
  ResultRecord(
    studentId: 's1',
    code: 'ENG102',
    subject: 'English',
    marks: 65,
    points: 5,
    year: '2026',
    term: 'Term 1',
  ),
  ResultRecord(
    studentId: 's1',
    code: 'BIO103',
    subject: 'Biology',
    marks: 82,
    points: 7,
    year: '2026',
    term: 'Term 2',
  ),

  // Thandiwe Phiri — University of Malawi
  ResultRecord(
    studentId: 's2',
    code: 'COM211',
    subject: 'Data Structures',
    marks: 74,
    gpa: 3.6,
    year: '2026',
    semester: 'Semester 1',
  ),
  ResultRecord(
    studentId: 's2',
    code: 'MATH212',
    subject: 'Calculus II',
    marks: 68,
    gpa: 3.1,
    year: '2026',
    semester: 'Semester 1',
  ),
  ResultRecord(
    studentId: 's2',
    code: 'COM222',
    subject: 'Database Systems',
    marks: 88,
    gpa: 4.0,
    year: '2026',
    semester: 'Semester 2',
  ),

  // Takondwa Mwale — Chichiri Secondary School
  ResultRecord(
    studentId: 's3',
    code: 'PHY301',
    subject: 'Physical Science',
    marks: 71,
    points: 6,
    year: '2025',
    term: 'Term 3',
  ),
  ResultRecord(
    studentId: 's3',
    code: 'CHI302',
    subject: 'Chichewa',
    marks: 90,
    points: 8,
    year: '2025',
    term: 'Term 3',
  ),

  // Kondwani Nyirenda — Mzuzu University
  ResultRecord(
    studentId: 's4',
    code: 'COM411',
    subject: 'Software Engineering',
    marks: 80,
    gpa: 3.8,
    year: '2026',
    semester: 'Semester 1',
  ),
  ResultRecord(
    studentId: 's4',
    code: 'COM412',
    subject: 'Operating Systems',
    marks: 63,
    gpa: 2.9,
    year: '2026',
    semester: 'Semester 1',
  ),

  // Chimwemwe Kaunda — Providence High School
  ResultRecord(
    studentId: 's5',
    code: 'AGR101',
    subject: 'Agriculture',
    marks: 85,
    points: 7,
    year: '2026',
    term: 'Term 1',
  ),

  // Tendai Chirwa — MUBAS
  ResultRecord(
    studentId: 's6',
    code: 'ACC421',
    subject: 'Accounting',
    marks: 76,
    gpa: 3.4,
    year: '2026',
    semester: 'Semester 2',
  ),
  ResultRecord(
    studentId: 's6',
    code: 'STA422',
    subject: 'Business Statistics',
    marks: 91,
    gpa: 4.0,
    year: '2026',
    semester: 'Semester 2',
  ),
];

const List<String> kTerms = ['Term 1', 'Term 2', 'Term 3'];
const List<String> kSemesters = ['Semester 1', 'Semester 2'];

/// Derives a letter grade from a mark out of 100.
/// Adjust the bands here to match your institution's actual grading scale.
String letterGradeFor(double marks) {
  if (marks >= 80) return 'A+';
  if (marks >= 75) return 'A';
  if (marks >= 70) return 'B+';
  if (marks >= 65) return 'B';
  if (marks >= 60) return 'B-';
  if (marks >= 55) return 'C+';
  if (marks >= 50) return 'C';
  if (marks >= 45) return 'C-';
  if (marks >= 40) return 'D';
  return 'F';
}

/// ---------------------------------------------------------------------
/// COMPONENT
/// ---------------------------------------------------------------------

class ViewResultsComponent extends StatefulWidget {
  const ViewResultsComponent({super.key});

  @override
  State<ViewResultsComponent> createState() => _ViewResultsComponentState();
}

class _ViewResultsComponentState extends State<ViewResultsComponent> {
  final TextEditingController _searchController = TextEditingController();

  SchoolType? _schoolTypeFilter; // null = All
  String? _schoolNameFilter; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _schoolNameOptions {
    final students = _schoolTypeFilter == null
        ? kStudents
        : kStudents.where((s) => s.schoolType == _schoolTypeFilter).toList();
    final names = students.map((s) => s.schoolName).toSet().toList()..sort();
    return names;
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    return kStudents.where((s) {
      final matchesQuery = query.isEmpty || s.name.toLowerCase().contains(query);
      final matchesType =
          _schoolTypeFilter == null || s.schoolType == _schoolTypeFilter;
      final matchesSchool =
          _schoolNameFilter == null || s.schoolName == _schoolNameFilter;
      return matchesQuery && matchesType && matchesSchool;
    }).toList();
  }

  void _openStudentResults(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentExamResultsSheet(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2), // warm off-white background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Results',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _schoolTypeFilter = null;
                      _schoolNameFilter = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---------------- Search by student name ----------------
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by student name',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(_searchController.clear),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // ---------------- School type + school name filters ----------------
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<SchoolType?>(
                      initialValue: _schoolTypeFilter,
                      decoration: const InputDecoration(
                        labelText: 'School Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(
                          value: SchoolType.secondary,
                          child: Text('Secondary'),
                        ),
                        DropdownMenuItem(
                          value: SchoolType.university,
                          child: Text('University'),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _schoolTypeFilter = v;
                        _schoolNameFilter = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _schoolNameFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'School Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._schoolNameOptions.map(
                              (name) => DropdownMenuItem(
                            value: name,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _schoolNameFilter = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(),

              // ---------------- Filtered student list ----------------
              Expanded(
                child: students.isEmpty
                    ? const Center(
                  child: Text('No students match your filters.'),
                )
                    : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final resultCount = kResults
                        .where((r) => r.studentId == student.id)
                        .length;
                    final isUniversity =
                        student.schoolType == SchoolType.university;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Text(
                        '${isUniversity ? 'University' : 'Secondary'} • '
                            '${student.schoolName} • $resultCount result(s)',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openStudentResults(student),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Exam results transcript sheet — mirrors the "Semester/Term Courses"
/// exam-results layout, grouped by period, with a Code / Title /
/// Final Grade / Letter Grade / Grade Point table (no Type column) and
/// a GPA + pass/proceed summary at the bottom.
/// ---------------------------------------------------------------------

class _StudentExamResultsSheet extends StatefulWidget {
  const _StudentExamResultsSheet({required this.student});

  final Student student;

  @override
  State<_StudentExamResultsSheet> createState() =>
      _StudentExamResultsSheetState();
}

class _StudentExamResultsSheetState extends State<_StudentExamResultsSheet> {
  late String _selectedYear;

  bool get _isUniversity => widget.student.schoolType == SchoolType.university;

  List<ResultRecord> get _studentResults =>
      kResults.where((r) => r.studentId == widget.student.id).toList();

  List<String> get _yearOptions {
    final years = _studentResults.map((r) => r.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a)); // most recent first
    return years;
  }

  List<String> get _periods => _isUniversity ? kSemesters : kTerms;

  @override
  void initState() {
    super.initState();
    _selectedYear = _yearOptions.isNotEmpty ? _yearOptions.first : '';
  }

  List<ResultRecord> _resultsFor(String period) {
    return _studentResults.where((r) {
      final matchesYear = r.year == _selectedYear;
      final matchesPeriod = _isUniversity ? r.semester == period : r.term == period;
      return matchesYear && matchesPeriod;
    }).toList();
  }

  double _gpaFor(List<ResultRecord> records) {
    if (records.isEmpty) return 0;
    return records.map((r) => r.gradePoint).reduce((a, b) => a + b) / records.length;
  }

  @override
  Widget build(BuildContext context) {
    final periodsWithResults = _periods.where((p) => _resultsFor(p).isNotEmpty).toList();
    final allYearResults =
    _studentResults.where((r) => r.year == _selectedYear).toList();
    final endOfYearGpa = _gpaFor(allYearResults);
    final passed = allYearResults.isNotEmpty && endOfYearGpa >= 2.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ---------------- Header bar ----------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A4A),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EXAM RESULTS — ${widget.student.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_yearOptions.length > 1)
                      DropdownButton<String>(
                        value: _selectedYear,
                        dropdownColor: const Color(0xFF1B2A4A),
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(color: Colors.white),
                        items: _yearOptions
                            .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ---------------- Scrollable body ----------------
              Expanded(
                child: periodsWithResults.isEmpty
                    ? const Center(child: Text('No results recorded yet.'))
                    : SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final period in periodsWithResults) ...[
                        _PeriodResultsTable(
                          periodLabel: '$period Courses',
                          records: _resultsFor(period),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              // ---------------- Footer: GPA summary + pass/proceed ----------------
              if (periodsWithResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      for (final period in periodsWithResults)
                        Text(
                          '$period GPA: ${_gpaFor(_resultsFor(period)).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      Text(
                        'End of Year GPA: ${endOfYearGpa.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: passed ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          passed ? 'PASS AND PROCEED' : 'BELOW REQUIREMENT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One "<Period> Courses" section with its results table.
/// Columns: # | Code | Title | Final Grade | Letter Grade | Grade Point
/// (Type column intentionally omitted.)
class _PeriodResultsTable extends StatelessWidget {
  const _PeriodResultsTable({required this.periodLabel, required this.records});

  final String periodLabel;
  final List<ResultRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          periodLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Final Grade')),
              DataColumn(label: Text('Letter Grade')),
              DataColumn(label: Text('Grade Point')),
            ],
            rows: List.generate(records.length, (index) {
              final r = records[index];
              final letter = letterGradeFor(r.marks);
              return DataRow(cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      r.code,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                DataCell(Text(r.subject)),
                DataCell(
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue.shade600,
                    child: Text(
                      r.marks.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                DataCell(Text(letter)),
                DataCell(Text(r.gradePoint.toStringAsFixed(2))),
              ]);
            }),
          ),
        ),
      ],
    );
  }
}