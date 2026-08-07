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
      return const SizedBox.shrink();
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(isMobile),
          const Divider(height: 1),
          Expanded(
            child: isMobile 
              ? _buildMobileLayout()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 300, child: _buildRolesList()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildPermissionsMatrix(isMobile)),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(color: Colors.grey.shade50),
          child: _buildRolesList(isMobile: true),
        ),
        const Divider(height: 1),
        Expanded(child: _buildPermissionsMatrix(true)),
      ],
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Permissions", style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePermissions,
            icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(Icons.verified_user_rounded, size: 14),
            label: Text(isMobile ? "SYNC" : "SYNC CHANGES", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList({bool isMobile = false}) {
    return Column(
      children: [
        if (!isMobile)
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
            scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
            itemCount: _rolesData.length,
            itemBuilder: (context, index) {
              final role = _rolesData[index];
              final isSelected = _selectedRoleId == role['id'].toString();
              if (!isMobile && _searchQuery.isNotEmpty && !role['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
                return const SizedBox();
              }

              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedRoleId = role['id'].toString()),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? kBrandOlive.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? kBrandOlive : Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 18, color: isSelected ? kBrandOlive : kBrandBrown),
                          const SizedBox(height: 8),
                          Text(role['name'], 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? kBrandOlive : kBrandBrown),
                            overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListTile(
                selected: isSelected,
                selectedTileColor: kBrandOlive.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: kBrandBrown.withOpacity(0.1),
                  child: Icon(Icons.security, size: 18, color: isSelected ? kBrandOlive : kBrandBrown),
                ),
                title: Text(role['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? kBrandOlive : kBrandBrown)),
                subtitle: Text("${_rolePermissions[role['id'].toString()]?.length ?? 0} active perms", style: const TextStyle(fontSize: 11)),
                onTap: () => setState(() => _selectedRoleId = role['id'].toString()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsMatrix(bool isMobile) {
    if (_selectedRoleId == null) return const Center(child: Text("Select a role"));
    
    final selectedRole = _rolesData.firstWhere((r) => r['id'].toString() == _selectedRoleId);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text("Scope for: ${selectedRole['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown))),
              if (selectedRole['name'] == 'Administrator')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
                  child: const Text("ADMIN BYPASS", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 9)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ..._permissionGroups.map((group) => _buildPermissionGroup(group, isMobile)).toList(),
        ],
      ),
    );
  }

  Widget _buildPermissionGroup(dynamic group, bool isMobile) {
    final String groupName = group['name'];
    final List<dynamic> perms = group['permissions'];

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(groupName.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 1.5)),
              const SizedBox(width: 16),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              childAspectRatio: isMobile ? 6 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isEnabled ? kBrandOlive.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isEnabled ? kBrandOlive.withOpacity(0.3) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.7,
                        child: Checkbox(
                          value: isEnabled || isAdmin,
                          onChanged: isAdmin ? null : (v) => _togglePermission(_selectedRoleId!, perm['id']),
                          activeColor: kBrandOlive,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(perm['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isEnabled || isAdmin ? kBrandBrown : Colors.grey))),
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
