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
    final nameCtrl = TextEditingController(text: dept?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: dept?['code']?.toString() ?? '');
    final descCtrl = TextEditingController(text: dept?['description']?.toString() ?? '');
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
                  if (ctx.mounted) Navigator.pop(ctx);
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
                  if (ctx.mounted) Navigator.pop(ctx);
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
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 32, isMobile ? 16 : 24, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Departments", style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showDeptDialog(),
            icon: const Icon(Icons.add, size: 14),
            label: Text(isMobile ? "ADD" : "CREATE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(String userId) {
    if (userId.isEmpty) return;
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
              key: const PageStorageKey('departments_list'),
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              itemCount: _departments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final dept = _departments[index];
                return _DepartmentTile(
                  key: ValueKey(dept['id']),
                  dept: dept,
                  onEdit: () => _showDeptDialog(dept: dept),
                  onDelete: () => _confirmDelete(
                    dept['id'].toString(),
                    dept['name']?.toString() ?? 'this department',
                  ),
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
    super.key,
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
  bool _hasError = false;
  List<dynamic> _users = [];

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _hasError = false;
    });
    try {
      final response = await ApiService.getDepartmentUsers(widget.dept['id'].toString());
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        if (mounted) {
          setState(() {
            _users = rawData is List ? rawData : [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dept users: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  // Safe getters so a missing/null field from the API never crashes the tile.
  String _name(dynamic user) {
    final v = user['fullName'] ?? user['full_name'] ?? user['name'];
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? 'Unnamed User' : s;
  }

  String _initial(dynamic user) {
    final n = _name(user);
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String _email(dynamic user) {
    final v = (user['email'] ?? user['email_address'] ?? user['emailAddress'])?.toString().trim();
    return (v == null || v.isEmpty) ? 'No email on file' : v;
  }

  String _userId(dynamic user) {
    return (user['id'] ?? user['_id'] ?? '').toString();
  }

  String _role(dynamic user) {
    if (user['role_name'] != null) return user['role_name'].toString();
    if (user['roleName'] != null) return user['roleName'].toString();
    if (user['roleId'] != null && user['roleId'] is Map) {
      return user['roleId']['name']?.toString() ?? 'Staff';
    }
    return 'Staff';
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildTrailing() {
    // On narrow screens, a row of two icon buttons + the expand arrow can
    // overflow and throw layout exceptions repeatedly on expand/collapse.
    // Use a compact popup menu instead so it never overflows.
    if (widget.isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            onSelected: (value) {
              if (value == 'edit') widget.onEdit();
              if (value == 'delete') widget.onDelete();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionBtn(Icons.edit_outlined, kBrandBrown, widget.onEdit),
        const SizedBox(width: 8),
        _actionBtn(Icons.delete_outline, Colors.redAccent, widget.onDelete),
        const SizedBox(width: 12),
        Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptName = widget.dept['name']?.toString() ?? 'Unnamed Department';
    final deptCode = widget.dept['code']?.toString();
    final deptDesc = widget.dept['description']?.toString();
    final userCount = widget.dept['userCount'] ?? widget.dept['user_count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // Explicit, unique, string-based key so this never collides in
        // PageStorage with another widget (e.g. a nested ListView saving a
        // scroll-offset double under the same derived key) — that collision
        // is what causes "type 'bool' is not a subtype of type 'double?'".
        key: PageStorageKey('dept_expansion_${widget.dept['id']}'),
        tilePadding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 20, vertical: 8),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          if (expanded) {
            _fetchUsers();
          }
        },
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
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
                      Flexible(
                        child: Text(
                          deptName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isMobile ? 14 : 16),
                        ),
                      ),
                      if (deptCode != null && deptCode.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text(deptCode, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
                  if (widget.isMobile)
                    Text("$userCount staff",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kBrandOlive, letterSpacing: 0.2)),
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
                  "$userCount staff",
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kBrandOlive, letterSpacing: 0.2),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
        subtitle: Text(
          (deptDesc == null || deptDesc.isEmpty) ? 'No description.' : deptDesc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: _buildTrailing(),
        children: [
          const Divider(height: 1),
          if (_isLoadingUsers)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const Text("Couldn't load staff for this department.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _fetchUsers, child: const Text("Retry", style: TextStyle(fontSize: 11))),
                  ],
                ),
              ),
            )
          else if (_users.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No users assigned.", style: TextStyle(fontSize: 11, color: Colors.grey))))
            else
              ListView.separated(
                // Own unique key, separate namespace from the ExpansionTile's
                // key above, so PageStorage never mixes their saved state.
                key: PageStorageKey('dept_users_list_${widget.dept['id']}'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, idx) {
                  final user = _users[idx];
                  final name = _name(user);
                  final email = _email(user);
                  final initial = _initial(user);
                  final userId = _userId(user);
                  final roleName = _role(user);

                  return ListTile(
                    onTap: userId.isEmpty ? null : () => widget.onUserTap(userId),
                    contentPadding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 24, vertical: 8),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: kBrandOlive.withOpacity(0.1),
                      child: Text(initial, style: const TextStyle(color: kBrandOlive, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    subtitle: Text(email, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    trailing: widget.isMobile ? null : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                          child: Text(roleName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        ),
                        const SizedBox(height: 4),
                        Text("Enrolled: ${_formatDate(user['created_at']?.toString())}", style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
  bool _hasError = false;
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
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        if (mounted) {
          setState(() {
            _user = rawData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _hasError = true; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  String _field(String key, {String fallback = 'Not provided'}) {
    final v = _user is Map ? _user[key] : null;
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: kBrandOlive)),
        ),
      );
    }

    if (_hasError || _user == null) {
      return AlertDialog(
        title: const Text("User Not Found"),
        content: const Text("We couldn't load this user's details. Please try again."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      );
    }

    final fullName = _field('fullName', fallback: _field('full_name', fallback: 'N/A'));
    final initials = fullName == 'N/A'
        ? 'U'
        : fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
    final profilePicture = _user['profile_picture'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
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
                      backgroundImage: (profilePicture != null && profilePicture.toString().isNotEmpty)
                          ? NetworkImage(ApiService.getFullUrl(profilePicture.toString()))
                          : null,
                      child: (profilePicture == null || profilePicture.toString().isEmpty)
                          ? Text(initials.isEmpty ? 'U' : initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: kBrandOlive, borderRadius: BorderRadius.circular(20)),
                      child: Text(_field('role_name', fallback: 'STAFF').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _detailRow(Icons.alternate_email_rounded, "Username", "@${_field('username', fallback: 'n/a')}"),
                    const Divider(height: 32),
                    _detailRow(Icons.email_outlined, "Email Address", _field('email')),
                    const Divider(height: 32),
                    _detailRow(Icons.phone_android_rounded, "Phone Number", _field('phone', fallback: _field('phone_number', fallback: 'Not provided'))),
                    const Divider(height: 32),
                    _detailRow(Icons.apartment_rounded, "Department", _field('department_name', fallback: _field('departmentName', fallback: 'Unallocated'))),
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
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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