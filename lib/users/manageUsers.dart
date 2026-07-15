import 'package:flutter/material.dart';

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
  /// Optional hook — called when the "Add User" button is pressed.
  /// If not provided, a snackbar placeholder is shown instead.
  final VoidCallback? onAddUser;

  /// Optional hook — called when a user row's Edit action is pressed.
  final void Function(AppUser user)? onEditUser;

  const ManageUsersComponent({super.key, this.onAddUser, this.onEditUser});

  @override
  State<ManageUsersComponent> createState() => _ManageUsersComponentState();
}

class _ManageUsersComponentState extends State<ManageUsersComponent> {
  // ---------------------------------------------------------------------
  // MOCK DATA (replace with your real data source / API call)
  // ---------------------------------------------------------------------
  final List<AppUser> _users = [
    AppUser(
      id: '1',
      fullName: 'Edward Shaba',
      username: 'eshaba',
      email: 'edward.shaba@ageafrica.org',
      phone: '+265 991 234 567',
      role: 'Administrator',
      department: 'Information Technology',
      isActive: true,
      createdDate: DateTime(2025, 3, 12),
    ),
    AppUser(
      id: '2',
      fullName: 'Grace Banda',
      username: 'gbanda',
      email: 'grace.banda@ageafrica.org',
      phone: '+265 998 765 432',
      role: 'Program Manager',
      department: 'Programs',
      isActive: true,
      createdDate: DateTime(2025, 5, 2),
    ),
    AppUser(
      id: '3',
      fullName: 'Chikondi Phiri',
      username: 'cphiri',
      email: 'chikondi.phiri@ageafrica.org',
      phone: '+265 887 112 233',
      role: 'Data Officer',
      department: 'Monitoring & Evaluation',
      isActive: true,
      createdDate: DateTime(2025, 6, 18),
    ),
    AppUser(
      id: '4',
      fullName: 'Thandiwe Mvula',
      username: 'tmvula',
      email: 'thandiwe.mvula@ageafrica.org',
      phone: '+265 992 345 678',
      role: 'Finance Officer',
      department: 'Finance & Administration',
      isActive: false,
      createdDate: DateTime(2024, 11, 9),
    ),
    AppUser(
      id: '5',
      fullName: 'Blessings Kamanga',
      username: 'bkamanga',
      email: 'blessings.kamanga@ageafrica.org',
      phone: '+265 881 998 776',
      role: 'Field Coordinator',
      department: 'Field Operations',
      isActive: true,
      createdDate: DateTime(2025, 1, 27),
    ),
    AppUser(
      id: '6',
      fullName: 'Memory Nyirenda',
      username: 'mnyirenda',
      email: 'memory.nyirenda@ageafrica.org',
      phone: '+265 995 443 221',
      role: 'Volunteer',
      department: 'Programs',
      isActive: true,
      createdDate: DateTime(2025, 7, 1),
    ),
    AppUser(
      id: '7',
      fullName: 'Yamikani Chirwa',
      username: 'ychirwa',
      email: 'yamikani.chirwa@ageafrica.org',
      phone: '+265 993 221 445',
      role: 'Data Officer',
      department: 'Human Resources',
      isActive: false,
      createdDate: DateTime(2024, 9, 15),
    ),
    AppUser(
      id: '8',
      fullName: 'Precious Mhango',
      username: 'pmhango',
      email: 'precious.mhango@ageafrica.org',
      phone: '+265 884 556 778',
      role: 'Program Manager',
      department: 'Programs',
      isActive: true,
      createdDate: DateTime(2025, 4, 22),
    ),
  ];

  // Filters
  String _searchQuery = '';
  String? _roleFilter;
  String? _departmentFilter;
  String _statusFilter = 'All';
  bool _sortAscending = true;

  final List<String> _roles = [
    'Administrator',
    'Program Manager',
    'Data Officer',
    'Finance Officer',
    'Field Coordinator',
    'Volunteer',
  ];

  final List<String> _departments = [
    'Programs',
    'Finance & Administration',
    'Human Resources',
    'Information Technology',
    'Field Operations',
    'Monitoring & Evaluation',
  ];

