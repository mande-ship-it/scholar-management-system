import 'package:flutter/material.dart';
import 'scholarAttendance.dart';

class AttendanceHistoryComponent extends StatefulWidget {
  const AttendanceHistoryComponent({super.key});

  @override
  State<AttendanceHistoryComponent> createState() => _AttendanceHistoryComponentState();
}

class _AttendanceHistoryComponentState extends State<AttendanceHistoryComponent> {
  String? _filterSchool;
  AttendanceType? _filterType;

  final List<Map<String, dynamic>> _mockHistory = [
    {'date': '2026-07-09', 'type': AttendanceType.chats, 'school': 'Kamuzu Academy', 'present': 12, 'total': 15, 'facilitator': 'Dr. Banda'},
    {'date': '2026-07-08', 'type': AttendanceType.studyCircle, 'school': 'University of Malawi', 'present': 28, 'total': 30, 'facilitator': 'Prof. Phiri'},
    {'date': '2026-07-07', 'type': AttendanceType.chats, 'school': 'Kamuzu Academy', 'present': 14, 'total': 15, 'facilitator': 'Ms. Mwale'},
    {'date': '2026-07-06', 'type': AttendanceType.studyCircle, 'school': 'Chichiri Secondary', 'present': 10, 'total': 12, 'facilitator': 'Mr. Zulu'},
    {'date': '2026-07-05', 'type': AttendanceType.chats, 'school': 'University of Malawi', 'present': 25, 'total': 30, 'facilitator': 'Dr. Banda'},
  ];

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
          // ---------------- Gradient Header ----------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kBrandBrown, kBrandOlive]),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attendance History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 3),
                      Text('Review past CHATs and Study Circle attendance logs.',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
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
                        value: _filterType,
                        decoration: _inputDeco("Session Type", Icons.forum_rounded),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All Sessions")),
                          ...AttendanceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                        ],
                        onChanged: (v) => setState(() => _filterType = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: _inputDeco("Search School", Icons.search_rounded),
                        onChanged: (v) => setState(() => _filterSchool = v.isEmpty ? null : v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mockHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _mockHistory[index];
                    final type = item['type'] as AttendanceType;
                    
                    // Simple search filtering
                    if (_filterType != null && type != _filterType) return const SizedBox.shrink();
                    if (_filterSchool != null && !item['school'].toString().toLowerCase().contains(_filterSchool!.toLowerCase())) return const SizedBox.shrink();

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
                            Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            Text(item['school'], style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                            Text("Facilitator: ${item['facilitator']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${item['present']}/${item['total']}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive, fontSize: 16)),
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
