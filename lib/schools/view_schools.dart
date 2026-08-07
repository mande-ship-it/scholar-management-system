import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import '../services/file_download_service.dart';
import '../widgets/custom_loaders.dart';
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
      barrierColor: Colors.black.withOpacity(0.5),
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
      height: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          _buildPortalToolbar(isMobile),
          Expanded(
            child: _isLoading 
                ? BeautifulLoader(isOverlay: false, message: "Synchronizing Registry...")
                : _buildPortalRegistryList(filtered, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
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
                const Text(
                  "INSTITUTIONAL DIRECTORY",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9AB334),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.forcedLevel != null 
                    ? "${widget.forcedLevel} Registry"
                    : "Central Institutional Registry",
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF4C3C32), 
                    letterSpacing: -0.5
                  ),
                ),
              ],
            ),
          ),
          if (!widget.hideRegistration && PermissionService.hasPermission('schools.create'))
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
              label: const Text("REGISTER INSTITUTION"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3C32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortalToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: isMobile
          ? Column(
              children: [
                _portalCompactSearchField(true),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (widget.forcedLevel == null)
                        _portalCompactDropdown("Type", _selectedLevel, _schoolLevels, (v) => setState(() => _selectedLevel = v!)),
                      if (widget.forcedLevel == null) const SizedBox(width: 8),
                      _portalCompactDropdown("Region", _selectedRegion, _regions, (v) => setState(() => _selectedRegion = v!)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                _portalCompactSearchField(false),
                const SizedBox(width: 16),
                if (widget.forcedLevel == null) ...[
                  SizedBox(
                    width: 220,
                    child: _portalCompactDropdown("Institution Level", _selectedLevel, _schoolLevels, (v) => setState(() => _selectedLevel = v!)),
                  ),
                  const SizedBox(width: 12),
                ],
                SizedBox(
                  width: 180,
                  child: _portalCompactDropdown("Location Region", _selectedRegion, _regions, (v) => setState(() => _selectedRegion = v!)),
                ),
                const Spacer(),
                _miniStat(Icons.domain_rounded, "${_getFilteredSchools().length} Registered Institutions"),
              ],
            ),
    );
  }

  Widget _portalCompactSearchField(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      height: 44,
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          hintText: "Search name, code, district...",
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _portalCompactDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF4C3C32).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4C3C32)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4C3C32))),
        ],
      ),
    );
  }

  Widget _buildPortalRegistryList(List<Map<String, dynamic>> schools, bool isMobile) {
    if (schools.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      itemCount: schools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildPortalActionRow(schools[index], isMobile),
    );
  }

  Widget _buildPortalActionRow(Map<String, dynamic> s, bool isMobile) {
    final bool isActive = s['status'] == 'Active';
    final bool isUni = s['level']!.toLowerCase().contains('university') || s['level']!.toLowerCase().contains('tertiary');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSchoolProfile(s),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (isUni ? Color(0xFF4C3C32) : Color(0xFF9AB334)).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: (isUni ? Color(0xFF4C3C32) : Color(0xFF9AB334)).withOpacity(0.2), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(isUni ? Icons.account_balance_rounded : Icons.school_rounded, color: isUni ? const Color(0xFF4C3C32) : const Color(0xFF9AB334), size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name']!.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF4C3C32), letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.qr_code_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(s['code']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(s['district']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['level']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4C3C32))),
                        const SizedBox(height: 4),
                        Text(s['region']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Color(0xFF9AB334).withOpacity(0.1) : Color(0xFFE05B1C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s['status']!.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? const Color(0xFF9AB334) : const Color(0xFFE05B1C), 
                          fontWeight: FontWeight.w900, 
                          fontSize: 9,
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
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
    return Container(
      color: Colors.white, // Toolbar stays white
      child: Column(
        children: [
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
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search institutions by name or district...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, bool isMobile) {
    return Container(
      width: isMobile ? null : 180,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(20)),
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
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 20),
      itemCount: schools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final s = schools[index];
        final bool isUni = s['level']!.toLowerCase().contains('university') || s['level']!.toLowerCase().contains('tertiary');
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openSchoolProfile(s),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: (isUni ? kBrandBrown : kBrandOlive).withOpacity(0.1),
                      child: Icon(isUni ? Icons.account_balance_rounded : Icons.school_rounded, color: isUni ? kBrandBrown : kBrandOlive, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrandBrown)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _miniBadge(s['code']!, Colors.grey.shade100, Colors.grey.shade700),
                              _miniBadge(s['district']!.toUpperCase(), kBrandOlive.withOpacity(0.1), kBrandOlive),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: s['status'] == 'Active' ? Colors.green : Colors.red),
                              ),
                              Text(s['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s['status'] == 'Active' ? Colors.green : Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
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
