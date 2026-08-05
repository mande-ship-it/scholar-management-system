import 'package:flutter/material.dart';
import 'scholar_attendance.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class AttendanceHistoryComponent extends StatefulWidget {
  const AttendanceHistoryComponent({super.key});

  @override
  State<AttendanceHistoryComponent> createState() => _AttendanceHistoryComponentState();
}

class _AttendanceHistoryComponentState extends State<AttendanceHistoryComponent> {
  String? _filterSchool;
  AttendanceModuleType? _filterType;
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
        if (mounted) {
          setState(() {
            _history = response.data['data'] ?? [];
          });
        }
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
      height: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfessionalHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: kBrandOlive)))
                  else if (_history.isEmpty)
                    _buildEmptyState()
                  else
                    _buildHistoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kBrandBrown.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.history_edu_rounded, color: kBrandBrown, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Attendance Archives", 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.4)),
                Text("Historical audit of program engagement.",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildQuickActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: () => setState(() {
            _filterType = null;
            _filterSchool = null;
            _fetchHistory();
          }),
          icon: const Icon(Icons.refresh_rounded, color: kBrandBrown, size: 20),
          tooltip: "Reload Archives",
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _dropdownFilter("MODULE", _filterType, [
              const DropdownMenuItem(value: null, child: Text("All Modules")),
              ...AttendanceModuleType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
            ], (v) {
              setState(() => _filterType = v);
              _fetchHistory();
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _textFilter("INSTITUTION", Icons.search_rounded, "Search school...", (v) {
              setState(() => _filterSchool = v.isEmpty ? null : v);
              _fetchHistory();
            }),
          ),
        ],
      ),
    );
  }

  Widget _dropdownFilter(String label, dynamic value, List<DropdownMenuItem<AttendanceModuleType>> items, ValueChanged<AttendanceModuleType?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AttendanceModuleType>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textFilter(String label, IconData icon, String hint, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              icon: Icon(icon, size: 14, color: kBrandBrown.withOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("HISTORICAL LOGS (${_history.length})", 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
            Text("Ordered by most recent sessions.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _history[index];
            final typeLabel = item['type'] ?? 'CHATs';
            final moduleType = typeLabel == 'CHATs' ? AttendanceModuleType.chats : AttendanceModuleType.studyCircle;
            final String dateStr = item['session_date'] != null ? item['session_date'].toString().split('T')[0] : 'N/A';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(moduleType.icon, color: kBrandOlive, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['display_school_name'] ?? item['school_name'] ?? 'N/A', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kBrandBrown)),
                        const SizedBox(height: 2),
                        Text("Facilitator: ${item['facilitator'] ?? 'N/A'}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kBrandBrown)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(moduleType.label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${item['present_count'] ?? 0}/${item['total_count'] ?? 0}", 
                        style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 18)),
                      Text("RATE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          const Text("No attendance archives found.",
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
