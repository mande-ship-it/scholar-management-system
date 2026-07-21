import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// ---------------------------------------------------------------------
/// MODEL
/// ---------------------------------------------------------------------
class UserRole {
  final String id;
  String name;
  String description;
  IconData icon;
  Color color;
  int userCount;
  final bool isSystemRole;
  final DateTime createdDate;

  UserRole({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.userCount,
    this.isSystemRole = false,
    required this.createdDate,
  });
}

class _RoleFormResult {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _RoleFormResult({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// ---------------------------------------------------------------------
/// ROLES COMPONENT
/// ---------------------------------------------------------------------
class UserRolesComponent extends StatefulWidget {
  /// Optional hook — called when "Manage Permissions" is tapped on a role card.
  final void Function(UserRole role)? onManagePermissions;

  const UserRolesComponent({super.key, this.onManagePermissions});

  @override
  State<UserRolesComponent> createState() => _UserRolesComponentState();
}

class _UserRolesComponentState extends State<UserRolesComponent> {
  List<UserRole> _roles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllRoles();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _roles = data.map((r) => UserRole(
              id: r['id'].toString(),
              name: r['name'] ?? '',
              description: r['description'] ?? '',
              icon: _getIconData(r['icon']),
              color: _getColor(r['color']),
              userCount: 0, // In a real app, backend would return this count
              isSystemRole: r['is_system_role'] ?? false,
              createdDate: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
            )).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconData(String? iconName) {
    // Basic mapping from icon name string to IconData
    switch (iconName) {
      case 'shield_rounded': return Icons.shield_rounded;
      case 'supervisor_account_rounded': return Icons.supervisor_account_rounded;
      case 'storage_rounded': return Icons.storage_rounded;
      case 'attach_money_rounded': return Icons.attach_money_rounded;
      case 'map_rounded': return Icons.map_rounded;
      case 'volunteer_activism_rounded': return Icons.volunteer_activism_rounded;
      case 'badge_rounded': return Icons.badge_rounded;
      case 'work_rounded': return Icons.work_rounded;
      case 'security_rounded': return Icons.security_rounded;
      case 'admin_panel_settings_rounded': return Icons.admin_panel_settings_rounded;
      case 'groups_rounded': return Icons.groups_rounded;
      default: return Icons.person_rounded;
    }
  }

  Color _getColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _searchQuery = '';

  // Icon & color palettes offered in the create/edit dialog
  final List<IconData> _iconChoices = const [
    Icons.shield_rounded,
    Icons.supervisor_account_rounded,
    Icons.storage_rounded,
    Icons.attach_money_rounded,
    Icons.map_rounded,
    Icons.volunteer_activism_rounded,
    Icons.badge_rounded,
    Icons.work_rounded,
    Icons.security_rounded,
    Icons.admin_panel_settings_rounded,
    Icons.groups_rounded,
    Icons.person_rounded,
  ];

  final List<Color> _colorChoices = [
    Colors.purple.shade600,
    Colors.blue.shade600,
    Colors.teal.shade600,
    Colors.orange.shade700,
    Colors.indigo.shade600,
    Colors.blueGrey.shade600,
    Colors.red.shade600,
    Colors.pink.shade600,
    Colors.brown.shade500,
    Colors.green.shade700,
  ];

  // ---------------------------------------------------------------------
  // DERIVED DATA
  // ---------------------------------------------------------------------
  List<UserRole> get _filteredRoles {
    if (_searchQuery.trim().isEmpty) return _roles;
    final q = _searchQuery.trim().toLowerCase();
    return _roles
        .where((r) =>
    r.name.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q))
        .toList();
  }

  int get _totalUsers => _roles.fold(0, (sum, r) => sum + r.userCount);
  int get _systemRoleCount => _roles.where((r) => r.isSystemRole).length;
  int get _customRoleCount => _roles.length - _systemRoleCount;

  // ---------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------
  Future<void> _openRoleDialog({UserRole? role}) async {
    final nameController = TextEditingController(text: role?.name ?? '');
    final descController = TextEditingController(text: role?.description ?? '');
    IconData selectedIcon = role?.icon ?? _iconChoices.first;
    Color selectedColor = role?.color ?? _colorChoices.first;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_RoleFormResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(selectedIcon, color: selectedColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  role == null ? "Create New Role" : "Edit Role",
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: "Role Name *",
                              prefixIcon: const Icon(Icons.label_outline, size: 20),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? "Enter a role name"
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: descController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: "Description",
                              prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text("Icon",
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _iconChoices.map((icon) {
                              final isSelected = icon == selectedIcon;
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () =>
                                    setDialogState(() => selectedIcon = icon),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? selectedColor.withValues(alpha: 0.14)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? selectedColor
                                          : Colors.grey.shade200,
                                      width: isSelected ? 1.6 : 1,
                                    ),
                                  ),
                                  child: Icon(icon,
                                      size: 18,
                                      color: isSelected
                                          ? selectedColor
                                          : Colors.grey.shade600),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          Text("Color",
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _colorChoices.map((color) {
                              final isSelected = color.toARGB32() ==
                                  selectedColor.toARGB32();
                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    setDialogState(() => selectedColor = color),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      Navigator.pop(
                                        context,
                                        _RoleFormResult(
                                          name: nameController.text.trim(),
                                          description: descController.text.trim(),
                                          icon: selectedIcon,
                                          color: selectedColor,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(role == null
                                      ? "Create Role"
                                      : "Save Changes"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final roleData = {
        'name': result.name,
        'description': result.description,
        'icon': _getIconString(result.icon),
        'color': '#${result.color.toARGB32().toRadixString(16).substring(2)}',
      };

      try {
        if (role == null) {
          final response = await ApiService.createRole(roleData);
          if (response.statusCode == 201) {
            _fetchRoles();
          }
        } else {
          final response = await ApiService.updateRole(role.id, roleData);
          if (response.statusCode == 200) {
            _fetchRoles();
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(role == null
                ? "Role '${result.name}' created."
                : "Role '${result.name}' updated."),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error saving role. Please try again."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _getIconString(IconData icon) {
    if (icon == Icons.shield_rounded) return 'shield_rounded';
    if (icon == Icons.supervisor_account_rounded) return 'supervisor_account_rounded';
    if (icon == Icons.storage_rounded) return 'storage_rounded';
    if (icon == Icons.attach_money_rounded) return 'attach_money_rounded';
    if (icon == Icons.map_rounded) return 'map_rounded';
    if (icon == Icons.volunteer_activism_rounded) return 'volunteer_activism_rounded';
    if (icon == Icons.badge_rounded) return 'badge_rounded';
    if (icon == Icons.work_rounded) return 'work_rounded';
    if (icon == Icons.security_rounded) return 'security_rounded';
    if (icon == Icons.admin_panel_settings_rounded) return 'admin_panel_settings_rounded';
    if (icon == Icons.groups_rounded) return 'groups_rounded';
    return 'person_rounded';
  }

  Future<void> _confirmDelete(UserRole role) async {
    if (role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${role.name}' is a system role and cannot be deleted."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (role.userCount > 0) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text("Role In Use", style: TextStyle(fontSize: 17))),
            ],
          ),
          content: Text(
            "${role.userCount} user${role.userCount == 1 ? '' : 's'} "
                "${role.userCount == 1 ? 'is' : 'are'} currently assigned to "
                "'${role.name}'. Reassign ${role.userCount == 1 ? 'this user' : 'these users'} "
                "to a different role before deleting it.",
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Got it"),
            ),
          ],
        ),
      );
      return;
    }

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
              child: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            const Text("Delete Role", style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete '${role.name}'? "
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
      try {
        final response = await ApiService.deleteRole(role.id);
        if (response.statusCode == 200) {
          _fetchRoles();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Role '${role.name}' was deleted."),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error deleting role. Please try again."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoles;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          // ---------------- Stats (Banners Removed) ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search roles by name or description...",
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int columns = 3;
                          if (constraints.maxWidth < 620) {
                            columns = 1;
                          } else if (constraints.maxWidth < 980) {
                            columns = 2;
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.55,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildRoleCard(filtered[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ---------------- CLEAN HEADER (Banner Removed) ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.green, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User Roles",
                  style: TextStyle(
                      color: Color(0xFF4C3C32), fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Define and manage the roles available across CHATS.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openRoleDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text("New Role"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C3C32),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ROLE CARD
  // ---------------------------------------------------------------------
  Widget _buildRoleCard(UserRole role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: role.color, size: 20),
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
                            role.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (role.isSystemRole) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "SYSTEM",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          "${role.userCount} user${role.userCount == 1 ? '' : 's'}",
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              role.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
          Divider(color: Colors.grey.shade100, height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    if (widget.onManagePermissions != null) {
                      widget.onManagePermissions!(role);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Hook this up to the Permissions tab for '${role.name}'."),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.lock_outline_rounded, size: 15, color: role.color),
                  label: Text("Permissions",
                      style: TextStyle(fontSize: 12, color: role.color)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openRoleDialog(role: role),
                icon: Icon(Icons.edit_outlined, size: 17, color: Colors.blue.shade600),
                tooltip: "Edit",
                splashRadius: 18,
              ),
              IconButton(
                onPressed: () => _confirmDelete(role),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: role.isSystemRole ? Colors.grey.shade400 : Colors.red.shade400,
                ),
                tooltip: role.isSystemRole ? "System role" : "Delete",
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          Text("No roles found",
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text("Try a different search term",
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}