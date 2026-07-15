import 'package:flutter/material.dart';

enum AttendanceStatus { present, absent, late }

class ScholarAttendance {
  final String id;
  final String name;
  final String studyCircle;
  AttendanceStatus status;

  ScholarAttendance({
    required this.id,
    required this.name,
    required this.studyCircle,
    this.status = AttendanceStatus.present,
  });
}

class TakeAttendanceComponent extends StatefulWidget {
  const TakeAttendanceComponent({super.key});

  @override
  State<TakeAttendanceComponent> createState() =>
      _TakeAttendanceComponentState();
}

class _TakeAttendanceComponentState extends State<TakeAttendanceComponent> {
  DateTime _selectedDate = DateTime.now();
  String _selectedCircle = 'All Circles';

  // Replace this with data pulled from your scholars/study circle source.
  final List<ScholarAttendance> _scholars = [
    ScholarAttendance(id: '1', name: 'Chikondi Banda', studyCircle: 'Circle A'),
    ScholarAttendance(id: '2', name: 'Thandiwe Phiri', studyCircle: 'Circle A'),
    ScholarAttendance(id: '3', name: 'Wongani Mvula', studyCircle: 'Circle B'),
    ScholarAttendance(id: '4', name: 'Zione Kamanga', studyCircle: 'Circle B'),
    ScholarAttendance(id: '5', name: 'Mphatso Nyirenda', studyCircle: 'Circle C'),
  ];

  List<String> get _circles {
    final set = _scholars.map((s) => s.studyCircle).toSet().toList()..sort();
    return ['All Circles', ...set];
  }

  List<ScholarAttendance> get _filteredScholars {
    if (_selectedCircle == 'All Circles') return _scholars;
    return _scholars.where((s) => s.studyCircle == _selectedCircle).toList();
  }

  int get _presentCount =>
      _filteredScholars.where((s) => s.status == AttendanceStatus.present).length;
  int get _absentCount =>
      _filteredScholars.where((s) => s.status == AttendanceStatus.absent).length;
  int get _lateCount =>
      _filteredScholars.where((s) => s.status == AttendanceStatus.late).length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _markAllPresent() {
    setState(() {
      for (final s in _filteredScholars) {
        s.status = AttendanceStatus.present;
      }
    });
  }

  void _setStatus(ScholarAttendance scholar, AttendanceStatus status) {
    setState(() => scholar.status = status);
  }

  void _saveAttendance() {
    // TODO: wire this up to your backend / local database.
    final records = _filteredScholars
        .map((s) => {
      'scholarId': s.id,
      'name': s.name,
      'studyCircle': s.studyCircle,
      'status': s.status.name,
      'date': _selectedDate.toIso8601String(),
    })
        .toList();

    debugPrint('Saving attendance: $records');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance saved for ${_filteredScholars.length} scholar(s) — '
              '$_presentCount present, $_absentCount absent, $_lateCount late.',
        ),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Take Attendance",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Mark attendance for scholars by study circle.",
              style: TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCircle,
                    decoration: const InputDecoration(
                      labelText: 'Study Circle',
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _circles
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedCircle = value);
                    },
                  ),
                ),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(_formatDate(_selectedDate)),
                      ],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _markAllPresent,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark All Present'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                      label: 'Present',
                      value: _presentCount.toString(),
                      color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                      label: 'Absent',
                      value: _absentCount.toString(),
                      color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                      label: 'Late',
                      value: _lateCount.toString(),
                      color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _filteredScholars.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('No scholars found.')),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredScholars.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final scholar = _filteredScholars[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(scholar.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                scholar.studyCircle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _StatusToggle(
                            status: scholar.status,
                            onChanged: (status) =>
                                _setStatus(scholar, status),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _filteredScholars.isEmpty ? null : _saveAttendance,
                icon: const Icon(Icons.save),
                label: const Text('Save Attendance'),
                style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  const _StatusToggle({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AttendanceStatus>(
      segments: const [
        ButtonSegment(
          value: AttendanceStatus.present,
          label: Text('Present'),
          icon: Icon(Icons.check_circle_outline, size: 16),
        ),
        ButtonSegment(
          value: AttendanceStatus.late,
          label: Text('Late'),
          icon: Icon(Icons.access_time, size: 16),
        ),
        ButtonSegment(
          value: AttendanceStatus.absent,
          label: Text('Absent'),
          icon: Icon(Icons.cancel_outlined, size: 16),
        ),
      ],
      selected: {status},
      onSelectionChanged: (Set<AttendanceStatus> selected) =>
          onChanged(selected.first),
      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}