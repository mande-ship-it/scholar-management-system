import 'package:flutter/material.dart';

// ============================================================
// Shared Brand Color Palette
// ------------------------------------------------------------
// NOTE: these are the exact same constants used on the
// View Scholars page. If both files live in the same Flutter
// project/package, move this block into its own file (e.g.
// `lib/theme/brand_colors.dart`) and import it from both
// view_schools.dart and view_scholars.dart instead of declaring
// it twice — Dart will throw a duplicate-definition error if two
// libraries in the same import scope both declare top-level
// consts with the same name.
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

// ============================================================
// VIEW SCHOOLS COMPONENT (registry table + profile pop-up)
// ============================================================

class ViewSchoolsComponent extends StatefulWidget {
  const ViewSchoolsComponent({super.key});

  @override
  State<ViewSchoolsComponent> createState() => _ViewSchoolsComponentState();
}

class _ViewSchoolsComponentState extends State<ViewSchoolsComponent> {
  String _searchQuery = '';
  String _selectedLevel = 'All';
  String _selectedRegion = 'All';

  final List<Map<String, String>> _allSchools = [
    {
      'name': 'Mzuzu Government Secondary School',
      'code': 'SCH-001',
      'level': 'Secondary School',
      'type': 'Public / Government',
      'genderPolicy': 'Co-educational (Mixed)',
      'region': 'Northern Region',
      'district': 'Mzimba',
      'address': 'Off M1 Road, Mzuzu',
      'phone': '+265 1 311 234',
      'altPhone': '+265 888 123 456',
      'email': 'info@mzuzugovsec.edu.mw',
      'postal': 'P.O. Box 201, Mzuzu',
      'website': 'www.mzuzugovsec.edu.mw',
      'adminName': 'Mr. Charles Nyirenda',
      'adminRole': 'Headteacher',
      'adminPhone': '+265 999 456 789',
      'adminEmail': 'cnyirenda@mzuzugovsec.edu.mw',
      'description': 'One of the oldest government secondary schools in the Northern Region of Malawi.',
      'notes': 'Partner school since 2018. Active scholar support programs in place.',
      'status': 'Active',
      'date': '2026-07-09',
    },
    {
      'name': 'Likuni Boys Secondary School',
      'code': 'SCH-002',
      'level': 'Secondary School',
      'type': 'Mission / Religious School',
      'genderPolicy': 'Boys Only',
      'region': 'Central Region',
      'district': 'Lilongwe',
      'address': 'Likuni, Lilongwe',
      'phone': '+265 1 762 555',
      'altPhone': '+265 999 987 654',
      'email': 'administration@likuniboys.org',
      'postal': 'P.O. Box 110, Lilongwe',
      'website': 'www.likuniboys.org',
      'adminName': 'Brother James Phiri',
      'adminRole': 'Principal',
      'adminPhone': '+265 888 456 123',
      'adminEmail': 'principal@likuniboys.org',
      'description': 'A prestigious Catholic national secondary boarding school for boys, run by the Marist Brothers.',
      'notes': 'Famous for academic excellence and discipline.',
      'status': 'Active',
      'date': '2026-07-09',
    },
    {
      'name': 'University of Malawi (UNIMA)',
      'code': 'SCH-003',
      'level': 'Tertiary / University',
      'type': 'Public / Government',
      'genderPolicy': 'Co-educational (Mixed)',
      'region': 'Southern Region',
      'district': 'Zomba',
      'address': 'Chirunga Campus, Zomba',
      'phone': '+265 1 524 222',
      'altPhone': '+265 881 234 567',
      'email': 'registrar@unima.ac.mw',
      'postal': 'P.O. Box 280, Zomba',
      'website': 'www.unima.ac.mw',
      'adminName': 'Prof. Samson Sajidu',
      'adminRole': 'Vice Chancellor',
      'adminPhone': '+265 999 111 222',
      'adminEmail': 'vc@unima.ac.mw',
      'description': 'The premier public university in Malawi, located in Zomba, offering a wide range of undergraduate and postgraduate courses.',
      'notes': 'Key tertiary partner for scholarship program graduates.',
      'status': 'Active',
      'date': '2026-07-09',
    },
    {
      'name': 'Lilongwe Girls Secondary School',
      'code': 'SCH-004',
      'level': 'Secondary School',
      'type': 'Public / Government',
      'genderPolicy': 'Girls Only',
      'region': 'Central Region',
      'district': 'Lilongwe',
      'address': 'Area 2, Lilongwe',
      'phone': '+265 1 753 111',
      'altPhone': '',
      'email': 'lilongwegirlssec@gmail.com',
      'postal': 'Private Bag 3, Lilongwe',
      'website': '',
      'adminName': 'Mrs. Grace Banda',
      'adminRole': 'Headmistress',
      'adminPhone': '+265 992 345 678',
      'adminEmail': 'gbanda@lilongwegirls.edu.mw',
      'description': 'A leading national girls boarding secondary school located in the heart of Lilongwe.',
      'notes': 'Partner school since the inception of AGE Africa.',
      'status': 'Active',
      'date': '2026-07-09',
    },
    {
      'name': 'Karonga Girls Secondary School',
      'code': 'SCH-005',
      'level': 'Secondary School',
      'type': 'Grant-Aided',
      'genderPolicy': 'Girls Only',
      'region': 'Northern Region',
      'district': 'Karonga',
      'address': 'Karonga Boma',
      'phone': '+265 1 362 222',
      'altPhone': '',
      'email': 'head@karongagirls.edu.mw',
      'postal': 'P.O. Box 45, Karonga',
      'website': 'www.karongagirls.edu.mw',
      'adminName': 'Sister Beatrice Chirwa',
      'adminRole': 'Headmistress',
      'adminPhone': '+265 888 789 456',
      'adminEmail': 'bchirwa@karongagirls.edu.mw',
      'description': 'A prominent grant-aided secondary boarding school for girls in Karonga district.',
      'notes': 'Strong focus on STEM subjects for girls.',
      'status': 'Active',
      'date': '2026-07-09',
    },
  ];

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

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedLevel = 'All';
      _selectedRegion = 'All';
    });
  }

  String _initialsOf(String name) {
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  // ---------------------------------------------------------------------
  // Activate / Deactivate a school
  // ---------------------------------------------------------------------
  void _toggleSchoolStatus(Map<String, String> school) {
    final bool wasActive = school['status'] == 'Active';
    setState(() {
      school['status'] = wasActive ? 'Inactive' : 'Active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasActive
              ? "${school['name']} has been deactivated."
              : "${school['name']} has been activated.",
        ),
        backgroundColor: wasActive ? kBrandOrange : kBrandOlive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Opens the professional profile pop-up for a given school.
  // From there the user can launch the Edit pop-up, and any saved
  // changes are written back into _allSchools.
  void _openSchoolProfile(Map<String, String> school) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "School Profile",
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
                Navigator.pop(ctx); // close profile pop-up first

                final updatedSchool = await showDialog<Map<String, String>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (editContext) => EditSchoolDialog(school: school),
                );

                if (updatedSchool != null) {
                  setState(() {
                    final idx = _allSchools
                        .indexWhere((s) => s['code'] == school['code']);
                    if (idx != -1) {
                      _allSchools[idx] = updatedSchool;
                    }
                  });
                  // Re-open the profile pop-up with the freshly saved details.
                  _openSchoolProfile(updatedSchool);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter the mock list of schools
    final filteredSchools = _allSchools.where((school) {
      final matchesSearch = school['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school['code']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school['district']!.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesLevel = _selectedLevel == 'All' || school['level'] == _selectedLevel;
      final matchesRegion = _selectedRegion == 'All' || school['region'] == _selectedRegion;

      return matchesSearch && matchesLevel && matchesRegion;
    }).toList();

    final activeCount = _allSchools.where((s) => s['status'] == 'Active').length;
    final tertiaryCount = _allSchools.where((s) => s['level'] == 'Tertiary / University').length;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F6F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Gradient Header (compact) — matches Scholars Registry header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kBrandBrown, kBrandOlive],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Schools Registry",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${filteredSchools.length} of ${_allSchools.length} schools",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _miniStat(Icons.check_circle_rounded, "$activeCount active", kBrandCream),
                    _miniStat(Icons.account_balance_rounded, "$tertiaryCount tertiary", kBrandCream),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _resetFilters,
                    tooltip: "Reset Filters",
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_business, color: kBrandBrown, size: 18),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.pushNamed(context, '/schools/register');
                    },
                    tooltip: "Register School",
                  ),
                ),
              ],
            ),
          ),

          // 2. Search & Filter Bar — matches Scholars filter card
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Search by name, code or district",
                        hintText: "Enter search text...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedLevel,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Education Level",
                        prefixIcon: const Icon(Icons.layers, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _schoolLevels.map((l) {
                        return DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLevel = val ?? 'All';
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedRegion,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Region",
                        prefixIcon: const Icon(Icons.map, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _regions.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRegion = val ?? 'All';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. School List Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: filteredSchools.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No Schools Found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try loosening your filters or clearing search text.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
                    : Scrollbar(
                  child: ListView.separated(
                    itemCount: filteredSchools.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final school = filteredSchools[index];
                      final isActive = school['status'] == 'Active';
                      final isTertiary = school['level'] == 'Tertiary / University';

                      return Container(
                        color: index.isEven ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTertiary
                                  ? kBrandBrown.withValues(alpha: 0.10)
                                  : kBrandOlive.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTertiary ? Icons.account_balance : Icons.school,
                              color: isTertiary ? kBrandBrown : kBrandOlive,
                            ),
                          ),
                          title: Text(
                            school['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5, color: Colors.black87),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text("Code: ${school['code']!}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isTertiary
                                        ? kBrandBrown.withValues(alpha: 0.08)
                                        : kBrandOrange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    school['level']!,
                                    style: TextStyle(
                                      color: isTertiary ? kBrandBrown : kBrandOrange,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                                Text(school['district']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? kBrandOlive.withValues(alpha: 0.12) : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? kBrandOlive.withValues(alpha: 0.4) : Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive ? kBrandOlive : Colors.red.shade600,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      school['status']!,
                                      style: TextStyle(
                                        color: isActive ? kBrandOlive : Colors.red.shade900,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                  color: isActive ? kBrandOlive : Colors.grey.shade500,
                                  size: 26,
                                ),
                                onPressed: () => _toggleSchoolStatus(school),
                                tooltip: isActive ? "Deactivate" : "Activate",
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: kBrandBrown),
                                onPressed: () async {
                                  final updatedSchool = await showDialog<Map<String, String>>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (editContext) => EditSchoolDialog(school: school),
                                  );
                                  if (updatedSchool != null) {
                                    setState(() {
                                      final idx = _allSchools.indexWhere((s) => s['code'] == school['code']);
                                      if (idx != -1) {
                                        _allSchools[idx] = updatedSchool;
                                      }
                                    });
                                  }
                                },
                                tooltip: "Edit School",
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ],
                          ),
                          onTap: () => _openSchoolProfile(school),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// SCHOOL PROFILE POP-UP
// ============================================================

/// A professional, read-only pop-up dialog that displays full details
/// for a single school, styled to match the Scholar profile dialog.
/// Triggered by tapping a school in ViewSchoolsComponent.
class SchoolProfileDialog extends StatefulWidget {
  final Map<String, String> school;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const SchoolProfileDialog({
    super.key,
    required this.school,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  State<SchoolProfileDialog> createState() => _SchoolProfileDialogState();
}

class _SchoolProfileDialogState extends State<SchoolProfileDialog> {
  String _initialsOf(String name) {
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
        color: kBrandBrown,
      ),
    );
  }

  Widget _infoGrid(List<_SchoolInfoItem> items) {
    final visible = items.where((i) => i.value.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 380 ? 2 : 1;
        final itemWidth = columns == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: visible.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kBrandOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: kBrandOrange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _badge(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kBrandCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBrandOlive.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kBrandBrown),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: kBrandBrown, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.school;
    final isActive = school['status'] == 'Active';
    final isTertiary = school['level'] == 'Tertiary / University';
    final initials = _initialsOf(school['name'] ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------- Header ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kBrandBrown, kBrandOlive],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: initials.isNotEmpty
                          ? Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      )
                          : Icon(
                        isTertiary ? Icons.account_balance : Icons.school,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school['name'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            school['code'] ?? '',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              school['status'] ?? '',
                              style: TextStyle(
                                color: isActive ? kBrandOlive : Colors.red.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ],
                ),
              ),

              // ---------------- Body ----------------
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _badge(Icons.layers, school['level'] ?? ''),
                          _badge(Icons.account_balance, school['type'] ?? ''),
                          _badge(Icons.wc, school['genderPolicy'] ?? ''),
                        ],
                      ),
                      if ((school['description'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          school['description']!,
                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                        ),
                      ],
                      const SizedBox(height: 24),

                      _sectionTitle("Location"),
                      const SizedBox(height: 12),
                      _infoGrid([
                        _SchoolInfoItem(Icons.map, "Region", school['region'] ?? ''),
                        _SchoolInfoItem(Icons.my_location, "District", school['district'] ?? ''),
                        _SchoolInfoItem(Icons.home, "Address", school['address'] ?? ''),
                        _SchoolInfoItem(Icons.local_post_office, "Postal", school['postal'] ?? ''),
                      ]),
                      const SizedBox(height: 24),

                      _sectionTitle("School Contacts"),
                      const SizedBox(height: 12),
                      _infoGrid([
                        _SchoolInfoItem(Icons.phone, "Phone", school['phone'] ?? ''),
                        _SchoolInfoItem(Icons.phone_android, "Alt. Phone", school['altPhone'] ?? ''),
                        _SchoolInfoItem(Icons.email, "Email", school['email'] ?? ''),
                        _SchoolInfoItem(Icons.language, "Website", school['website'] ?? ''),
                      ]),
                      const SizedBox(height: 24),

                      _sectionTitle("Administrator"),
                      const SizedBox(height: 12),
                      _infoGrid([
                        _SchoolInfoItem(Icons.badge, "Name", school['adminName'] ?? ''),
                        _SchoolInfoItem(Icons.work, "Role", school['adminRole'] ?? ''),
                        _SchoolInfoItem(Icons.contact_phone, "Phone", school['adminPhone'] ?? ''),
                        _SchoolInfoItem(Icons.contact_mail, "Email", school['adminEmail'] ?? ''),
                      ]),

                      if ((school['notes'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle("Notes"),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            school['notes']!,
                            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, height: 1.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ---------------- Footer Actions ----------------
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onToggleStatus();
                          setState(() {}); // reflect new status immediately in this dialog
                        },
                        icon: Icon(
                          isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                          size: 20,
                          color: isActive ? kBrandOrange : kBrandOlive,
                        ),
                        label: Text(
                          isActive ? "Deactivate School" : "Activate School",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? kBrandOrange : kBrandOlive),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: (isActive ? kBrandOrange : kBrandOlive).withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text("Close"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text("Edit School"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: kBrandOlive,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchoolInfoItem {
  final IconData icon;
  final String label;
  final String value;

  _SchoolInfoItem(this.icon, this.label, this.value);
}


// ============================================================
// EDIT SCHOOL POP-UP
// ============================================================

/// A professional pop-up (modal) version of the Edit School form,
/// restyled with the shared brand palette.
/// Pass in the school's current data; on save it pops with the
/// updated Map<String, String> so the caller can update its state.
class EditSchoolDialog extends StatefulWidget {
  final Map<String, String> school;

  const EditSchoolDialog({super.key, required this.school});

  @override
  State<EditSchoolDialog> createState() => _EditSchoolDialogState();
}

class _EditSchoolDialogState extends State<EditSchoolDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _postalController;
  late TextEditingController _websiteController;
  late TextEditingController _adminNameController;
  late TextEditingController _adminRoleController;
  late TextEditingController _adminPhoneController;
  late TextEditingController _adminEmailController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String? _selectedLevel;
  String? _selectedType;
  String? _selectedGenderType;
  String? _selectedRegion;
  String? _selectedDistrict;
  String? _selectedStatus;

  final List<String> _schoolLevels = [
    'Primary School',
    'Secondary School',
    'High School',
    'Tertiary / University',
    'Vocational Training Center',
  ];

  final List<String> _schoolTypes = [
    'Public / Government',
    'Private',
    'Community Day (CDSS)',
    'Grant-Aided',
    'Mission / Religious School',
  ];

  final List<String> _genderTypes = [
    'Co-educational (Mixed)',
    'Boys Only',
    'Girls Only',
  ];

  final List<String> _regions = [
    'Northern Region',
    'Central Region',
    'Southern Region',
  ];

  final List<String> _statuses = ['Active', 'Inactive'];

  final Map<String, List<String>> _regionDistricts = {
    'Northern Region': [
      'Chitipa',
      'Karonga',
      'Likoma',
      'Mzimba',
      'Nkhata Bay',
      'Rumphi',
    ],
    'Central Region': [
      'Dedza',
      'Dowa',
      'Kasungu',
      'Lilongwe',
      'Mchinji',
      'Nkhotakota',
      'Ntcheu',
      'Ntchisi',
      'Salima',
    ],
    'Southern Region': [
      'Balaka',
      'Blantyre',
      'Chikwawa',
      'Chiradzulu',
      'Machinga',
      'Mangochi',
      'Mulanje',
      'Mwanza',
      'Neno',
      'Nsanje',
      'Phalombe',
      'Thyolo',
      'Zomba',
    ],
  };

  @override
  void initState() {
    super.initState();
    final args = widget.school;

    _nameController = TextEditingController(text: args['name'] ?? '');
    _codeController = TextEditingController(text: args['code'] ?? '');
    _addressController = TextEditingController(text: args['address'] ?? '');
    _phoneController = TextEditingController(text: args['phone'] ?? '');
    _altPhoneController = TextEditingController(text: args['altPhone'] ?? '');
    _emailController = TextEditingController(text: args['email'] ?? '');
    _postalController = TextEditingController(text: args['postal'] ?? '');
    _websiteController = TextEditingController(text: args['website'] ?? '');
    _adminNameController = TextEditingController(text: args['adminName'] ?? '');
    _adminRoleController = TextEditingController(text: args['adminRole'] ?? '');
    _adminPhoneController = TextEditingController(text: args['adminPhone'] ?? '');
    _adminEmailController = TextEditingController(text: args['adminEmail'] ?? '');
    _descriptionController = TextEditingController(text: args['description'] ?? '');
    _notesController = TextEditingController(text: args['notes'] ?? '');

    _selectedLevel = args['level'];
    if (_selectedLevel != null && !_schoolLevels.contains(_selectedLevel)) {
      _selectedLevel = null;
    }

    _selectedType = args['type'];
    if (_selectedType != null && !_schoolTypes.contains(_selectedType)) {
      _selectedType = null;
    }

    _selectedGenderType = args['genderPolicy'];
    if (_selectedGenderType != null && !_genderTypes.contains(_selectedGenderType)) {
      _selectedGenderType = null;
    }

    _selectedRegion = args['region'];
    if (_selectedRegion != null && !_regions.contains(_selectedRegion)) {
      _selectedRegion = null;
    }

    _selectedDistrict = args['district'];
    if (_selectedRegion != null && _selectedDistrict != null) {
      final dists = _regionDistricts[_selectedRegion] ?? [];
      if (!dists.contains(_selectedDistrict)) {
        _selectedDistrict = null;
      }
    }

    _selectedStatus = args['status'];
    if (_selectedStatus != null && !_statuses.contains(_selectedStatus)) {
      _selectedStatus = 'Active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _postalController.dispose();
    _websiteController.dispose();
    _adminNameController.dispose();
    _adminRoleController.dispose();
    _adminPhoneController.dispose();
    _adminEmailController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _activeDistricts {
    if (_selectedRegion == null) return [];
    return _regionDistricts[_selectedRegion] ?? [];
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedSchool = <String, String>{
        ...widget.school,
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'level': _selectedLevel ?? '',
        'type': _selectedType ?? '',
        'genderPolicy': _selectedGenderType ?? '',
        'region': _selectedRegion ?? '',
        'district': _selectedDistrict ?? '',
        'address': _addressController.text.trim(),
        'postal': _postalController.text.trim(),
        'phone': _phoneController.text.trim(),
        'altPhone': _altPhoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'adminName': _adminNameController.text.trim(),
        'adminRole': _adminRoleController.text.trim(),
        'adminPhone': _adminPhoneController.text.trim(),
        'adminEmail': _adminEmailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': _selectedStatus ?? widget.school['status'] ?? 'Active',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Changes to '${updatedSchool['name']}' (${updatedSchool['code']}) successfully saved!"),
          backgroundColor: kBrandOlive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, updatedSchool);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please correct the errors in the form."),
          backgroundColor: kBrandOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      enabled: enabled,
      isDense: true,
      filled: true,
      fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBrandOlive, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, color: kBrandOlive, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown),
            ),
          ],
        ),
        const Divider(height: 16, thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 780 ? screenWidth * 0.94 : 720.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBrandBrown, kBrandOlive],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Edit School Details",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Update details for ${widget.school['name'] ?? 'this school'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ),

            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: School Identity
                      _buildSectionHeader("School Identity Details", Icons.school),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: _fieldDecoration(label: "School Name / Title *", icon: Icons.edit),
                              validator: (value) => (value == null || value.trim().isEmpty) ? "Enter school name" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: _fieldDecoration(label: "School Code / ID *", icon: Icons.pin),
                              validator: (value) => (value == null || value.trim().isEmpty) ? "Enter code" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedLevel,
                              decoration: _fieldDecoration(label: "Education Level *", icon: Icons.layers),
                              items: _schoolLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                              onChanged: (val) => setState(() => _selectedLevel = val),
                              validator: (val) => val == null ? "Select level" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: _fieldDecoration(label: "School Type / Agency *", icon: Icons.account_balance),
                              items: _schoolTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                              onChanged: (val) => setState(() => _selectedType = val),
                              validator: (val) => val == null ? "Select type" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGenderType,
                              decoration: _fieldDecoration(label: "Gender Policy *", icon: Icons.wc),
                              items: _genderTypes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => _selectedGenderType = val),
                              validator: (val) => val == null ? "Select policy" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: _fieldDecoration(
                                label: "Status *",
                                icon: Icons.toggle_on_outlined,
                              ),
                              items: _statuses.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: s == 'Active' ? kBrandOlive : Colors.red.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(s),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedStatus = val),
                              validator: (val) => val == null ? "Select status" : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 2: Location Information
                      _buildSectionHeader("Location Details", Icons.location_on),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedRegion,
                              decoration: _fieldDecoration(label: "Region *", icon: Icons.map),
                              items: _regions.map((region) => DropdownMenuItem(value: region, child: Text(region))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRegion = val;
                                  _selectedDistrict = null;
                                });
                              },
                              validator: (val) => val == null ? "Select region" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_selectedRegion),
                              initialValue: _selectedDistrict,
                              decoration: _fieldDecoration(
                                label: "District *",
                                icon: Icons.my_location,
                                enabled: _selectedRegion != null,
                              ),
                              items: _activeDistricts.map((district) => DropdownMenuItem(value: district, child: Text(district))).toList(),
                              onChanged: _selectedRegion == null ? null : (val) => setState(() => _selectedDistrict = val),
                              validator: (val) => val == null ? "Select district" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: _fieldDecoration(label: "Physical Address / Landmarks", icon: Icons.home),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _postalController,
                        decoration: _fieldDecoration(label: "Postal Address", icon: Icons.local_post_office),
                      ),

                      const SizedBox(height: 16),

                      // SECTION 3: School Contact Info
                      _buildSectionHeader("School Contacts", Icons.contact_phone),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(label: "Primary Phone *", icon: Icons.phone),
                              validator: (value) => (value == null || value.trim().isEmpty) ? "Enter primary phone" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _altPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(label: "Alternative Phone", icon: Icons.phone_android),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _fieldDecoration(label: "School Email *", icon: Icons.email),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return "Enter email";
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value.trim())) return "Enter valid email";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              decoration: _fieldDecoration(label: "Website URL (e.g. www.school.com)", icon: Icons.language),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 4: Headteacher / Administrator Contact
                      _buildSectionHeader("Contact Person / Headteacher", Icons.person),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _adminNameController,
                              decoration: _fieldDecoration(label: "Contact Full Name", icon: Icons.badge),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _adminRoleController,
                              decoration: _fieldDecoration(label: "Designation (e.g. Principal)", icon: Icons.work),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _adminPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(label: "Contact Phone", icon: Icons.contact_phone),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _adminEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _fieldDecoration(label: "Contact Email", icon: Icons.contact_mail),
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegex.hasMatch(value.trim())) return "Enter valid email";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 5: Additional Info & Description
                      _buildSectionHeader("Additional Information", Icons.info_outline),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: _fieldDecoration(label: "Details / Description", icon: Icons.description),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: _fieldDecoration(label: "Additional Notes", icon: Icons.info),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}