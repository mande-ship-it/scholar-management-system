import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

class PromoteScholarsComponent extends StatefulWidget {
  const PromoteScholarsComponent({super.key});

  @override
  State<PromoteScholarsComponent> createState() => _PromoteScholarsComponentState();
}

class _PromoteScholarsComponentState extends State<PromoteScholarsComponent> {
  String _selectedSchool = 'All Schools';
  String _selectedYear = '2026';
  bool _isLoading = false;

  List<String> get _schoolOptions => ['All Schools', ...kStudents.map((s) => s.schoolName).toSet().toList()..sort()];
  List<String> get _yearOptions => kResults.map((r) => r.year).toSet().toList()..sort((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _fetchScholars();
  }

  Future<void> _fetchScholars() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllScholars();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          kStudents.clear();
          for (var item in data) {
            kStudents.add(Student(
              id: item['id'].toString(),
              scholarId: item['scholar_id']?.toString() ?? 'N/A',
              name: item['full_name'] ?? 'N/A',
              age: 16,
              schoolType: item['school_type'] == 'University' ? SchoolType.university : SchoolType.secondary,
              schoolName: item['display_school_name'] ?? 'N/A',
              currentClass: item['academic_year'] ?? 'N/A',
              status: item['status'] ?? 'Active',
              district: item['district'] ?? 'N/A',
              village: item['village'] ?? 'N/A',
              donor: item['donor'] ?? 'N/A',
              phone: item['phone'] ?? 'N/A',
              email: item['email'] ?? 'N/A',
              sex: item['sex'] ?? 'Female',
              dob: item['dob'] ?? '',
              programType: item['program_type'] ?? '',
              startYear: item['start_year']?.toString() ?? '2026',
              endYear: item['end_year']?.toString() ?? '2030',
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _promoteStudent(Student student) async {
    final current = student.currentClass;
    String nextClass = current;
    
    if (student.schoolType == SchoolType.secondary) {
      if (current.startsWith('Form ')) {
        final formNum = int.tryParse(current.replaceFirst('Form ', ''));
        if (formNum != null) nextClass = 'Form ${formNum + 1}';
      } else {
        nextClass = 'Form 1';
      }
    } else {
      if (current.startsWith('Year ')) {
        final yearNum = int.tryParse(current.replaceFirst('Year ', ''));
        if (yearNum != null) nextClass = 'Year ${yearNum + 1}';
      } else {
        nextClass = 'Year 1';
      }
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.promoteScholar(student.id, nextClass);
      if (response.statusCode == 200) {
        // Optimization: Update local state instead of full refetch
        setState(() {
          final index = kStudents.indexWhere((s) => s.id == student.id);
          if (index != -1) {
            kStudents[index] = kStudents[index].copyWith(currentClass: nextClass);
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Promoted ${student.name} from $current to $nextClass."),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _promoteAllFiltered(List<Student> filtered) async {
    if (filtered.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bulk Promotion"),
        content: Text("Are you sure you want to promote all ${filtered.length} scholars in the current view?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
            child: const Text("Promote All"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    int successCount = 0;

    // In a real high-volume system, we would use a single bulk API endpoint.
    // Since the backend doesn't have one yet, we'll iterate with a small delay or in parallel.
    // For now, we'll do it sequentially but update UI at the end.

    for (final student in filtered) {
      final current = student.currentClass;
      String nextClass = current;

      if (student.schoolType == SchoolType.secondary) {
        if (current.startsWith('Form ')) {
          final formNum = int.tryParse(current.replaceFirst('Form ', ''));
          if (formNum != null) nextClass = 'Form ${formNum + 1}';
        } else {
          nextClass = 'Form 1';
        }
      } else {
        if (current.startsWith('Year ')) {
          final yearNum = int.tryParse(current.replaceFirst('Year ', ''));
          if (yearNum != null) nextClass = 'Year ${yearNum + 1}';
        } else {
          nextClass = 'Year 1';
        }
      }

      try {
        final response = await ApiService.promoteScholar(student.id, nextClass);
        if (response.statusCode == 200) {
          successCount++;
          final index = kStudents.indexWhere((s) => s.id == student.id);
          if (index != -1) {
            kStudents[index] = kStudents[index].copyWith(currentClass: nextClass);
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully promoted $successCount scholars."),
          backgroundColor: kBrandOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final filteredStudents = kStudents.where((s) {
      final matchesSchool = _selectedSchool == 'All Schools' || s.schoolName == _selectedSchool;
      return matchesSchool;
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isSmallScreen ? BorderRadius.zero : BorderRadius.circular(16),
        border: isSmallScreen ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isSmallScreen ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header ----------------
            Padding(
              padding: EdgeInsets.fromLTRB(24, isSmallScreen ? 16 : 12, 24, 8),
              child: isMobile 
                ? Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.auto_graph_rounded, color: kBrandOlive, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Progression', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                                Text('Promote scholars.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filteredStudents.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _promoteAllFiltered(filteredStudents),
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: const Text("PROMOTE ALL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBrandOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.auto_graph_rounded, color: kBrandOlive, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scholar Progression', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                            SizedBox(height: 1),
                            Text('Update and promote scholars to the next form or academic year.',
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (filteredStudents.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _promoteAllFiltered(filteredStudents),
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text("PROMOTE ALL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
            ),
            const Divider(indent: 24, endIndent: 24),

            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Filter Bar ---
                  if (isMobile)
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSchool,
                          decoration: _inputDeco("Filter by School", Icons.school_outlined),
                          items: _schoolOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedSchool = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedYear,
                          decoration: _inputDeco("Result Year", Icons.calendar_month),
                          items: _yearOptions.isEmpty 
                            ? [const DropdownMenuItem(value: '2026', child: Text('2026'))]
                            : _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSchool,
                            decoration: _inputDeco("Filter by School", Icons.school_outlined),
                            items: _schoolOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _selectedSchool = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedYear,
                            decoration: _inputDeco("Result Year", Icons.calendar_month),
                            items: _yearOptions.isEmpty 
                              ? [const DropdownMenuItem(value: '2026', child: Text('2026'))]
                              : _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (v) => setState(() => _selectedYear = v!),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  const Text("Review & Promote Scholars", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => isSmallScreen ? const SizedBox.shrink() : const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = filteredStudents[index];
                      const passed = true;

                      if (isSmallScreen) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: kBrandCream,
                                child: Text(s.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBrandBrown)),
                                    Text("${s.schoolName} (${s.currentClass})", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: passed ? () => _promoteStudent(s) : null,
                                icon: Icon(Icons.upgrade_rounded, color: passed ? kBrandOlive : Colors.grey),
                                tooltip: "Promote Scholar",
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: kBrandCream,
                              child: Text(s.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBrandBrown)),
                                  Text("${s.schoolName} (${s.currentClass})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: passed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    passed ? "PASSED" : "PENDING/FAIL",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: passed ? Colors.green : Colors.orange),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(s.schoolType == SchoolType.university ? "Ready for Year Upgrade" : "Ready for Form Upgrade", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: passed ? () => _promoteStudent(s) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBrandOlive,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade200,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Promote"),
                            ),
                          ],
                        ),
                      );
                    },
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
