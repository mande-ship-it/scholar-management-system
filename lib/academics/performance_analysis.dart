import 'package:flutter/material.dart';
import 'academics_utils.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

enum AnalysisMode { scholar, school }

class PerformanceAnalysisComponent extends StatefulWidget {
  const PerformanceAnalysisComponent({super.key});

  @override
  State<PerformanceAnalysisComponent> createState() => _PerformanceAnalysisComponentState();
}

class _PerformanceAnalysisComponentState extends State<PerformanceAnalysisComponent> {
  AnalysisMode _mode = AnalysisMode.scholar;
  String? _selectedStudentId;
  String? _selectedSchool;

  void _onModeChanged(Set<AnalysisMode> selection) {
    setState(() {
      _mode = selection.first;
      _selectedStudentId = null;
      _selectedSchool = null;
    });
  }

  List<String> get _schoolOptions {
    return kStudents.map((s) => s.schoolName).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final rankedStudents = _getRankedStudents();
    final rankedSchools = _getRankedSchools();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header (No Banners) ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.analytics_rounded, color: kBrandOlive, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Performance Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        SizedBox(height: 2),
                        Text('Detailed academic insights and student ranking statistics.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Quick Stats (Banners Removed) ----------------

                  // Mode Toggle
                  SegmentedButton<AnalysisMode>(
                    segments: const [
                      ButtonSegment(value: AnalysisMode.scholar, label: Text('Scholar Analysis'), icon: Icon(Icons.person_pin_rounded)),
                      ButtonSegment(value: AnalysisMode.school, label: Text('School Analysis'), icon: Icon(Icons.school_outlined)),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _onModeChanged,
                    style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandOlive, selectedForegroundColor: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Search Filters
                  if (_mode == AnalysisMode.scholar)
                    Autocomplete<Student>(
                      displayStringForOption: (s) => s.name,
                      optionsBuilder: (textValue) {
                        final query = textValue.text.trim().toLowerCase();
                        if (query.isEmpty) return kStudents;
                        return kStudents.where((s) => s.name.toLowerCase().contains(query) || s.schoolName.toLowerCase().contains(query));
                      },
                      onSelected: (s) => setState(() => _selectedStudentId = s.id),
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _inputDeco('Search for a scholar...', Icons.search_rounded).copyWith(
                            suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () {
                              controller.clear();
                              setState(() => _selectedStudentId = null);
                            }),
                          ),
                        );
                      },
                    )
                  else
                    Autocomplete<String>(
                      optionsBuilder: (textValue) {
                        final query = textValue.text.trim().toLowerCase();
                        if (query.isEmpty) return _schoolOptions;
                        return _schoolOptions.where((n) => n.toLowerCase().contains(query));
                      },
                      onSelected: (n) => setState(() => _selectedSchool = n),
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _inputDeco('Search for a school...', Icons.search_rounded).copyWith(
                            suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () {
                              controller.clear();
                              setState(() => _selectedSchool = null);
                            }),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Analysis Body
                  if (_mode == AnalysisMode.scholar && _selectedStudentId != null)
                    _ScholarDetailAnalysis(studentId: _selectedStudentId!)
                  else if (_mode == AnalysisMode.school && _selectedSchool != null)
                    _SchoolDetailAnalysis(schoolName: _selectedSchool!)
                  else
                    _PlaceholderView(text: _mode == AnalysisMode.scholar 
                        ? 'Select a scholar to view their progress and performance metrics.' 
                        : 'Select a school to compare overall academic statistics.'),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Leaderboards
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Leaderboard(
                          title: 'Top Performers (Scholars)',
                          icon: Icons.stars_rounded,
                          items: rankedStudents.take(5).map((e) => _LeaderItem(
                            title: e.student.name,
                            subtitle: e.student.schoolName,
                            average: e.average,
                          )).toList(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _Leaderboard(
                          title: 'School Rankings',
                          icon: Icons.trending_up_rounded,
                          items: rankedSchools.take(5).map((e) => _LeaderItem(
                            title: e.name,
                            subtitle: '${e.studentCount} Scholars',
                            average: e.average,
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }

  List<({Student student, double average})> _getRankedStudents() {
    return kStudents.map((s) {
      final records = kResults.where((r) => r.studentId == s.id).toList();
      final avg = records.isEmpty ? 0.0 : records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
      return (student: s, average: avg);
    }).where((e) => e.average > 0).toList()..sort((a, b) => b.average.compareTo(a.average));
  }

  List<({String name, double average, int studentCount})> _getRankedSchools() {
    final schoolNames = kStudents.map((s) => s.schoolName).toSet();
    return schoolNames.map((name) {
      final ids = kStudents.where((s) => s.schoolName == name).map((s) => s.id).toSet();
      final records = kResults.where((r) => ids.contains(r.studentId)).toList();
      final avg = records.isEmpty ? 0.0 : records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
      return (name: name, average: avg, studentCount: ids.length);
    }).where((e) => e.average > 0).toList()..sort((a, b) => b.average.compareTo(a.average));
  }
}

class _ScholarDetailAnalysis extends StatelessWidget {
  const _ScholarDetailAnalysis({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final student = kStudents.firstWhere((s) => s.id == studentId);
    final records = kResults.where((r) => r.studentId == studentId).toList();
    final isUni = student.schoolType == SchoolType.university;
    final avg = records.isEmpty ? 0.0 : records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
    final band = performanceBand(avg);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MetricCard(label: 'Average Score', value: '${avg.toStringAsFixed(1)}%', color: kBrandBrown),
            const SizedBox(width: 12),
            _MetricCard(label: isUni ? 'Total Courses' : 'Total Subjects', value: '${records.length}', color: kBrandOlive),
            const SizedBox(width: 12),
            _MetricCard(label: 'Current Status', value: band.label, color: band.color, isBadge: true),
          ],
        ),
        const SizedBox(height: 24),
        const Text("Score Distribution", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 12),
        _MiniChart(records: records),
      ],
    );
  }
}

class _SchoolDetailAnalysis extends StatelessWidget {
  const _SchoolDetailAnalysis({required this.schoolName});
  final String schoolName;

  @override
  Widget build(BuildContext context) {
    final ids = kStudents.where((s) => s.schoolName == schoolName).map((s) => s.id).toSet();
    final records = kResults.where((r) => ids.contains(r.studentId)).toList();
    final avg = records.isEmpty ? 0.0 : records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
    final band = performanceBand(avg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MetricCard(label: 'Overall Average', value: '${avg.toStringAsFixed(1)}%', color: kBrandBrown),
            const SizedBox(width: 12),
            _MetricCard(label: 'Total Scholars', value: '${ids.length}', color: kBrandOlive),
            const SizedBox(width: 12),
            _MetricCard(label: 'School Standing', value: band.label, color: band.color, isBadge: true),
          ],
        ),
        const SizedBox(height: 24),
        const Text("School Performance Distribution", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(height: 12),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Center(child: Text("Aggregated analytics for $schoolName", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))),
        )
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color, this.isBadge = false});
  final String label, value;
  final Color color;
  final bool isBadge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isBadge ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isBadge ? color.withValues(alpha: 0.3) : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.records});
  final List<ResultRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kBrandBrown, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: records.map((r) {
          final height = (r.marks / 100) * 80;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${r.marks.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kBrandOlive, kBrandOlive.withValues(alpha: 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(r.subject.length > 4 ? r.subject.substring(0, 4) : r.subject, 
                    style: const TextStyle(color: Colors.white70, fontSize: 8), overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.title, required this.icon, required this.items});
  final String title;
  final IconData icon;
  final List<_LeaderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 18, color: kBrandOrange), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBrandBrown))]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.isEmpty ? 1 : items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (items.isEmpty) return const ListTile(title: Text("No data recorded", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic), textAlign: TextAlign.center));
              final item = items[index];
              final band = performanceBand(item.average);
              return ListTile(
                dense: true,
                leading: CircleAvatar(backgroundColor: kBrandCream, child: Text("${index + 1}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandBrown))),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 11)),
                trailing: Text("${item.average.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.bold, color: band.color)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaderItem {
  final String title, subtitle;
  final double average;
  _LeaderItem({required this.title, required this.subtitle, required this.average});
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
      child: Center(child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      )),
    );
  }
}
