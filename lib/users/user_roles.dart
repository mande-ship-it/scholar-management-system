import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

class UserRolesComponent extends StatefulWidget {
  final void Function(UserRole role)? onManagePermissions;

  const UserRolesComponent({super.key, this.onManagePermissions});

  @override
  State<UserRolesComponent> createState() => _UserRolesComponentState();
}

class _UserRolesComponentState extends State<UserRolesComponent> {
  List<UserRole> _roles = [];
  bool _isLoading = false;
  String _searchQuery = '';

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
        final dynamic raw = response.data;
        List<dynamic> data = [];
        if (raw is Map && raw.containsKey('data')) {
          data = raw['data'] is List ? raw['data'] : [];
        } else if (raw is List) {
          data = raw;
        }

        if (mounted) {
          setState(() {
            _roles = data
                .map((r) {
                  if (r is! Map) return null;
                  return UserRole(
                    id: (r['id'] ?? r['_id'] ?? '').toString(),
                    name: r['name'] ?? '',
                    description: r['description'] ?? '',
                    icon: _getIconData(r['icon']),
                    color: _getColor(r['color']),
                    userCount: r['userCount'] ?? r['user_count'] ?? 0,
                    isSystemRole: r['isSystemRole'] ?? r['is_system_role'] ?? false,
                    createdDate: DateTime.tryParse(r['createdAt'] ?? r['created_at'] ?? '') ??
                        DateTime.now(),
                  );
                })
                .whereType<UserRole>()
                .toList();
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

  List<UserRole> get _filteredRoles {
    if (_searchQuery.trim().isEmpty) return _roles;
    final q = _searchQuery.trim().toLowerCase();
    return _roles
        .where((r) =>
    r.name.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q))
        .toList();
  }

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
                                  color: selectedColor.withOpacity(0.12),
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
                                        ? selectedColor.withOpacity(0.14)
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
                              final isSelected = color.value ==
                                  selectedColor.value;
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
        'color': '#${result.color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}',
      };

      try {
        if (role == null) {
          final response = await ApiService.createRole(roleData);
          if (response.statusCode == 201) _fetchRoles();
        } else {
          final response = await ApiService.updateRole(role.id, roleData);
          if (response.statusCode == 200) _fetchRoles();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(role == null ? "Role created." : "Role updated."),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error saving role."), backgroundColor: Colors.redAccent),
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
        const SnackBar(content: Text("System roles cannot be deleted.")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Role"),
        content: Text("Permanently delete '${role.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteRole(role.id);
        if (response.statusCode == 200) {
          _fetchRoles();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role deleted.")));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error deleting role.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoles;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(isMobile),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: isMobile ? "Search roles..." : "Search roles by name or description...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("No roles found"))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int columns = constraints.maxWidth < 620 ? 1 : (constraints.maxWidth < 980 ? 2 : 3);
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isMobile ? 1.4 : 1.55,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildRoleCard(filtered[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 12, isMobile ? 16 : 24, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Define system access models",
                  style: TextStyle(
                      color: const Color(0xFF4C3C32), fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openRoleDialog(),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(isMobile ? "ADD" : "REGISTER"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C3C32),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: role.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: role.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    Text("${role.userCount} users", style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: Text(role.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          const Divider(),
          Row(
            children: [
              TextButton(
                onPressed: () => widget.onManagePermissions?.call(role),
                child: const Text("Permissions", style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              IconButton(onPressed: () => _openRoleDialog(role: role), icon: const Icon(Icons.edit_outlined, size: 16)),
              IconButton(onPressed: () => _confirmDelete(role), icon: const Icon(Icons.delete_outline, size: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
