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
  final String? forcedLevel;
  final bool hideRegistration;
  const ViewSchoolsComponent({super.key, this.onRegisterSchool, this.forcedLevel, this.hideRegistration = false});

  @override
  State<ViewSchoolsComponent> createState() => _ViewSchoolsComponentState();
}

class _ViewSchoolsComponentState extends State<ViewSchoolsComponent> {
  String _searchQuery = '';
  late String _selectedLevel;
  String _selectedRegion = 'All';
  bool _isLoading = true;
  String _userRole = 'User';

  List<Map<String, dynamic>> _allSchools = [];

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.forcedLevel ?? 'All';
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
        border: isMobile ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isMobile ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildExecutiveHeader(isMobile),
          _buildToolbar(isMobile),
          Expanded(
            child: _buildRegistryList(filtered, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 16 : 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrandBrown.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment_rounded, color: kBrandBrown, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Institutional Registry",
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text("Management of partner secondary schools and tertiary institutions.",
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!widget.hideRegistration && (_userRole == 'Administrator' || PermissionService.hasPermission('schools.create')))
            ElevatedButton.icon(
              onPressed: () async {
                if (widget.onRegisterSchool != null) {
                  widget.onRegisterSchool!();
                } else {
                  final result = await Navigator.pushNamed(context, '/schools/register');
                  if (result == true) _fetchSchools();
                }
              },
              icon: const Icon(Icons.add_business_rounded, size: 16),
              label: Text(isMobile ? "ADD" : "REGISTER", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Column(
      children: [
        const Divider(indent: 24, endIndent: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: isMobile 
            ? Column(
                children: [
                  _searchField(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.forcedLevel == null)
                        Expanded(child: _filterDropdown("Level", _selectedLevel, _schoolLevels, (v) => setState(() => _selectedLevel = v!), isMobile)),
                      if (widget.forcedLevel == null) const SizedBox(width: 8),
                      Expanded(child: _filterDropdown("Region", _selectedRegion, _regions, (v) => setState(() => _selectedRegion = v!), isMobile)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.sync_rounded, color: kBrandBrown),
                        onPressed: _isLoading ? null : _fetchSchools,
                        tooltip: 'Refresh Registry',
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _searchField(),
                  ),
                  const SizedBox(width: 16),
                  if (widget.forcedLevel == null)
                    _filterDropdown("Level", _selectedLevel, _schoolLevels, (v) => setState(() => _selectedLevel = v!), isMobile),
                  const SizedBox(width: 12),
                  _filterDropdown("Region", _selectedRegion, _regions, (v) => setState(() => _selectedRegion = v!), isMobile),
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

  Widget _searchField() {
    return TextField(
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
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, bool isMobile) {
    return Container(
      width: isMobile ? null : 180,
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

  Widget _buildRegistryList(List<Map<String, dynamic>> schools, bool isMobile) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    if (schools.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24, vertical: 12),
      itemCount: schools.length,
      separatorBuilder: (_, __) => isMobile ? const Divider(height: 1, thickness: 1) : const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = schools[index];
        final bool isUni = s['level']!.toLowerCase().contains('university') || s['level']!.toLowerCase().contains('tertiary');
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(12),
            border: isMobile ? null : Border.all(color: Colors.grey.shade100),
            boxShadow: isMobile ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 16, vertical: isMobile ? 8 : 16),
            leading: CircleAvatar(
              radius: isMobile ? 20 : 24,
              backgroundColor: (isUni ? kBrandBrown : kBrandOlive).withValues(alpha: 0.1),
              child: Icon(isUni ? Icons.account_balance_rounded : Icons.school_rounded, color: isUni ? kBrandBrown : kBrandOlive, size: isMobile ? 20 : 24),
            ),
            title: Text(s['name']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15, color: kBrandBrown)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _miniBadge(s['code']!, Colors.grey.shade100, Colors.grey.shade700),
                  _miniBadge(s['district']!.toUpperCase(), kBrandOlive.withValues(alpha: 0.1), kBrandOlive),
                  Text(s['status']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: s['status'] == 'Active' ? Colors.green : Colors.red)),
                ],
              ),
            ),
            trailing: isMobile
              ? const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20)
              : Row(
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
