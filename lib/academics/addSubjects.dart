import 'package:flutter/material.dart';
import 'academicsUtils.dart';

class AddSubjectsComponent extends StatefulWidget {
  const AddSubjectsComponent({super.key});

  @override
  State<AddSubjectsComponent> createState() => _AddSubjectsComponentState();
}

class _AddSubjectsComponentState extends State<AddSubjectsComponent> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Level selected in the "Add Subject" form
  SubjectLevel _formLevel = SubjectLevel.secondary;

  // Filter applied to the registry list below (null = show all)
  SubjectLevel? _filterLevel;

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addSubject() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        final subjectName = _nameController.text.trim();
        kSubjects.add({
          'name': subjectName,
          'details': _detailsController.text.trim(),
          'notes': _notesController.text.trim(),
          'level': _formLevel,
          'code': subjectName.length >= 4 
              ? subjectName.substring(0, 4).toUpperCase() + '101'
              : 'SUBJ101',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Subject '${_nameController.text}' added successfully for ${_formLevel.label}!",
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      _nameController.clear();
      _detailsController.clear();
      _notesController.clear();
      // Note: _formLevel intentionally NOT reset, so entering several
      // subjects for the same level in a row doesn't require re-selecting.
    }
  }

  void _deleteSubject(int index) {
    final deleted = kSubjects[index];
    setState(() {
      kSubjects.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Subject '${deleted['name']}' deleted."),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              kSubjects.insert(index, deleted);
            });
          },
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  List<Map<String, dynamic>> get _visibleSubjects {
    if (_filterLevel == null) return kSubjects;
    return kSubjects.where((s) => s['level'] == _filterLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 850;

        final Widget formWidget = Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add_task_rounded, color: Colors.green.shade700, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Add New Subject",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1.2),

                  // Level selector — required, drives which registry tab this subject lands in
                  Text(
                    "Subject Level",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<SubjectLevel>(
                    segments: const [
                      ButtonSegment(
                        value: SubjectLevel.secondary,
                        label: Text('Secondary'),
                        icon: Icon(Icons.school_outlined),
                      ),
                      ButtonSegment(
                        value: SubjectLevel.university,
                        label: Text('University'),
                        icon: Icon(Icons.apartment_outlined),
                      ),
                    ],
                    selected: {_formLevel},
                    onSelectionChanged: (selection) {
                      setState(() => _formLevel = selection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.green.shade700,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Subject Name / Title",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.edit_note_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? "Please enter a subject name" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Details / Description",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.description_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? "Please enter details" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: "Additional Notes",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.info_outline_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addSubject,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      "Save Subject Record",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final Widget listWidget = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.library_books_rounded, color: Colors.blue.shade700, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Subjects Registry",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "${_visibleSubjects.length} Subjects Active",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Level filter chips for the registry
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filterLevel == null,
                      onSelected: (_) => setState(() => _filterLevel = null),
                      selectedColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                        color: _filterLevel == null ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Secondary'),
                      selected: _filterLevel == SubjectLevel.secondary,
                      onSelected: (_) => setState(() => _filterLevel = SubjectLevel.secondary),
                      selectedColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                        color: _filterLevel == SubjectLevel.secondary ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('University'),
                      selected: _filterLevel == SubjectLevel.university,
                      onSelected: (_) => setState(() => _filterLevel = SubjectLevel.university),
                      selectedColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                        color: _filterLevel == SubjectLevel.university ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24, thickness: 1.2),
                if (_visibleSubjects.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.library_books, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "No subjects registered yet.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _visibleSubjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sub = _visibleSubjects[index];
                      // Find the real index in the underlying list so delete/undo
                      // operate on the correct item even while filtered.
                      final realIndex = kSubjects.indexOf(sub);
                      final level = sub['level'] as SubjectLevel;
                      final levelColor = level == SubjectLevel.secondary
                          ? Colors.green.shade700
                          : Colors.indigo.shade700;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              foregroundColor: Colors.green.shade800,
                              child: Text((sub['name'] as String)[0].toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          sub['name'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: levelColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          level.label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: levelColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sub['details'] as String,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  if ((sub['notes'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sub['notes'] as String,
                                        style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteSubject(realIndex),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: formWidget),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: listWidget),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              formWidget,
              const SizedBox(height: 16),
              listWidget,
            ],
          );
        }
      },
    );
  }
}