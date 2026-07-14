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
  ResultRecord(studentId: 's1', subject: 'Biology', marks: 82, points: 7, year: '2026', term: 'Term 2'),

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

  ResultRecord(studentId: 's8', subject: 'Microeconomics', marks: 95, gpa: 4.0, year: '2026', semester: 'Semester 1'),
  ResultRecord(studentId: 's8', subject: 'Statistics', marks: 89, gpa: 3.9, year: '2026', semester: 'Semester 1'),
];

/// ---------------------------------------------------------------------
/// ANALYTICS HELPERS
/// ---------------------------------------------------------------------

enum AnalysisMode { student, school }

List<ResultRecord> _resultsFor(String studentId) =>
    kResults.where((r) => r.studentId == studentId).toList();

double _averageMarks(List<ResultRecord> records) {
  if (records.isEmpty) return 0;
  return records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
}

double? _averageGpa(List<ResultRecord> records) {
  final withGpa = records.where((r) => r.gpa != null).toList();
  if (withGpa.isEmpty) return null;
  return withGpa.map((r) => r.gpa!).reduce((a, b) => a + b) / withGpa.length;
}

double? _averagePoints(List<ResultRecord> records) {
  final withPoints = records.where((r) => r.points != null).toList();
  if (withPoints.isEmpty) return null;
  return withPoints.map((r) => r.points!).reduce((a, b) => a + b) /
      withPoints.length;
}

