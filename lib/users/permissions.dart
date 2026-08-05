import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class PermissionsComponent extends StatefulWidget {
  const PermissionsComponent({super.key});

  @override
  State<PermissionsComponent> createState() => _PermissionsComponentState();
}

class _PermissionsComponentState extends State<PermissionsComponent> {
  List<dynamic> _rolesData = [];
  List<dynamic> _permissionGroups = [];
  Map<String, List<String>> _rolePermissions = {}; // roleId -> list of permission strings
  
  String? _selectedRoleId;
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAllRoles(),
        ApiService.getPermissionGroups(),
      ]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final roles = results[0].data['data'] as List;
        final groups = results[1].data['data'] as List;

        if (mounted) {
          setState(() {
            _rolesData = roles;
            _permissionGroups = groups;
            
            _rolePermissions.clear();
            for (var role in roles) {
              final id = role['id'].toString();
              final List<dynamic> perms = role['permissions'] ?? [];
              _rolePermissions[id] = perms.map((e) => e.toString()).toList();
            }

            if (_rolesData.isNotEmpty) {
              _selectedRoleId = _rolesData.first['id'].toString();
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching permissions data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasPermission(String roleId, String permId) {
    return _rolePermissions[roleId]?.contains(permId) ?? false;
  }

  void _togglePermission(String roleId, String permId) {
    setState(() {
      if (_rolePermissions[roleId]!.contains(permId)) {
        _rolePermissions[roleId]!.remove(permId);
      } else {
        _rolePermissions[roleId]!.add(permId);
      }
    });
  }

  Future<void> _savePermissions() async {
    if (_selectedRoleId == null) return;

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.updateRolePermissions(
        _selectedRoleId!, 
        _rolePermissions[_selectedRoleId]!
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permissions updated successfully."), backgroundColor: kBrandOlive),
        );
      }
    } catch (e) {
      debugPrint('Error saving permissions: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 300, child: _buildRolesList()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildPermissionsMatrix()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.admin_panel_settings_rounded, color: kBrandOlive, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Role Permissions Governance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text("Define modular access control and functional boundaries for each user role.", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePermissions,
            icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.verified_user_rounded, size: 16),
            label: const Text("SYNC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: "Filter roles...",
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _rolesData.length,
            itemBuilder: (context, index) {
              final role = _rolesData[index];
              final isSelected = _selectedRoleId == role['id'].toString();
              if (_searchQuery.isNotEmpty && !role['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
                return const SizedBox();
              }

              return ListTile(
                selected: isSelected,
                selectedTileColor: kBrandOlive.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: kBrandBrown.withOpacity(0.1),
                  child: Icon(Icons.security, size: 18, color: isSelected ? kBrandOlive : kBrandBrown),
                ),
                title: Text(role['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? kBrandOlive : kBrandBrown)),
                subtitle: Text("${_rolePermissions[role['id'].toString()]?.length ?? 0} active permissions", style: const TextStyle(fontSize: 11)),
                onTap: () => setState(() => _selectedRoleId = role['id'].toString()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsMatrix() {
    if (_selectedRoleId == null) return const Center(child: Text("Select a role to manage permissions"));
    
    final selectedRole = _rolesData.firstWhere((r) => r['id'].toString() == _selectedRoleId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Permissions for: ${selectedRole['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
              const Spacer(),
              if (selectedRole['name'] == 'Administrator')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
                  child: const Text("FULL SYSTEM BYPASS ENABLED", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ..._permissionGroups.map((group) => _buildPermissionGroup(group)).toList(),
        ],
      ),
    );
  }

  Widget _buildPermissionGroup(dynamic group) {
    final String groupName = group['name'];
    final List<dynamic> perms = group['permissions'];

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(groupName.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 1.5)),
              const SizedBox(width: 16),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: perms.length,
            itemBuilder: (context, index) {
              final perm = perms[index];
              final bool isEnabled = _hasPermission(_selectedRoleId!, perm['id']);
              final bool isAdmin = _rolesData.firstWhere((r) => r['id'].toString() == _selectedRoleId)['name'] == 'Administrator';

              return InkWell(
                onTap: isAdmin ? null : () => _togglePermission(_selectedRoleId!, perm['id']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isEnabled ? kBrandOlive.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isEnabled ? kBrandOlive.withOpacity(0.3) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Checkbox(
                          value: isEnabled || isAdmin,
                          onChanged: isAdmin ? null : (v) => _togglePermission(_selectedRoleId!, perm['id']),
                          activeColor: kBrandOlive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(perm['label'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isEnabled || isAdmin ? kBrandBrown : Colors.grey))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
