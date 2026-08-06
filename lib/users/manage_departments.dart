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
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        setState(() {
          _departments = rawData is List ? rawData : [];
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

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Departments", style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const Text("Define institutional structure.", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showDeptDialog(),
            icon: Icon(Icons.add, size: isMobile ? 14 : 16),
            label: Text(isMobile ? "ADD" : "CREATE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _UserDetailsDialog(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

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
          _buildHeader(isMobile),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : _departments.isEmpty
                ? const Center(child: Text("No departments created yet."))
                : ListView.separated(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    itemCount: _departments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final dept = _departments[index];
                      return _DepartmentTile(
                        dept: dept,
                        onEdit: () => _showDeptDialog(dept: dept),
                        onDelete: () => _confirmDelete(dept['id'].toString(), dept['name']),
                        onUserTap: _showUserDetails,
                        isMobile: isMobile,
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
  final Function(String) onUserTap;
  final bool isMobile;

  const _DepartmentTile({
    required this.dept,
    required this.onEdit,
    required this.onDelete,
    required this.onUserTap,
    this.isMobile = false,
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        hoverColor: color.withOpacity(0.1),
      ),
    );
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
        tilePadding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 20, vertical: 8),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          if (expanded && _users.isEmpty) {
            _fetchUsers();
          }
        },
        leading: widget.isMobile ? null : Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBrandOlive.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.apartment_rounded, color: kBrandOlive),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.dept['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isMobile ? 14 : 16)),
                      if (widget.dept['code'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text(widget.dept['code'], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
                  if (widget.isMobile)
                    Text("${widget.dept['userCount'] ?? widget.dept['user_count'] ?? 0} PERSONNEL",
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 0.5)),
                ],
              ),
            ),
            if (!widget.isMobile) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kBrandOlive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${widget.dept['userCount'] ?? widget.dept['user_count'] ?? 0} PERSONNEL",
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
        subtitle: Text(widget.dept['description'] ?? 'No description.', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(Icons.edit_outlined, kBrandBrown, widget.onEdit),
            const SizedBox(width: 8),
            _actionBtn(Icons.delete_outline, Colors.redAccent, widget.onDelete),
            const SizedBox(width: 12),
            Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
        children: [
          const Divider(height: 1),
          if (_isLoadingUsers)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_users.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No users assigned.", style: TextStyle(fontSize: 11, color: Colors.grey))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, idx) {
                final user = _users[idx];
                return ListTile(
                  onTap: () => widget.onUserTap(user['id'] ?? user['_id']),
                  contentPadding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 24, vertical: 8),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: kBrandOlive.withOpacity(0.1),
                    child: Text(user['full_name'][0].toUpperCase(), style: const TextStyle(color: kBrandOlive, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(user['full_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(user['email'], style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                  trailing: widget.isMobile ? null : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                        child: Text(user['role_name'] ?? 'Staff', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      ),
                      const SizedBox(height: 4),
                      Text("Enrolled: ${_formatDate(user['created_at'])}", style: const TextStyle(fontSize: 9, color: Colors.grey)),
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

class _UserDetailsDialog extends StatefulWidget {
  final String userId;
  const _UserDetailsDialog({required this.userId});

  @override
  State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> {
  bool _isLoading = true;
  dynamic _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final response = await ApiService.getUserById(widget.userId);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _user = response.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    if (_user == null) {
      return const AlertDialog(content: Text("User details not found."));
    }

    final initials = _user['full_name'] != null
        ? _user['full_name'].toString().trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "U";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: kBrandBrown,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: _user['profile_picture'] != null
                        ? NetworkImage(ApiService.getFullUrl(_user['profile_picture']))
                        : null,
                    child: _user['profile_picture'] == null
                        ? Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(_user['full_name'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: kBrandOlive, borderRadius: BorderRadius.circular(20)),
                    child: Text(_user['role_name']?.toString().toUpperCase() ?? 'STAFF',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  _detailRow(Icons.alternate_email_rounded, "Username", "@${_user['username']}"),
                  const Divider(height: 32),
                  _detailRow(Icons.email_outlined, "Email Address", _user['email']),
                  const Divider(height: 32),
                  _detailRow(Icons.phone_android_rounded, "Phone Number", _user['phone'] ?? 'Not provided'),
                  const Divider(height: 32),
                  _detailRow(Icons.apartment_rounded, "Department", _user['department_name'] ?? 'Unallocated'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("CLOSE PROFILE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: kBrandOlive),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kBrandBrown)),
            ],
          ),
        ),
      ],
    );
  }
}
