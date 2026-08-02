import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import '../academics/academics_utils.dart';

/// ---------------------------------------------------------------------
/// MODEL
/// ---------------------------------------------------------------------
class AppUser {
  final String id;
  String fullName;
  String username;
  String email;
  String phone;
  String role;
  String department;
  bool isActive;
  DateTime createdDate;

  AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.isActive,
    required this.createdDate,
  });
}

/// ---------------------------------------------------------------------
/// MANAGE USERS COMPONENT
/// ---------------------------------------------------------------------
class ManageUsersComponent extends StatefulWidget {
  final VoidCallback? onAddUser;
  final VoidCallback? onViewRoles;
  final VoidCallback? onViewPermissions;
  final VoidCallback? onViewDepartments;
  final VoidCallback? onViewProfile;
  final void Function(AppUser user)? onEditUser;

  const ManageUsersComponent({
    super.key,
    this.onAddUser,
    this.onViewRoles,
    this.onViewPermissions,
    this.onViewDepartments,
    this.onViewProfile,
    this.onEditUser,
  });

  @override
  State<ManageUsersComponent> createState() => _ManageUsersComponentState();
}

class _ManageUsersComponentState extends State<ManageUsersComponent> {
  List<AppUser> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchRoles();
    _fetchDepartments();
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await ApiService.getAllRoles();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];

        if (mounted) {
          setState(() {
            _roles.clear();
            _roles.addAll(data.map((r) => r['name'].toString()).toList());
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await ApiService.getAllDepartments();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];

        if (mounted) {
          setState(() {
            _departments.clear();
            _departments.addAll(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllUsers();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];

        if (mounted) {
          setState(() {
            _users = data.map((u) => AppUser(
              id: (u['id'] ?? u['_id'] ?? '').toString(),
              fullName: u['fullName'] ?? u['full_name'] ?? '',
              username: u['username'] ?? '',
              email: u['email'] ?? '',
              phone: u['phone'] ?? '',
              role: u['role_name'] ?? 'Staff',
              department: u['department_name'] ?? u['department'] ?? 'Unallocated',
              isActive: u['isActive'] ?? u['is_active'] ?? true,
              createdDate: DateTime.tryParse(u['createdAt'] ?? u['created_at'] ?? '') ?? DateTime.now(),
            )).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filters
  String _searchQuery = '';
  String? _roleFilter;
  String _statusFilter = 'All';
  bool _sortAscending = true;

  final List<String> _roles = [];
  final List<dynamic> _departments = [];

  List<AppUser> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    final list = _users.where((u) {
      final matchesSearch = query.isEmpty ||
          u.fullName.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && u.isActive) ||
          (_statusFilter == 'Inactive' && !u.isActive);
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    list.sort((a, b) {
      final cmp = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  int get _totalCount => _users.length;
  int get _activeCount => _users.where((u) => u.isActive).length;
  int get _inactiveCount => _totalCount - _activeCount;

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
          _roleFilter != null ||
          _statusFilter != 'All';

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _roleFilter = null;
      _statusFilter = 'All';
    });
  }

  void _toggleStatus(AppUser user) async {
    final oldStatus = user.isActive;
    setState(() => user.isActive = !user.isActive);

    try {
      final response = await ApiService.updateUser(user.id, {'isActive': user.isActive});
      if (response.statusCode != 200) {
        throw Exception("Failed to update status");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${user.fullName} status updated."),
          backgroundColor: user.isActive ? kBrandOlive : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => user.isActive = oldStatus);
    }
  }

  void _editUser(AppUser user) {
    if (widget.onEditUser != null) {
      widget.onEditUser!(user);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(
        user: user,
        roles: _roles,
        departments: _departments,
        onUserUpdated: (updatedUser) {
          setState(() {
            final index = _users.indexWhere((u) => u.id == updatedUser.id);
            if (index != -1) {
              _users[index] = updatedUser;
            }
          });
          _fetchUsers(); // Refresh counts
        },
      ),
    );
  }

  Future<void> _confirmDelete(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete User"),
        content: Text("Are you sure you want to permanently delete '${user.fullName}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteUser(user.id);
        if (response.statusCode == 200) {
          setState(() => _users.removeWhere((u) => u.id == user.id));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        debugPrint('Error deleting user: $e');
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Administrator': return Colors.purple;
      case 'Program Manager': return Colors.blue;
      case 'Data Officer': return Colors.teal;
      case 'Finance Officer': return Colors.orange;
      case 'Field Coordinator': return Colors.indigo;
      default: return Colors.blueGrey;
    }
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfessionalHeader(),
          _buildStatsRow(),
          _buildSubNavigation(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  _buildFilterBar(),
                  const SizedBox(height: 24),
                  _buildProfessionalTable(filtered),
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
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandBrown.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.manage_accounts_rounded, color: kBrandBrown, size: 30),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Administration", 
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text("Command center for identity management, access control and role governance.", 
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (PermissionService.hasPermission('users.create'))
            ElevatedButton.icon(
              onPressed: widget.onAddUser,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text("Register User"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Row(
        children: [
          _statTile("Global Users", _totalCount.toString(), Colors.blue),
          _statTile("Active Identities", _activeCount.toString(), kBrandOlive),
          _statTile("Deactivated", _inactiveCount.toString(), Colors.grey),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSubNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 10, 32, 24),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _subNavItem("User Profiles", Icons.account_circle_outlined, widget.onViewProfile),
          _subNavItem("Role Architecture", Icons.security_rounded, widget.onViewRoles),
          _subNavItem("Departmental Structure", Icons.apartment_rounded, widget.onViewDepartments),
          _subNavItem("Governance Permissions", Icons.admin_panel_settings_outlined, widget.onViewPermissions),
        ],
      ),
    );
  }

  Widget _subNavItem(String label, IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: kBrandBrown),
        label: Text(label, style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 13)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: "Filter by name, username or email...",
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _dropdownFilter("ROLES", _roleFilter, _roles, (v) => setState(() => _roleFilter = v)),
        const SizedBox(width: 16),
        _dropdownFilter("STATUS", _statusFilter, ['All', 'Active', 'Inactive'], (v) => setState(() => _statusFilter = v ?? 'All')),
        if (_hasActiveFilters)
          IconButton(onPressed: _clearFilters, icon: const Icon(Icons.filter_list_off_rounded, color: Colors.redAccent), tooltip: "Reset Filters"),
      ],
    );
  }

  Widget _dropdownFilter(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildProfessionalTable(List<AppUser> filtered) {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: kBrandOlive)));
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text("No identities found matching the current filters.", style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        dataRowMaxHeight: 80,
        horizontalMargin: 32,
        columnSpacing: 40,
        columns: const [
          DataColumn(label: Text("USER IDENTITY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1))),
          DataColumn(label: Text("ROLE & SCOPE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1))),
          DataColumn(label: Text("ACCESS STATUS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1))),
          DataColumn(label: Text("ONBOARDED", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1))),
          DataColumn(label: Text("GOVERNANCE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1))),
        ],
        rows: filtered.map((u) {
          final color = _roleColor(u.role);
          return DataRow(cells: [
            DataCell(Row(
              children: [
                CircleAvatar(
                  radius: 22, 
                  backgroundColor: color.withOpacity(0.1), 
                  child: Text(_initialsOf(u.fullName), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14))),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kBrandBrown)),
                  Text(u.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
              ],
            )),
            DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(u.role.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 4),
              Text(u.department, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            ])),
            DataCell(Row(
              children: [
                Text(u.isActive ? "Authorized" : "Revoked", 
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: u.isActive ? kBrandOlive : Colors.redAccent)),
                const SizedBox(width: 12),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(value: u.isActive, activeColor: kBrandOlive, onChanged: (_) => _toggleStatus(u)),
                ),
              ],
            )),
            DataCell(Text(_formatDate(u.createdDate), style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
            DataCell(Row(children: [
              if (PermissionService.hasPermission('users.edit'))
                _actionBtn(Icons.edit_note_rounded, Colors.blue, () => _editUser(u)),
              if (PermissionService.hasPermission('users.edit') && PermissionService.hasPermission('users.delete'))
                const SizedBox(width: 8),
              if (PermissionService.hasPermission('users.delete'))
                _actionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _confirmDelete(u)),
            ])),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color), 
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        hoverColor: color.withOpacity(0.1),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// EDIT USER DIALOG
/// ---------------------------------------------------------------------
class _EditUserDialog extends StatefulWidget {
  final AppUser user;
  final List<String> roles;
  final List<dynamic> departments;
  final Function(AppUser) onUserUpdated;

  const _EditUserDialog({
    required this.user,
    required this.roles,
    required this.departments,
    required this.onUserUpdated,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  String? _selectedRole;
  dynamic _selectedDepartmentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedRole = widget.user.role;
    
    // Find initial department ID
    try {
      final dept = widget.departments.firstWhere((d) => d['name'] == widget.user.department);
      _selectedDepartmentId = dept['id'];
    } catch (_) {
      _selectedDepartmentId = null;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      final data = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'roleName': _selectedRole,
        'departmentId': _selectedDepartmentId,
      };

      try {
        final response = await ApiService.updateUser(widget.user.id, data);
        if (response.statusCode == 200) {
          final dept = widget.departments.firstWhere((d) => d['id'] == _selectedDepartmentId, orElse: () => {'name': 'Unallocated'});
          final updated = AppUser(
            id: widget.user.id,
            fullName: _fullNameController.text.trim(),
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole!,
            department: dept['name'],
            isActive: widget.user.isActive,
            createdDate: widget.user.createdDate,
          );
          widget.onUserUpdated(updated);
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Error updating user: $e');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: kBrandOlive, size: 28),
          const SizedBox(width: 12),
          Text("Edit User: ${widget.user.fullName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                _buildTextField(_fullNameController, "Full Name", Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_usernameController, "Username", Icons.alternate_email),
                const SizedBox(height: 16),
                _buildTextField(_emailController, "Email Address", Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: widget.roles.contains(_selectedRole) ? _selectedRole : null,
                  decoration: _inputDeco("System Role", Icons.security_rounded),
                  items: widget.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<dynamic>(
                  value: _selectedDepartmentId,
                  decoration: _inputDeco("Department", Icons.apartment_rounded),
                  items: widget.departments.map((d) => DropdownMenuItem(value: d['id'], child: Text(d['name']))).toList(),
                  onChanged: (v) => setState(() => _selectedDepartmentId = v),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Discard", style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandOlive,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: _inputDeco(label, icon),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.6)),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
