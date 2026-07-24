import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// ---------------------------------------------------------------------
/// PERMISSIONS COMPONENT
/// Role-based, module-level permission matrix (View / Create / Edit / Delete)
/// ---------------------------------------------------------------------
class PermissionsComponent extends StatefulWidget {
  const PermissionsComponent({super.key});

  @override
  State<PermissionsComponent> createState() => _PermissionsComponentState();
}

class _PermissionsComponentState extends State<PermissionsComponent> {
  // ---------------------------------------------------------------------
  // CONFIG
  // ---------------------------------------------------------------------
  final List<String> _roles = [];

  final List<String> _modules = [
    'Dashboard',
    'Scholars',
    'Schools',
    'Sponsors',
    'Academics',
    'Attendance',
    'Finance',
    'Reports',
    'Users',
    'Settings',
  ];

  final List<String> _actions = ['view', 'create', 'edit', 'delete'];

  final Map<String, String> _actionLabels = const {
    'view': 'View',
    'create': 'Create',
    'edit': 'Edit',
    'delete': 'Delete',
  };

  final Map<String, IconData> _actionIcons = const {
    'view': Icons.visibility_outlined,
    'create': Icons.add_circle_outline,
    'edit': Icons.edit_outlined,
    'delete': Icons.delete_outline,
  };

  final Map<String, IconData> _moduleIcons = const {
    'Dashboard': Icons.dashboard_outlined,
    'Scholars': Icons.school_outlined,
    'Schools': Icons.apartment_outlined,
    'Sponsors': Icons.volunteer_activism_outlined,
    'Academics': Icons.menu_book_outlined,
    'Attendance': Icons.fact_check_outlined,
    'Finance': Icons.attach_money_rounded,
    'Reports': Icons.bar_chart_rounded,
    'Users': Icons.group_outlined,
    'Settings': Icons.settings_outlined,
  };