List<MapEntry<Student, double>> _rankedStudents() {
  final entries = kStudents
      .map((s) => MapEntry(s, _averageMarks(_resultsFor(s.id))))
      .where((e) => e.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

List<MapEntry<String, double>> _rankedSchools() {
  final schoolNames = kStudents.map((s) => s.schoolName).toSet();
  final entries = schoolNames.map((school) {
    final studentIds =
    kStudents.where((s) => s.schoolName == school).map((s) => s.id);
    final records =
    kResults.where((r) => studentIds.contains(r.studentId)).toList();
    return MapEntry(school, _averageMarks(records));
  }).where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

/// ---------------------------------------------------------------------
/// COMPONENT
/// ---------------------------------------------------------------------

class PerformanceAnalysisComponent extends StatefulWidget {
  const PerformanceAnalysisComponent({super.key});

  @override
  State<PerformanceAnalysisComponent> createState() =>
      _PerformanceAnalysisComponentState();
}

class _PerformanceAnalysisComponentState
    extends State<PerformanceAnalysisComponent> {
  AnalysisMode _mode = AnalysisMode.student;
  String? _selectedStudentId;
  String? _selectedSchool;

  List<String> get _schoolOptions =>
      kStudents.map((s) => s.schoolName).toSet().toList()..sort();

  void _onModeChanged(Set<AnalysisMode> selection) {
    setState(() {
      _mode = selection.first;
      _selectedStudentId = null;
      _selectedSchool = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankedStudents = _rankedStudents();
    final rankedSchools = _rankedSchools();

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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.analytics_rounded, color: Colors.green.shade700, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Performance Analysis',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Insights and statistics across scholars and institutions.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1.2),

              // Banners
              Row(
                children: [
                  Expanded(
                    child: _TopPerformerBanner(
                      icon: Icons.workspace_premium_rounded,
                      startColor: Colors.amber.shade700,
                      endColor: Colors.orange.shade600,
                      title: rankedStudents.isEmpty ? 'No data yet' : rankedStudents.first.key.name,
                      subtitle: rankedStudents.isEmpty
                          ? 'Top Student'
                          : 'Top Student • ${rankedStudents.first.value.toStringAsFixed(1)}% Avg',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TopPerformerBanner(
                      icon: Icons.school_rounded,
                      startColor: Colors.indigo.shade600,
                      endColor: Colors.blue.shade500,
                      title: rankedSchools.isEmpty ? 'No data yet' : rankedSchools.first.key,
                      subtitle: rankedSchools.isEmpty
                          ? 'Top School'
                          : 'Top School • ${rankedSchools.first.value.toStringAsFixed(1)}% Avg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mode toggle
              SegmentedButton<AnalysisMode>(
                segments: const [
                  ButtonSegment(
                    value: AnalysisMode.student,
                    label: Text('By Student'),
                    icon: Icon(Icons.person_pin_rounded),
                  ),
                  ButtonSegment(
                    value: AnalysisMode.school,
                    label: Text('By School'),
                    icon: Icon(Icons.apartment_rounded),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _onModeChanged,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.green.shade700,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Searchable selector
              if (_mode == AnalysisMode.student)
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
                  onSelected: (s) => setState(() => _selectedStudentId = s.id),
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
                        labelText: 'Search for a student...',
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
                  onSelected: (name) =>
                      setState(() => _selectedSchool = name),
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
                        labelText: 'Search for a school...',
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

              const SizedBox(height: 24),

              // Detail section
              if (_mode == AnalysisMode.student && _selectedStudentId != null)
                _StudentAnalysis(studentId: _selectedStudentId!)
              else if (_mode == AnalysisMode.school && _selectedSchool != null)
                _SchoolAnalysis(schoolName: _selectedSchool!)
              else
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
                        Icon(Icons.bar_chart_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _mode == AnalysisMode.student
                              ? 'Select a student to see their performance analysis'
                              : 'Select a school to see its overall average analytics',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(thickness: 1.2),
              const SizedBox(height: 16),

              // Leaderboards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Top Performing Students',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Leaderboard(
                          entries: rankedStudents
                              .take(5)
                              .map((e) => _LeaderboardItem(
                            title: e.key.name,
                            subtitle: e.key.schoolName,
                            value: e.value,
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.indigo, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Top Performing Schools',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Leaderboard(
                          entries: rankedSchools
                              .map((e) => _LeaderboardItem(
                            title: e.key,
                            subtitle: null,
                            value: e.value,
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Redesigned widgets
/// ---------------------------------------------------------------------

class _TopPerformerBanner extends StatelessWidget {
  const _TopPerformerBanner({
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color startColor;
  final Color endColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.87)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final Color valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border(left: BorderSide(color: valueColor, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 13 : 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBadgeCard extends StatelessWidget {
  const _PerformanceBadgeCard({required this.band});

  final ({String label, Color color}) band;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: band.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: band.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Band',
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 16, color: band.color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  band.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: band.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentAnalysis extends StatelessWidget {
  const _StudentAnalysis({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final student = kStudents.firstWhere((s) => s.id == studentId);
    final records = _resultsFor(studentId);
    final isUniversity = student.schoolType == SchoolType.university;
    final avgMarks = _averageMarks(records);
    final avgGpa = _averageGpa(records);
    final avgPoints = _averagePoints(records);
    final band = performanceBand(avgMarks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Average Marks',
              value: '${avgMarks.toStringAsFixed(1)}%',
              color: Colors.green.shade50.withOpacity(0.5),
              valueColor: Colors.green.shade800,
            ),
            _MetricCard(
              label: isUniversity ? 'Average GPA' : 'Average Points',
              value: isUniversity
                  ? (avgGpa ?? 0).toStringAsFixed(2)
                  : (avgPoints ?? 0).toStringAsFixed(1),
              color: Colors.blue.shade50.withOpacity(0.5),
              valueColor: Colors.blue.shade800,
            ),
            _MetricCard(
              label: 'Subjects Recorded',
              value: '${records.length}',
              color: Colors.orange.shade50.withOpacity(0.5),
              valueColor: Colors.orange.shade800,
            ),
            _PerformanceBadgeCard(band: band),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Marks by ${isUniversity ? 'Course' : 'Subject'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        _BarChart(
          bars: records
              .map((r) => _BarDatum(label: r.subject, value: r.marks))
              .toList(),
          maxValue: 100,
          color: Colors.green.shade600,
        ),
      ],
    );
  }
}

class _SchoolAnalysis extends StatelessWidget {
  const _SchoolAnalysis({required this.schoolName});

  final String schoolName;

  @override
  Widget build(BuildContext context) {
    final students =
    kStudents.where((s) => s.schoolName == schoolName).toList();
    final studentIds = students.map((s) => s.id).toSet();
    final records =
    kResults.where((r) => studentIds.contains(r.studentId)).toList();
    final avgMarks = _averageMarks(records);
    final band = performanceBand(avgMarks);

    final perStudentAverages = students
        .map((s) => MapEntry(s, _averageMarks(_resultsFor(s.id))))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topStudent =
    perStudentAverages.isNotEmpty ? perStudentAverages.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'School Average Marks',
              value: '${avgMarks.toStringAsFixed(1)}%',
              color: Colors.green.shade50.withOpacity(0.5),
              valueColor: Colors.green.shade800,
            ),
            _MetricCard(
              label: 'Students Registered',
              value: '${students.length}',
              color: Colors.blue.shade50.withOpacity(0.5),
              valueColor: Colors.blue.shade800,
            ),
            _MetricCard(
              label: 'Top Student',
              value: topStudent == null
                  ? '—'
                  : '${topStudent.key.name} (${topStudent.value.toStringAsFixed(1)}%)',
              color: Colors.amber.shade50.withOpacity(0.5),
              valueColor: Colors.amber.shade900,
              compact: true,
            ),
            _PerformanceBadgeCard(band: band),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Average Marks by Student',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        _BarChart(
          bars: perStudentAverages
              .map((e) => _BarDatum(label: e.key.name, value: e.value))
              .toList(),
          maxValue: 100,
          color: Colors.indigo.shade600,
        ),
      ],
    );
  }
}

class _BarDatum {
  final String label;
  final double value;
  const _BarDatum({required this.label, required this.value});
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.bars,
    required this.maxValue,
    required this.color,
  });

  final List<_BarDatum> bars;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('No academic data available',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    const chartHeight = 250.0;
    const barMaxHeight = 130.0;

    return Container(
      height: chartHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Dark background for beautiful chart look
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((bar) {
            final barHeight =
                (bar.value / maxValue).clamp(0.0, 1.0) * barMaxHeight;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${bar.value.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, height: 1.0, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: barHeight < 6 ? 6 : barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 72,
                    height: 32,
                    child: Text(
                      bar.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, height: 1.1, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LeaderboardItem {
  final String title;
  final String? subtitle;
  final double value;
  const _LeaderboardItem({required this.title, this.subtitle, required this.value});
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.entries});

  final List<_LeaderboardItem> entries;

  static const _medalColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('No results recorded yet',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isMedal = index < 3;
          final band = performanceBand(entry.value);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: isMedal ? _medalColors[index].withOpacity(0.2) : Colors.grey.shade200,
              child: isMedal
                  ? Icon(Icons.emoji_events_rounded, color: _medalColors[index], size: 20)
                  : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
            title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: entry.subtitle == null
                ? null
                : Text(entry.subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: band.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: band.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}