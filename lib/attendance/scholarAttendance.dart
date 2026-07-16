import 'package:flutter/material.dart';

// ============================================================
// MODELS
// ============================================================

enum SchoolType { secondary, university }

enum AttendanceType { chats, studyCircle }

extension AttendanceTypeLabel on AttendanceType {
  String get label => this == AttendanceType.chats ? 'CHATs' : 'Study Circle';
  IconData get icon => this == AttendanceType.chats ? Icons.forum_rounded : Icons.groups_rounded;
}

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusData on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.late: return 'Late';
      case AttendanceStatus.excused: return 'Excused';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present: return Icons.check_circle_rounded;
      case AttendanceStatus.absent: return Icons.cancel_rounded;
      case AttendanceStatus.late: return Icons.schedule_rounded;
      case AttendanceStatus.excused: return Icons.event_busy_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present: return const Color(0xFF2E7D32);
      case AttendanceStatus.absent: return const Color(0xFFC62828);
      case AttendanceStatus.late: return const Color(0xFFE65100);
      case AttendanceStatus.excused: return const Color(0xFF455A64);
    }
  }
}

class Scholar {
  final String id;
  final String scholarNumber;
  final String name;
  final SchoolType schoolType;
  final String schoolName;
  final String programOrGrade;

  const Scholar({
    required this.id,
    required this.scholarNumber,
    required this.name,
    required this.schoolType,
    required this.schoolName,
    required this.programOrGrade,
  });
}

class AttendanceEntry {
  final Scholar scholar;
  AttendanceStatus status;
  String note;

  AttendanceEntry({
    required this.scholar,
    this.status = AttendanceStatus.present,
    this.note = '',
  });
}

// ============================================================
// SHARED BRAND COLORS
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class ScholarAttendanceComponent extends StatefulWidget {
  const ScholarAttendanceComponent({super.key});

  @override
  State<ScholarAttendanceComponent> createState() => _ScholarAttendanceComponentState();
}

class _ScholarAttendanceComponentState extends State<ScholarAttendanceComponent> {
  AttendanceType _attendanceType = AttendanceType.chats;
  SchoolType _schoolType = SchoolType.secondary;
  String? _selectedSchool;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _facilitatorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  List<AttendanceEntry> _entries = [];
  bool _isSaving = false;

  final List<Scholar> _allScholars = [
    const Scholar(id: 's1', scholarNumber: 'AGE-24-001', name: 'Chisomo Banda', schoolType: SchoolType.secondary, schoolName: 'Kamuzu Academy', programOrGrade: 'Form 3'),
    const Scholar(id: 's2', scholarNumber: 'AGE-24-002', name: 'Thandiwe Phiri', schoolType: SchoolType.university, schoolName: 'University of Malawi', programOrGrade: 'BSc CS Year 2'),
    const Scholar(id: 's3', scholarNumber: 'AGE-24-003', name: 'Takondwa Mwale', schoolType: SchoolType.secondary, schoolName: 'Chichiri Secondary', programOrGrade: 'Form 4'),
  ];

  List<String> get _schoolOptions => _allScholars
      .where((s) => s.schoolType == _schoolType)
      .map((s) => s.schoolName)
      .toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _facilitatorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadRegister() {
    if (_selectedSchool == null) return;
    setState(() {
      _entries = _allScholars
          .where((s) => s.schoolType == _schoolType && s.schoolName == _selectedSchool)
          .map((s) => AttendanceEntry(scholar: s))
          .toList();
    });
  }

  void _saveRegister() async {
    if (_entries.isEmpty) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate save
    if (mounted) {
      setState(() => _isSaving = false);
      final facilitator = _facilitatorController.text.isNotEmpty ? " by ${_facilitatorController.text}" : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance for ${_attendanceType.label} session$facilitator saved successfully.'),
          backgroundColor: kBrandOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                  child: Icon(_attendanceType.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attendance Register', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('Recording attendance for ${_attendanceType.label} sessions.',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<AttendanceType>(
                        segments: AttendanceType.values.map((t) => ButtonSegment(
                          value: t, label: Text(t.label), icon: Icon(t.icon),
                        )).toList(),
                        selected: {_attendanceType},
                        onSelectionChanged: (s) => setState(() {
                          _attendanceType = s.first;
                          _loadRegister();
                        }),
                        style: SegmentedButton.styleFrom(selectedBackgroundColor: kBrandOlive, selectedForegroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filters Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<SchoolType>(
                          initialValue: _schoolType,
                          decoration: _inputDeco("Level", Icons.category_outlined),
                          items: const [
                            DropdownMenuItem(value: SchoolType.secondary, child: Text("Secondary")),
                            DropdownMenuItem(value: SchoolType.university, child: Text("University")),
                          ],
                          onChanged: (v) => setState(() {
                            _schoolType = v!;
                            _selectedSchool = null;
                            _entries = [];
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSchool,
                          isExpanded: true,
                          decoration: _inputDeco("Select School", Icons.apartment_rounded),
                          items: _schoolOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedSchool = v;
                            _loadRegister();
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: InputDecorator(
                            decoration: _inputDeco("Date", Icons.calendar_today_rounded),
                            child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_entries.isEmpty)
                  _PlaceholderView(text: _selectedSchool == null ? "Select a school to load the register." : "No scholars found for this selection.")
                else ...[
                  // Session Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: kBrandOrange, size: 18),
                            const SizedBox(width: 8),
                            Text("Session Details (${_attendanceType.label})", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _facilitatorController,
                                decoration: _inputDeco("Facilitator Name", Icons.person_outline),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _locationController,
                                decoration: _inputDeco("Location / Venue", Icons.location_on_outlined),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mark All Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_entries.length} Scholars Found", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                      TextButton.icon(
                        onPressed: () => setState(() { for (var e in _entries) e.status = AttendanceStatus.present; }),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text("Mark All Present"),
                        style: TextButton.styleFrom(foregroundColor: kBrandOlive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Register List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return _AttendanceScholarCard(entry: entry);
                    },
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRegister,
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? "Saving..." : "Save Attendance Register", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: kBrandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
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
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }
}

class _AttendanceScholarCard extends StatefulWidget {
  const _AttendanceScholarCard({required this.entry});
  final AttendanceEntry entry;

  @override
  State<_AttendanceScholarCard> createState() => _AttendanceScholarCardState();
}

class _AttendanceScholarCardState extends State<_AttendanceScholarCard> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: kBrandCream, child: Text(entry.scholar.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.scholar.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("${entry.scholar.scholarNumber} • ${entry.scholar.programOrGrade}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: AttendanceStatus.values.map((status) {
              final isSelected = entry.status == status;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => entry.status = status),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? status.color.withValues(alpha: 0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? status.color : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(status.icon, size: 18, color: isSelected ? status.color : Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(status.label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? status.color : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
      child: Column(
        children: [
          Icon(Icons.event_note_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
