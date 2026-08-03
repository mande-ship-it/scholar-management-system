import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import '../services/file_download_service.dart';
import 'school_dialogs.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class ViewSchoolsComponent extends StatefulWidget {
  final VoidCallback? onRegisterSchool;
  const ViewSchoolsComponent({super.key, this.onRegisterSchool});

  @override
  State<ViewSchoolsComponent> createState() => _ViewSchoolsComponentState();
}

class _ViewSchoolsComponentState extends State<ViewSchoolsComponent> {
  String _searchQuery = '';
  String _selectedLevel = 'All';
  String _selectedRegion = 'All';
  bool _isLoading = true;
  String _userRole = 'User';

  List<Map<String, dynamic>> _allSchools = [];

  @override
  void initState() {
    super.initState();
    _fetchSchools();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _userRole = data['role_name'] ?? 'User';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSchools() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        if (mounted) {
          setState(() {
            _allSchools = data.map((s) => {
              'id': s['id'].toString(),
              'name': s['name']?.toString() ?? '',
              'code': s['code']?.toString() ?? '',
              'level': s['level']?.toString() ?? '',
              'type': s['type']?.toString() ?? '',
              'genderPolicy': s['gender_policy']?.toString() ?? '',
              'region': s['region']?.toString() ?? '',
              'district': s['district']?.toString() ?? '',
              'address': s['address']?.toString() ?? '',
              'postal': s['postal_address']?.toString() ?? '',
              'phone': s['phone']?.toString() ?? '',
              'altPhone': s['alt_phone']?.toString() ?? '',
              'email': s['email']?.toString() ?? '',
              'website': s['website']?.toString() ?? '',
              'adminName': s['admin_name']?.toString() ?? '',
              'adminRole': s['admin_role']?.toString() ?? '',
              'adminPhone': s['admin_phone']?.toString() ?? '',
              'adminEmail': s['admin_email']?.toString() ?? '',
              'description': s['description']?.toString() ?? '',
              'notes': s['notes']?.toString() ?? '',
              'status': s['status']?.toString() ?? 'Active',
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> _schoolLevels = [
    'All',
    'Primary School',
    'Secondary School',
    'High School',
    'Tertiary / University',
    'Vocational Training Center',
  ];

  final List<String> _regions = [
    'All',
    'Northern Region',
    'Central Region',
    'Southern Region',
  ];

  void _toggleSchoolStatus(Map<String, dynamic> school) async {
    final bool wasActive = school['status'] == 'Active';
    try {
      final response = await ApiService.toggleSchoolStatus(school['id']!);
      if (response.statusCode == 200) {
        setState(() {
          school['status'] = wasActive ? 'Inactive' : 'Active';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasActive ? "${school['name']} deactivated." : "${school['name']} activated."),
            backgroundColor: wasActive ? kBrandOrange : kBrandOlive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling school status: $e');
    }
  }

  void _deleteSchool(Map<String, dynamic> school) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Institution"),
        content: Text("Delete ${school['name']}? This action is permanent."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("DELETE")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.deleteSchool(school['id']!);
        if (response.statusCode == 200) {
          setState(() => _allSchools.removeWhere((s) => s['id'] == school['id']));
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted."), backgroundColor: Colors.red));
        }
      } catch (e) {
        debugPrint('Delete Error: $e');
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredSchools() {
    return _allSchools.where((school) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = school['name']!.toLowerCase().contains(query) ||
          school['code']!.toLowerCase().contains(query) ||
          school['district']!.toLowerCase().contains(query);
      final matchesLevel = _selectedLevel == 'All' || school['level'] == _selectedLevel;
      final matchesRegion = _selectedRegion == 'All' || school['region'] == _selectedRegion;
      return matchesSearch && matchesLevel && matchesRegion;
    }).toList();
  }

  void _openSchoolProfile(Map<String, dynamic> school) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Profile",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * curved.value),
            child: SchoolProfileDialog(
              school: school,
              onToggleStatus: () => _toggleSchoolStatus(school),
              onEdit: () async {
                Navigator.pop(ctx);
                final updated = await showDialog<Map<String, dynamic>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (editContext) => EditSchoolDialog(school: school),
                );
                if (updated != null) {
                  setState(() {
                    final idx = _allSchools.indexWhere((s) => s['id'] == school['id']);
                    if (idx != -1) _allSchools[idx] = updated;
                  });
                  _openSchoolProfile(updated);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredSchools();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(),
          _buildToolbar(),
          Expanded(
            child: _buildRegistryList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment_rounded, color: kBrandOlive, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Institutional Registry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                SizedBox(height: 2),
                Text('Regional distribution of partner secondary and tertiary institutions.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (_userRole == 'Administrator' || PermissionService.hasPermission('schools.create'))
            ElevatedButton.icon(
              onPressed: () async {
                if (widget.onRegisterSchool != null) {
                  widget.onRegisterSchool!();
                } else {
                  final result = await Navigator.pushNamed(context, '/schools/register');
                  if (result == true) _fetchSchools();
                }
              },
              icon: const Icon(Icons.add_business_rounded, size: 18),
              label: const Text("REGISTER SCHOOL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Column(
      children: [
        const Divider(indent: 24, endIndent: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search institutions by name or district...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              _filterDropdown("Level", _selectedLevel, _schoolLevels, (v) => setState(() => _selectedLevel = v!)),
              const SizedBox(width: 12),
              _filterDropdown("Region", _selectedRegion, _regions, (v) => setState(() => _selectedRegion = v!)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: kBrandBrown),
                onPressed: _isLoading ? null : _fetchSchools,
                tooltip: 'Refresh Registry',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: kBrandBrown, fontWeight: FontWeight.w600),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRegistryList(List<Map<String, dynamic>> schools) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    if (schools.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: schools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = schools[index];
        final bool isUni = s['level']!.toLowerCase().contains('university') || s['level']!.toLowerCase().contains('tertiary');
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: (isUni ? kBrandBrown : kBrandOlive).withValues(alpha: 0.1),
              child: Icon(isUni ? Icons.account_balance_rounded : Icons.school_rounded, color: isUni ? kBrandBrown : kBrandOlive),
            ),
            title: Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kBrandBrown)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  _miniBadge(s['code']!, Colors.grey.shade100, Colors.grey.shade700),
                  const SizedBox(width: 8),
                  _miniBadge(s['district']!.toUpperCase(), kBrandOlive.withValues(alpha: 0.1), kBrandOlive),
                  const SizedBox(width: 12),
                  Text(s['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s['status'] == 'Active' ? Colors.green : Colors.red)),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (PermissionService.hasPermission('schools.edit'))
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(context: context, builder: (c) => EditSchoolDialog(school: s));
                      if (result != null) _fetchSchools();
                    },
                  ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => _openSchoolProfile(s),
          ),
        );
      },
    );
  }

  Widget _miniBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apartment_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text("No institutions found", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
