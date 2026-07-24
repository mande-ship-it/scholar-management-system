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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getScholarsForPromotion(
        schoolName: _selectedSchool == 'All Schools' ? null : _selectedSchool,
        year: _selectedYear,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _promotionScholars = data.map((item) => {
            'id': item['id'].toString(),
            'name': item['full_name'],
            'schoolName': item['school_name'] ?? item['display_school_name'] ?? 'N/A',
            'currentClass': item['academic_year'] ?? 'N/A',
            'schoolType': item['school_type'],
            'passed': item['passed'] == true,
            'average': item['average_marks'].toString(),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching scholars for promotion: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _promotionScholars = [];

  List<String> get _schoolOptions => ['All Schools', ...kStudents.map((s) => s.schoolName).toSet().toList()..sort()];
  List<String> get _yearOptions => ['2023', '2024', '2025', '2026'];

  void _promoteStudent(Map<String, dynamic> scholar) async {
    try {
      final response = await ApiService.promoteScholarViaSchool(scholar['id']!);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Promoted ${scholar['name']} from ${data['previous_class']} to ${data['new_class']}."),
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _refreshData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to promote scholar."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
          ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: kBrandOlive)))
          : SingleChildScrollView(
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
                    child: const Icon(Icons.auto_graph_rounded, color: kBrandOlive, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scholar Progression', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        const SizedBox(height: 2),
                        Text('Update and promote scholars to the next form or academic year.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshData,
                  )
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Filter Bar ---
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSchool,
                          decoration: _inputDeco("Filter by School", Icons.school_outlined),
                          items: _schoolOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedSchool = v!;
                            _refreshData();
                          }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedYear,
                          decoration: _inputDeco("Result Year", Icons.calendar_month),
                          items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedYear = v!;
                            _refreshData();
                          }),
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
                    itemCount: _promotionScholars.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = _promotionScholars[index];
                      final passed = s['passed'] == true;
                      final isUni = s['schoolType'] == 'University';

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
                              child: Text(s['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBrandBrown)),
                                  Text("${s['schoolName']} (${s['currentClass']})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: passed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    passed ? "PASSED (${s['average']}%)" : "PENDING/FAIL (${s['average']}%)",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: passed ? Colors.green : Colors.orange),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(isUni ? "Ready for Year Upgrade" : "Ready for Form Upgrade", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
