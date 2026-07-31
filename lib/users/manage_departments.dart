import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class ManageDepartmentsComponent extends StatefulWidget {
  const ManageDepartmentsComponent({super.key});

  @override
  State<ManageDepartmentsComponent> createState() => _ManageDepartmentsComponentState();
}

class _ManageDepartmentsComponentState extends State<ManageDepartmentsComponent> {
  List<dynamic> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllDepartmentsWithCounts();
      if (response.statusCode == 200) {
        setState(() {
          _departments = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeptDialog({Map<String, dynamic>? dept}) {
    final nameCtrl = TextEditingController(text: dept?['name'] ?? '');
    final codeCtrl = TextEditingController(text: dept?['code'] ?? '');
    final descCtrl = TextEditingController(text: dept?['description'] ?? '');
    final isEdit = dept != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Department" : "Create Department"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Department Name")),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code (e.g., FIN)")),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameCtrl.text.trim(),
                'code': codeCtrl.text.trim().toUpperCase(),
                'description': descCtrl.text.trim(),
              };

              try {
                final response = isEdit
                  ? await ApiService.updateDepartment(dept!['id'].toString(), data)
                  : await ApiService.createDepartment(data);

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(ctx);
                  _fetchDepartments();
                }
              } catch (e) {
                debugPrint('Error saving department: $e');
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Department"),
        content: Text("Are you sure you want to delete '$name'? This will affect users assigned to it."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final response = await ApiService.deleteDepartment(id);
                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  _fetchDepartments();
                }
              } catch (e) {
                debugPrint('Error deleting department: $e');
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Department Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
              Text("Define and manage institutional departments for user allocation.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showDeptDialog(),
            icon: const Icon(Icons.add),
            label: const Text("Create Department"),
            style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _departments.isEmpty
                ? const Center(child: Text("No departments created yet."))
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _departments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final dept = _departments[index];
                      return _DepartmentTile(
                        dept: dept,
                        onEdit: () => _showDeptDialog(dept: dept),
                        onDelete: () => _confirmDelete(dept['id'].toString(), dept['name']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentTile extends StatefulWidget {
  final dynamic dept;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentTile({
    required this.dept,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DepartmentTile> createState() => _DepartmentTileState();
}

class _DepartmentTileState extends State<_DepartmentTile> {
  bool _isExpanded = false;
  bool _isLoadingUsers = false;
  List<dynamic> _users = [];

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await ApiService.getDepartmentUsers(widget.dept['id'].toString());
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _users = response.data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dept users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          if (expanded && _users.isEmpty) {
            _fetchUsers();
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBrandOlive.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.apartment_rounded, color: kBrandOlive),
        ),
        title: Row(
          children: [
            Text(widget.dept['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            if (widget.dept['code'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text(widget.dept['code'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.dept['description'] ?? 'No description.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text("${widget.dept['user_count'] ?? 0} Users assigned", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandOlive)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: widget.onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: widget.onDelete),
            const SizedBox(width: 8),
            Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        children: [
          const Divider(height: 1),
          if (_isLoadingUsers)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_users.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No users assigned to this department.", style: TextStyle(fontSize: 12, color: Colors.grey))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, idx) {
                final user = _users[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: kBrandOlive.withOpacity(0.1),
                    child: Text(user['full_name'][0].toUpperCase(), style: const TextStyle(color: kBrandOlive, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  title: Text(user['full_name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(user['email'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                        child: Text(user['role_name'] ?? 'Staff', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      ),
                      const SizedBox(height: 4),
                      Text("Enrolled: ${_formatDate(user['created_at'])}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