  Map<String, Map<String, Map<String, bool>>> _permissions = {};
  String _selectedRole = 'Administrator';
  String _moduleSearch = '';
  bool _hasUnsavedChanges = false;
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
            _roles.clear();
            _roles.addAll(data.map((r) => r['name'].toString()).toList());
            _permissions = _buildDefaultPermissions();
            if (_roles.isNotEmpty) {
              _selectedRole = _roles.first;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // DEFAULT PERMISSION SEEDING
  // ---------------------------------------------------------------------
  Map<String, Map<String, Map<String, bool>>> _buildDefaultPermissions() {
    final Map<String, Map<String, Map<String, bool>>> data = {};
    for (final role in _roles) {
      final Map<String, Map<String, bool>> modulePerms = {};
      for (final module in _modules) {
        modulePerms[module] = _defaultActionsFor(role, module);
      }
      data[role] = modulePerms;
    }
    return data;
  }

  Map<String, bool> _defaultActionsFor(String role, String module) {
    bool v = false, c = false, e = false, d = false;

    switch (role) {
      case 'Administrator':
        v = c = e = d = true;
        break;

      case 'Program Manager':
        v = true;
        if (module != 'Users' && module != 'Settings' && module != 'Finance') {
          c = true;
          e = true;
        }
        break;

      case 'Data Officer':
        v = true;
        if (['Scholars', 'Schools', 'Sponsors', 'Academics', 'Attendance']
            .contains(module)) {
          c = true;
          e = true;
        }
        break;

      case 'Finance Officer':
        v = true;
        if (module == 'Finance') {
          c = true;
          e = true;
          d = true;
        }
        break;

      case 'Field Coordinator':
        v = true;
        if (['Scholars', 'Attendance'].contains(module)) {
          c = true;
          e = true;
        }
        break;

      case 'Volunteer':
        if (module != 'Users' && module != 'Settings' && module != 'Finance') {
          v = true;
        }
        break;
    }

    return {'view': v, 'create': c, 'edit': e, 'delete': d};
  }

  // ---------------------------------------------------------------------
  // DERIVED DATA
  // ---------------------------------------------------------------------
  List<String> get _filteredModules {
    if (_moduleSearch.trim().isEmpty) return _modules;
    final query = _moduleSearch.trim().toLowerCase();
    return _modules.where((m) => m.toLowerCase().contains(query)).toList();
  }

  int _grantedCount(String role) {
    int count = 0;
    for (final module in _modules) {
      for (final action in _actions) {
        if (_permissions[role]![module]![action] == true) count++;
      }
    }
    return count;
  }

  int get _totalPossible => _modules.length * _actions.length;

  bool _isModuleFullyGranted(String module) {
    return _actions
        .every((a) => _permissions[_selectedRole]![module]![a] == true);
  }

  bool _isModulePartiallyGranted(String module) {
    final anyTrue =
    _actions.any((a) => _permissions[_selectedRole]![module]![a] == true);
    return anyTrue && !_isModuleFullyGranted(module);
  }

  // ---------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------
  void _toggleAction(String module, String action, bool value) {
    setState(() {
      _permissions[_selectedRole]![module]![action] = value;
      _hasUnsavedChanges = true;
    });
  }

  void _toggleModuleAll(String module) {
    final full = _isModuleFullyGranted(module);
    setState(() {
      for (final action in _actions) {
        _permissions[_selectedRole]![module]![action] = !full;
      }
      _hasUnsavedChanges = true;
    });
  }

  void _selectAllModules() {
    setState(() {
      for (final module in _modules) {
        for (final action in _actions) {
          _permissions[_selectedRole]![module]![action] = true;
        }
      }
      _hasUnsavedChanges = true;
    });
  }

  void _clearAllModules() {
    setState(() {
      for (final module in _modules) {
        for (final action in _actions) {
          _permissions[_selectedRole]![module]![action] = false;
        }
      }
      _hasUnsavedChanges = true;
    });
  }

  void _saveChanges() {
    setState(() => _hasUnsavedChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Permissions saved for $_selectedRole"),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Administrator':
        return Icons.shield_rounded;
      case 'Program Manager':
        return Icons.supervisor_account_rounded;
      case 'Data Officer':
        return Icons.storage_rounded;
      case 'Finance Officer':
        return Icons.attach_money_rounded;
      case 'Field Coordinator':
        return Icons.map_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 260, child: _buildRolesPanel()),
                      VerticalDivider(width: 1, color: Colors.grey.shade200),
                      Expanded(child: _buildPermissionsPanel()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------- CLEAN HEADER ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.green, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "User Permissions",
                  style: TextStyle(
                    color: Color(0xFF4C3C32),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Configure module-level access for each role.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Text(
                    "Unsaved changes",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LEFT PANEL — ROLES LIST
  // ---------------------------------------------------------------------
  Widget _buildRolesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Text(
            "ROLES",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _roles.length,
            itemBuilder: (context, index) {
              final role = _roles[index];
              final isSelected = role == _selectedRole;
              final color = _roleColor(role);
              final granted = _grantedCount(role);
              final percent = granted / _totalPossible;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedRole = role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.09) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_roleIcon(role), size: 16, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                role,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.8,
                                  fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "$granted / $_totalPossible permissions",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // RIGHT PANEL — PERMISSIONS MATRIX
  // ---------------------------------------------------------------------
  Widget _buildPermissionsPanel() {
    final modules = _filteredModules;
    final color = _roleColor(_selectedRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Icon(_roleIcon(_selectedRole), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$_selectedRole Access",
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _selectAllModules,
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text("Select All", style: TextStyle(fontSize: 12.5)),
                style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
              ),
              TextButton.icon(
                onPressed: _clearAllModules,
                icon: const Icon(Icons.remove_done_rounded, size: 16),
                label: const Text("Clear All", style: TextStyle(fontSize: 12.5)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _hasUnsavedChanges ? _saveChanges : null,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: TextField(
            onChanged: (val) => setState(() => _moduleSearch = val),
            decoration: InputDecoration(
              hintText: "Search modules...",
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
          child: modules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: modules.length,
            itemBuilder: (context, index) =>
                _buildModuleCard(modules[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text("No modules match your search",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MODULE PERMISSION CARD
  // ---------------------------------------------------------------------
  Widget _buildModuleCard(String module) {
    final perms = _permissions[_selectedRole]![module]!;
    final grantedInModule = perms.values.where((v) => v).length;
    final fullyGranted = _isModuleFullyGranted(module);
    final partiallyGranted = _isModulePartiallyGranted(module);
    final color = _roleColor(_selectedRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fullyGranted
              ? color.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => _toggleModuleAll(module),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: fullyGranted
                        ? color
                        : (partiallyGranted
                        ? color.withValues(alpha: 0.25)
                        : Colors.transparent),
                    border: Border.all(
                      color: fullyGranted || partiallyGranted
                          ? color
                          : Colors.grey.shade400,
                      width: 1.4,
                    ),
                  ),
                  child: fullyGranted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : (partiallyGranted
                      ? Icon(Icons.remove, size: 14, color: color)
                      : null),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _moduleIcons[module] ?? Icons.widgets_outlined,
                  size: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  module,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$grantedInModule/${_actions.length}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _actions.map((action) {
              final isLast = action == _actions.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10),
                  child: _buildActionToggle(module, action, perms[action] ?? false, color),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToggle(
      String module, String action, bool value, Color roleColor) {
    return InkWell(
      onTap: () => _toggleAction(module, action, !value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: value ? roleColor.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? roleColor.withValues(alpha: 0.35) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _actionIcons[action],
              size: 16,
              color: value ? roleColor : Colors.grey.shade400,
            ),
            const SizedBox(height: 5),
            Text(
              _actionLabels[action] ?? action,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: value ? roleColor : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: value,
                onChanged: (val) => _toggleAction(module, action, val),
                activeThumbColor: roleColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}