  // ---------------------------------------------------------------------
  // DERIVED DATA
  // ---------------------------------------------------------------------
  List<AppUser> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    final list = _users.where((u) {
      final matchesSearch = query.isEmpty ||
          u.fullName.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      final matchesDept =
          _departmentFilter == null || u.department == _departmentFilter;
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && u.isActive) ||
          (_statusFilter == 'Inactive' && !u.isActive);
      return matchesSearch && matchesRole && matchesDept && matchesStatus;
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
  int get _adminCount =>
      _users.where((u) => u.role == 'Administrator').length;

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
          _roleFilter != null ||
          _departmentFilter != null ||
          _statusFilter != 'All';

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _roleFilter = null;
      _departmentFilter = null;
      _statusFilter = 'All';
    });
  }

  // ---------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------
  void _toggleStatus(AppUser user) {
    setState(() => user.isActive = !user.isActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${user.fullName} is now ${user.isActive ? 'active' : 'inactive'}",
        ),
        backgroundColor:
        user.isActive ? Colors.green.shade700 : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editUser(AppUser user) {
    if (widget.onEditUser != null) {
      widget.onEditUser!(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Edit '${user.fullName}' — hook up your edit form."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _confirmDelete(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            const Text("Delete User", style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete '${user.fullName}'? "
              "This action cannot be undone.",
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _users.removeWhere((u) => u.id == user.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${user.fullName}' was deleted."),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // STYLE HELPERS
  // ---------------------------------------------------------------------
  Color _roleColor(String role) {
    switch (role) {
      case 'Administrator':
        return Colors.purple.shade600;
      case 'Program Manager':
        return Colors.blue.shade600;
      case 'Data Officer':
        return Colors.teal.shade600;
      case 'Finance Officer':
        return Colors.orange.shade700;
      case 'Field Coordinator':
        return Colors.indigo.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: _buildStatsRow(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _buildFilterBar(),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildTableHeaderRow(),
          ),
          Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) =>
                  _buildUserRow(filtered[index]),
            ),
          ),
          _buildFooter(filtered.length),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER BANNER
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade800, Colors.green.shade600],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Manage Users",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "View, filter, and manage all system user accounts",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: "Refresh",
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: widget.onAddUser ??
                    () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Hook this up to your Create User page."),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text("Add User"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade800,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // STATS ROW
  // ---------------------------------------------------------------------
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Total Users",
            _totalCount.toString(),
            Icons.groups_rounded,
            Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Active",
            _activeCount.toString(),
            Icons.check_circle_rounded,
            Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Inactive",
            _inactiveCount.toString(),
            Icons.pause_circle_rounded,
            Colors.orange.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Administrators",
            _adminCount.toString(),
            Icons.shield_rounded,
            Colors.purple.shade600,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FILTER BAR
  // ---------------------------------------------------------------------
  Widget _buildFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: constraints.maxWidth < 700 ? constraints.maxWidth : 280,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search name, username, or email...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green.shade400, width: 1.4),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                initialValue: _roleFilter,
                isExpanded: true,
                hint: const Text("All Roles", style: TextStyle(fontSize: 13)),
                decoration: _compactDecoration(Icons.shield_outlined),
                items: _roles
                    .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _roleFilter = val),
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                initialValue: _departmentFilter,
                isExpanded: true,
                hint: const Text("All Departments", style: TextStyle(fontSize: 13)),
                decoration: _compactDecoration(Icons.apartment_outlined),
                items: _departments
                    .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _departmentFilter = val),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: _compactDecoration(Icons.toggle_on_outlined),
                items: ['All', 'Active', 'Inactive']
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 13)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _statusFilter = val ?? 'All'),
              ),
            ),
            if (_hasActiveFilters)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.close, size: 16, color: Colors.red.shade600),
                label: Text("Clear filters",
                    style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
              ),
          ],
        );
      },
    );
  }

  InputDecoration _compactDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 18),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade400, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // ---------------------------------------------------------------------
  // TABLE HEADER ROW
  // ---------------------------------------------------------------------
  Widget _buildTableHeaderRow() {
    TextStyle headerStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => setState(() => _sortAscending = !_sortAscending),
              child: Row(
                children: [
                  Text("USER", style: headerStyle),
                  const SizedBox(width: 4),
                  Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          Expanded(flex: 2, child: Text("ROLE", style: headerStyle)),
          Expanded(flex: 2, child: Text("DEPARTMENT", style: headerStyle)),
          Expanded(flex: 2, child: Text("STATUS", style: headerStyle)),
          Expanded(flex: 2, child: Text("CREATED", style: headerStyle)),
          SizedBox(width: 110, child: Text("ACTIONS", style: headerStyle)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // USER ROW
  // ---------------------------------------------------------------------
  Widget _buildUserRow(AppUser user) {
    final roleColor = _roleColor(user.role);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // USER (avatar + name + email)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Text(
                    _initialsOf(user.fullName),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        "@${user.username} • ${user.email}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ROLE badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // DEPARTMENT
          Expanded(
            flex: 2,
            child: Text(
              user.department,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),

          // STATUS toggle
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _toggleStatus(user),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user.isActive
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: user.isActive
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.isActive ? "Active" : "Inactive",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: user.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CREATED date
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(user.createdDate),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _editUser(user),
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: Colors.blue.shade600),
                  tooltip: "Edit",
                  splashRadius: 20,
                ),
                IconButton(
                  onPressed: () => _confirmDelete(user),
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: Colors.red.shade400),
                  tooltip: "Delete",
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          Text(
            "No users found",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try adjusting your search or filters",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close, size: 16),
              label: const Text("Clear filters"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------
  Widget _buildFooter(int visibleCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing $visibleCount of $_totalCount user${_totalCount == 1 ? '' : 's'}",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              Icon(Icons.circle, size: 7, color: Colors.green.shade600),
              const SizedBox(width: 5),
              Text("$_activeCount active",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 14),
              Icon(Icons.circle, size: 7, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text("$_inactiveCount inactive",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}