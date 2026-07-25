import 'package:flutter/material.dart';
import 'scholar_attendance.dart';
import '../services/api_service.dart';

class AttendanceHistoryComponent extends StatefulWidget {
  const AttendanceHistoryComponent({super.key});

  @override
  State<AttendanceHistoryComponent> createState() => _AttendanceHistoryComponentState();
}

class _AttendanceHistoryComponentState extends State<AttendanceHistoryComponent> {
  String? _filterSchool;
  AttendanceType? _filterType;
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAttendanceHistory(
        type: _filterType?.label,
        schoolName: _filterSchool,
      );
      if (response.statusCode == 200) {
        setState(() {
          _history = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header (Banner Removed) ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBrandBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance History',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown)),
                        const SizedBox(height: 4),
                        Text('Review past CHATs and Study Circle attendance logs.',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchHistory,
                    icon: const Icon(Icons.refresh),
                    tooltip: "Refresh History",
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AttendanceType>(
                        initialValue: _filterType,
                        decoration: _inputDeco("Session Type", Icons.forum_rounded),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All Sessions")),
                          ...AttendanceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                        ],
                        onChanged: (v) {
                          setState(() => _filterType = v);
                          _fetchHistory();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: _inputDeco("Search School", Icons.search_rounded),
                        onChanged: (v) {
                          setState(() => _filterSchool = v.isEmpty ? null : v);
                          _fetchHistory();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kBrandOlive)))
                else if (_history.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final typeLabel = item['type'] ?? 'CHATs';
                      final type = typeLabel == 'CHATs' ? AttendanceType.chats : AttendanceType.studyCircle;

                      final String dateStr = item['session_date'] != null
                          ? item['session_date'].toString().split('T')[0]
                          : 'N/A';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(type.icon, color: kBrandOlive, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                                child: Text(type.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(item['display_school_name'] ?? item['school_name'] ?? 'N/A', style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text("Facilitator: ${item['facilitator'] ?? 'N/A'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${item['present_count'] ?? 0}/${item['total_count'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive, fontSize: 16)),
                              const Text("Present", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No attendance history found for this selection.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
    );
  }
}
