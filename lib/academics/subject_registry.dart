import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'academics_utils.dart';

class SubjectRegistryPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SubjectRegistryPage({super.key, this.onBack});

  @override
  State<SubjectRegistryPage> createState() => _SubjectRegistryPageState();
}

class _SubjectRegistryPageState extends State<SubjectRegistryPage> {
  List<dynamic> _subjects = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String _selectedLevel = 'Secondary';

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getSubjectRegistry();
      if (res.statusCode == 200) {
        setState(() {
          _subjects = res.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSubject() async {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Code are required")),
      );
      return;
    }

    try {
      final res = await ApiService.createSubject({
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'level': _selectedLevel,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        _nameController.clear();
        _codeController.clear();
        _fetchSubjects();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['message'] ?? "Failed to add subject")),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding subject: $e');
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Register New Subject", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Subject Name (e.g. Mathematics)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: "Subject Code (e.g. MAT001)"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              items: const [
                DropdownMenuItem(value: 'Secondary', child: Text("Secondary")),
                DropdownMenuItem(value: 'University', child: Text("University")),
              ],
              onChanged: (v) => setState(() => _selectedLevel = v!),
              decoration: const InputDecoration(labelText: "Institutional Level"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _addSubject,
            style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.library_books_rounded, color: kBrandOlive, size: 24),
                  const SizedBox(width: 12),
                  const Text("Subject Registry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBrandBrown)),
                  const Spacer(),
                  if (widget.onBack != null)
                    IconButton(onPressed: widget.onBack, icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("REGISTER NEW SUBJECT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          )
        : Row(
            children: [
              if (widget.onBack != null)
                IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const Icon(Icons.library_books_rounded, color: kBrandOlive, size: 28),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Subject Registry", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
                    Text("Manage core curriculum subjects for all institutional levels.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text("ADD SUBJECT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildList() {
    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text("No subjects registered yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final secondary = _subjects.where((s) => s['level'] == 'Secondary').toList();
    final university = _subjects.where((s) => s['level'] == 'University').toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (secondary.isNotEmpty) ...[
          _sectionTitle("Secondary School Subjects"),
          const SizedBox(height: 12),
          _buildGrid(secondary),
          const SizedBox(height: 32),
        ],
        if (university.isNotEmpty) ...[
          _sectionTitle("University / Tertiary Courses"),
          const SizedBox(height: 12),
          _buildGrid(university),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1.2));
  }

  Widget _buildGrid(List<dynamic> subs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 80,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final s = subs[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.menu_book_rounded, color: kBrandOlive, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(s['code'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteSubject(s['_id']),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSubject(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Subject"),
        content: const Text("Are you sure? This may affect existing academic records."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.dio.delete('/academic/subjects/$id');
        if (res.statusCode == 200) {
          _fetchSubjects();
        }
      } catch (e) {
        debugPrint('Delete error: $e');
      }
    }
  }
}
