import 'package:flutter/material.dart';

// ============================================================
// Shared Brand Color Palette (consistent with Register Scholar)
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

// Shared validation patterns (kept consistent with Register Scholar).
final RegExp _kEmailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

// ============================================================
// VIEW SCHOLARS COMPONENT (registry table + profile pop-up)
// ============================================================

class ViewScholarsComponent extends StatefulWidget {
  const ViewScholarsComponent({super.key});

  @override
  State<ViewScholarsComponent> createState() => _ViewScholarsComponentState();
}

class _ViewScholarsComponentState extends State<ViewScholarsComponent> {
  // Search & Filter state variables
  String _searchQuery = '';
  String _selectedSchoolType = 'All';
  String _selectedSchoolName = 'All';
  String _selectedSex = 'All';

  // Rich mock data representing different school types, districts, donors, etc.
  final List<Map<String, String>> _allScholars = [
    {
      'id': '001',
      'name': 'Mary Banda',
      'schoolType': 'Secondary',
      'school': 'Mzuzu Government Secondary School',
      'class': 'Form 3',
      'status': 'Active',
      'district': 'Mzimba',
      'donor': 'PMI',
      'sex': 'Female',
      'dob': '2009-05-12',
      'village': 'Chilinde',
      'phone': '+265 888 12 34 56',
      'email': 'mary.banda@example.com',
      'programType': '',
      'startYear': '2023',
      'endYear': '2027'
    },
    {
      'id': '002',
      'name': 'John Phiri',
      'schoolType': 'Secondary',
      'school': 'Likuni Boys Secondary School',
      'class': 'Form 4',
      'status': 'Active',
      'district': 'Lilongwe',
      'donor': 'BGE',
      'sex': 'Male',
      'dob': '2008-11-23',
      'village': 'Likuni',
      'phone': '+265 999 98 76 54',
      'email': '',
      'programType': '',
      'startYear': '2022',
      'endYear': '2026'
    },
    {
      'id': '003',
      'name': 'Chikondi Mwale',
      'schoolType': 'University',
      'school': 'University of Malawi (UNIMA)',
      'class': 'Year 2',
      'status': 'Active',
      'district': 'Zomba',
      'donor': 'General Fund',
      'sex': 'Female',
      'dob': '2005-04-15',
      'village': 'Chinamwali',
      'phone': '+265 881 23 45 67',
      'email': 'chikondi.mwale@example.com',
      'programType': 'Degree',
      'startYear': '2024',
      'endYear': '2028'
    },
    {
      'id': '004',
      'name': 'Taonga Nyirenda',
      'schoolType': 'University',
      'school': 'Malawi University of Business and Applied Sciences (MUBAS)',
      'class': 'Year 3',
      'status': 'Inactive',
      'district': 'Blantyre',
      'donor': 'PMI',
      'sex': 'Male',
      'dob': '2004-09-02',
      'village': 'Ndirande',
      'phone': '+265 992 34 56 78',
      'email': 'taonga.nyirenda@example.com',
      'programType': 'Diploma',
      'startYear': '2023',
      'endYear': '2026'
    },
  ];

  final List<String> _secondarySchools = [
    'Chaminade Secondary School',
    'Chassa Secondary School',
    'Chipasula Secondary School',
    'Dedza Secondary School',
    'HHI Secondary School',
    'Karonga Girls Secondary School',
    'Likuni Boys Secondary School',
    'Likuni Girls Secondary School',
    'Lilongwe Girls Secondary School',
    'Marymount Secondary School',
    'Mzuzu Government Secondary School',
    'Nkhata Bay Secondary School',
    'St. Mary\'s Girls Secondary School',
    'Zomba Catholic Secondary School',
  ];

  final List<String> _publicUniversities = [
    'University of Malawi (UNIMA)',
    'Malawi University of Business and Applied Sciences (MUBAS)',
    'Kamuzu University of Health Sciences (KUHeS)',
    'Lilongwe University of Agriculture and Natural Resources (LUANAR)',
    'Mzuzu University (MZUNI)',
    'Malawi University of Science and Technology (MUST)',
  ];

  // Helper to get matching schools list for the dropdown filter based on selected school type
  List<String> _getAvailableSchoolsForFilter() {
    if (_selectedSchoolType == 'Secondary') {
      return _secondarySchools;
    } else if (_selectedSchoolType == 'University') {
      return _publicUniversities;
    } else {
      return [..._secondarySchools, ..._publicUniversities];
    }
  }

  // Filter scholars list based on current user inputs
  List<Map<String, String>> _getFilteredScholars() {
    return _allScholars.where((scholar) {
      // 1. Search by name (case-insensitive text search)
      final nameMatches = scholar['name']!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      // 2. Filter by school type
      final typeMatches = _selectedSchoolType == 'All' ||
          scholar['schoolType'] == _selectedSchoolType;

      // 3. Filter by school name
      final schoolMatches = _selectedSchoolName == 'All' ||
          scholar['school'] == _selectedSchoolName;

      // 4. Filter by sex
      final sexMatches =
          _selectedSex == 'All' || scholar['sex'] == _selectedSex;

      return nameMatches && typeMatches && schoolMatches && sexMatches;
    }).toList();
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
  // Activate / Deactivate a scholar
  // ---------------------------------------------------------------------
  void _toggleScholarStatus(Map<String, String> scholar) {
    final bool wasActive = scholar['status'] == 'Active';
    setState(() {
      scholar['status'] = wasActive ? 'Inactive' : 'Active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasActive
              ? "${scholar['name']} has been deactivated."
              : "${scholar['name']} has been activated.",
        ),
        backgroundColor: wasActive ? kBrandOrange : kBrandOlive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Scholar Profile Popup
  // ---------------------------------------------------------------------
  void _showScholarProfileDialog(BuildContext context, Map<String, String> scholar) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Scholar Profile",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * curved.value),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    final isActive = scholar['status'] == 'Active';
                    final hasProgram = scholar['programType'] != null &&
                        scholar['programType']!.isNotEmpty;
                    final isUniversity = scholar['schoolType'] == 'University';
                    final initials = _initialsOf(scholar['name']!);
                    final hasEmail =
                        scholar['email'] != null && scholar['email']!.isNotEmpty;

                    return Material(
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
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        scholar['name']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Scholar ID: ${scholar['id']}",
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.white
                                              : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          scholar['status']!,
                                          style: TextStyle(
                                            color: isActive
                                                ? kBrandOlive
                                                : Colors.red.shade900,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  ),
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
                                  _sectionTitle("Academic Information"),
                                  const SizedBox(height: 12),
                                  _infoGrid([
                                    _InfoItem(Icons.category_outlined, "School Type", scholar['schoolType']!,
                                        valueColor: isUniversity ? kBrandBrown : kBrandOrange),
                                    _InfoItem(Icons.school_outlined, "School", scholar['school']!),
                                    _InfoItem(Icons.class_outlined, "Year / Form", scholar['class']!),
                                    _InfoItem(
                                      Icons.workspace_premium_outlined,
                                      "Program",
                                      hasProgram ? scholar['programType']! : 'N/A',
                                    ),
                                    _InfoItem(Icons.event_outlined, "Start Year", scholar['startYear'] ?? 'N/A'),
                                    _InfoItem(Icons.event_available_outlined, "End Year", scholar['endYear'] ?? 'N/A'),
                                  ]),
                                  const SizedBox(height: 24),
                                  _sectionTitle("Personal Information"),
                                  const SizedBox(height: 12),
                                  _infoGrid([
                                    _InfoItem(Icons.wc_outlined, "Sex", scholar['sex'] ?? 'N/A'),
                                    _InfoItem(Icons.cake_outlined, "Date of Birth", scholar['dob'] ?? 'N/A'),
                                    _InfoItem(Icons.location_on_outlined, "District", scholar['district'] ?? 'N/A'),
                                    _InfoItem(Icons.home_outlined, "Village", scholar['village'] ?? 'N/A'),
                                  ]),
                                  const SizedBox(height: 24),
                                  _sectionTitle("Contact & Sponsorship"),
                                  const SizedBox(height: 12),
                                  _infoGrid([
                                    _InfoItem(Icons.phone_outlined, "Phone", scholar['phone'] ?? 'N/A'),
                                    _InfoItem(Icons.email_outlined, "Email", hasEmail ? scholar['email']! : 'N/A'),
                                    _InfoItem(Icons.volunteer_activism_outlined, "Donor / Sponsor", scholar['donor'] ?? 'N/A'),
                                  ]),
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
                                      _toggleScholarStatus(scholar);
                                      setLocalState(() {});
                                    },
                                    icon: Icon(
                                      isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                                      size: 20,
                                      color: isActive ? kBrandOrange : kBrandOlive,
                                    ),
                                    label: Text(
                                      isActive ? "Deactivate Scholar" : "Activate Scholar",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? kBrandOrange : kBrandOlive,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide(
                                        color: (isActive ? kBrandOrange : kBrandOlive).withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text("Close"),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          foregroundColor: Colors.grey.shade700,
                                          side: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Close the profile pop-up, then open the
                                          // Edit Scholar pop-up (also a dialog, not a route).
                                          Navigator.of(ctx).pop();
                                          showEditScholarDialog(context, scholar);
                                        },
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text("Edit Scholar"),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
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
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
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

  Widget _infoGrid(List<_InfoItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on wider dialogs, one column if narrow.
        final columns = constraints.maxWidth > 380 ? 2 : 1;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
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
                          Text(
                            item.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: item.valueColor ?? Colors.black87,
                            ),
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

  // ---------------------------------------------------------------------
  // Page-level UI helpers
  // ---------------------------------------------------------------------
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
    final filteredScholars = _getFilteredScholars();
    final availableSchools = _getAvailableSchoolsForFilter();
    final activeCount = _allScholars.where((s) => s['status'] == 'Active').length;
    final universityCount = _allScholars.where((s) => s['schoolType'] == 'University').length;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F6F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Gradient Header (compact)
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
                        child: const Icon(Icons.groups_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Scholars Registry",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${filteredScholars.length} of ${_allScholars.length} scholars",
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
                    _miniStat(Icons.account_balance_rounded, "$universityCount uni", kBrandCream),
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
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedSchoolType = 'All';
                        _selectedSchoolName = 'All';
                        _selectedSex = 'All';
                      });
                    },
                    tooltip: "Reset Filters",
                  ),
                ),
              ],
            ),
          ),

          // 2. Search & Filter Bar
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
                  // Name Search Field
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Search by Name",
                        hintText: "Enter name...",
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                  // School Type Filter
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedSchoolType,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "School Type",
                        prefixIcon: const Icon(Icons.category_outlined, size: 18),
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
                      items: const [
                        DropdownMenuItem(
                          value: "All",
                          child: Text("All Types", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Secondary",
                          child: Text("Secondary", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "University",
                          child: Text("University", overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolType = value ?? 'All';
                          _selectedSchoolName = 'All'; // Reset school filter on type change
                        });
                      },
                    ),
                  ),

                  // School Name Filter (Cascading)
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      key: ValueKey(_selectedSchoolType),
                      initialValue: _selectedSchoolName,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "School Name",
                        prefixIcon: const Icon(Icons.school_outlined, size: 18),
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
                      items: [
                        const DropdownMenuItem(
                          value: "All",
                          child: Text("All Schools", overflow: TextOverflow.ellipsis),
                        ),
                        ...availableSchools.map((school) {
                          return DropdownMenuItem(
                            value: school,
                            child: Text(
                              school,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolName = value ?? 'All';
                        });
                      },
                    ),
                  ),

                  // Sex Filter
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedSex,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Sex",
                        prefixIcon: const Icon(Icons.wc_outlined, size: 18),
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
                      items: const [
                        DropdownMenuItem(
                          value: "All",
                          child: Text("All Genders", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Male",
                          child: Text("Male", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Other",
                          child: Text("Other", overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSex = value ?? 'All';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Scrollable Table Card
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
                child: filteredScholars.isEmpty
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
                          "No Scholars Found",
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
                    : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 120,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(kBrandCream),
                        headingRowHeight: 48,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 64,
                        columnSpacing: 24,
                        horizontalMargin: 24,
                        dividerThickness: 0.6,
                        columns: const [
                          DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("School Type", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("School", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Year / Form", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Program", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                        ],
                        rows: filteredScholars.asMap().entries.map((entry) {
                          final index = entry.key;
                          final scholar = entry.value;
                          final isActive = scholar['status'] == 'Active';
                          final hasProgram = scholar['programType'] != null && scholar['programType']!.isNotEmpty;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return kBrandCream.withValues(alpha: 0.6);
                              }
                              return index.isEven ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.6);
                            }),
                            onSelectChanged: (selected) {
                              if (selected != null) {
                                _showScholarProfileDialog(context, scholar);
                              }
                            },
                            cells: [
                              DataCell(Text(scholar['id']!, style: TextStyle(color: Colors.grey.shade600))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: kBrandOlive.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _initialsOf(scholar['name']!),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: kBrandBrown,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      scholar['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scholar['schoolType'] == 'University'
                                        ? kBrandBrown.withValues(alpha: 0.08)
                                        : kBrandOrange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    scholar['schoolType']!,
                                    style: TextStyle(
                                      color: scholar['schoolType'] == 'University'
                                          ? kBrandBrown
                                          : kBrandOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    scholar['school']!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              DataCell(Text(scholar['class']!)),
                              DataCell(
                                Text(
                                  hasProgram ? scholar['programType']! : 'N/A',
                                  style: TextStyle(
                                    color: hasProgram ? kBrandOlive : Colors.grey,
                                    fontStyle: hasProgram ? FontStyle.normal : FontStyle.italic,
                                  ),
                                ),
                              ),
                              DataCell(
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
                                        scholar['status']!,
                                        style: TextStyle(
                                          color: isActive ? kBrandOlive : Colors.red.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_note, color: kBrandBrown),
                                      onPressed: () {
                                        // Opens the Edit Scholar pop-up dialog directly
                                        // from the table row, without leaving the page.
                                        showEditScholarDialog(context, scholar);
                                      },
                                      tooltip: "Edit Scholar",
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                        color: isActive ? kBrandOlive : Colors.grey.shade500,
                                        size: 26,
                                      ),
                                      onPressed: () => _toggleScholarStatus(scholar),
                                      tooltip: isActive ? "Deactivate" : "Activate",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
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

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoItem(this.icon, this.label, this.value, {this.valueColor});
}


// ============================================================
// EDIT SCHOLAR POP-UP
// ============================================================

/// Call this to open the Edit Scholar form as a beautiful popup dialog.
/// Pass the scholar map (e.g. from a table row) or leave null to use
/// fallback demo data.
Future<void> showEditScholarDialog(
    BuildContext context,
    Map<String, String>? scholar,
    ) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Edit Scholar",
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.94 + (0.06 * curved.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
              child: EditScholarComponent(scholarData: scholar),
            ),
          ),
        ),
      );
    },
  );
}

class EditScholarComponent extends StatefulWidget {
  final Map<String, String>? scholarData;

  const EditScholarComponent({super.key, this.scholarData});

  @override
  State<EditScholarComponent> createState() => _EditScholarComponentState();
}

class _EditScholarComponentState extends State<EditScholarComponent> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  // Form Field States
  String? _selectedDistrict;
  String? _selectedSchoolType;
  String? _selectedSchool;
  String? _selectedProgramType;
  String? _selectedDonor;
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  String? _selectedStartYear;
  String? _selectedEndYear;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _homeVillageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Data lists
  final List<String> _districts = [
    'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa',
    'Dedza', 'Dowa', 'Karonga', 'Kasungu', 'Likoma',
    'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji', 'Mulanje',
    'Mwanza', 'Mzimba', 'Neno', 'Nkhata Bay', 'Nkhotakota',
    'Nsanje', 'Ntcheu', 'Ntchisi', 'Phalombe', 'Rumphi',
    'Salima', 'Thyolo', 'Zomba'
  ];

  final List<String> _schoolTypes = ['Secondary', 'University'];

  final List<String> _secondarySchools = [
    'Chaminade Secondary School',
    'Chassa Secondary School',
    'Chipasula Secondary School',
    'Dedza Secondary School',
    'HHI Secondary School',
    'Karonga Girls Secondary School',
    'Likuni Boys Secondary School',
    'Likuni Girls Secondary School',
    'Lilongwe Girls Secondary School',
    'Marymount Secondary School',
    'Mzuzu Government Secondary School',
    'Nkhata Bay Secondary School',
    'St. Mary\'s Girls Secondary School',
    'Zomba Catholic Secondary School',
  ];

  final List<String> _publicUniversities = [
    'University of Malawi (UNIMA)',
    'Malawi University of Business and Applied Sciences (MUBAS)',
    'Kamuzu University of Health Sciences (KUHeS)',
    'Lilongwe University of Agriculture and Natural Resources (LUANAR)',
    'Mzuzu University (MZUNI)',
    'Malawi University of Science and Technology (MUST)',
  ];

  final List<String> _donors = ['PMI', 'BGE', 'General Fund'];
  final List<String> _sexOptions = ['Female', 'Male', 'Other'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = widget.scholarData;

      if (args != null) {
        _selectedDistrict = args['district'];
        _selectedSchoolType = args['schoolType'];
        _selectedSchool = args['school'];
        _selectedProgramType = (args['programType'] != null && args['programType']!.isNotEmpty)
            ? args['programType']
            : null;
        _selectedDonor = args['donor'];
        _selectedSex = args['sex'];
        _selectedStartYear = args['startYear'];
        _selectedEndYear = args['endYear'];

        _fullNameController.text = args['name'] ?? '';
        _yearController.text = args['class'] ?? '';
        _homeVillageController.text = args['village'] ?? '';
        _phoneController.text = args['phone'] ?? '';
        _emailController.text = args['email'] ?? '';
        _dobController.text = args['dob'] ?? '';

        if (args['dob'] != null && args['dob']!.isNotEmpty) {
          try {
            _selectedDateOfBirth = DateTime.parse(args['dob']!);
          } catch (_) {}
        }
      } else {
        // Fallback default info (Mary Banda)
        _selectedDistrict = 'Mzimba';
        _selectedSchoolType = 'Secondary';
        _selectedSchool = 'Mzuzu Government Secondary School';
        _selectedProgramType = null;
        _selectedDonor = 'PMI';
        _selectedSex = 'Female';
        _fullNameController.text = 'Mary Banda';
        _yearController.text = 'Form 3';
        _homeVillageController.text = 'Chilinde';
        _phoneController.text = '+265 888 12 34 56';
        _emailController.text = 'mary.banda@example.com';
        _dobController.text = '2009-05-12';
        _selectedDateOfBirth = DateTime(2009, 5, 12);
        _selectedStartYear = '2023';
        _selectedEndYear = '2027';
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _yearController.dispose();
    _homeVillageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      // Email is optional - empty is fine.
      return null;
    }
    if (!_kEmailRegex.hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandOlive,
              onPrimary: Colors.white,
              onSurface: kBrandBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Scholar ${_fullNameController.text} updated successfully!"),
          backgroundColor: kBrandOlive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: kBrandBrown,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Professional searchable "Select School" popup
  // ---------------------------------------------------------------------
  Future<String?> _showSchoolPickerDialog(BuildContext context) {
    final options = _selectedSchoolType == 'Secondary' ? _secondarySchools : _publicUniversities;
    final isUniversity = _selectedSchoolType == 'University';
    String query = '';

    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Select School",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * curved.value),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    final filtered = options
                        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                        .toList();

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      elevation: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [kBrandBrown, kBrandOlive],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isUniversity ? Icons.account_balance_rounded : Icons.school_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUniversity ? "Select Public University" : "Select Secondary School",
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${options.length} institutions available",
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(32, 32),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Search bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                hintText: "Search schools...",
                                prefixIcon: const Icon(Icons.search, size: 20),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: kBrandOlive),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (value) => setLocalState(() => query = value),
                            ),
                          ),

                          // List
                          Flexible(
                            child: filtered.isEmpty
                                ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text("No schools match your search", style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                                : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final school = filtered[index];
                                final isSelected = school == _selectedSchool;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => Navigator.of(ctx).pop(school),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? kBrandCream : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? kBrandOlive.withValues(alpha: 0.5) : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: isSelected ? kBrandOlive.withValues(alpha: 0.15) : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isUniversity ? Icons.account_balance_rounded : Icons.school_outlined,
                                            size: 16,
                                            color: isSelected ? kBrandBrown : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            school,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? kBrandBrown : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: kBrandOlive, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> yearsList = List.generate(21, (index) => (DateTime.now().year - 5 + index).toString());
    if (_selectedStartYear != null && !yearsList.contains(_selectedStartYear)) {
      yearsList.add(_selectedStartYear!);
      yearsList.sort();
    }
    if (_selectedEndYear != null && !yearsList.contains(_selectedEndYear)) {
      yearsList.add(_selectedEndYear!);
      yearsList.sort();
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------- Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Edit Scholar Profile",
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullNameController.text.isEmpty
                              ? "Update the scholar's information"
                              : "Updating ${_fullNameController.text}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Body ----------------
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle("Academic Information"),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      decoration: _fieldDecoration(label: "District", icon: Icons.map_outlined, helperText: "Select district in Malawi"),
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _selectedDistrict = value),
                      validator: (value) => value == null ? "Please select a district" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSchoolType,
                      decoration: _fieldDecoration(label: "School Type", icon: Icons.category_outlined),
                      items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolType = value;
                          _selectedSchool = null;
                        });
                      },
                      validator: (value) => value == null ? "Please select a school type" : null,
                    ),
                    const SizedBox(height: 16),
                    FormField<String>(
                      key: ValueKey('school_field_${_selectedSchoolType}_$_selectedSchool'),
                      initialValue: _selectedSchool,
                      validator: (value) => _selectedSchool == null ? "Please select a school" : null,
                      builder: (state) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _selectedSchoolType == null
                              ? null
                              : () async {
                            final result = await _showSchoolPickerDialog(context);
                            if (result != null) {
                              setState(() => _selectedSchool = result);
                              state.didChange(result);
                            }
                          },
                          child: InputDecorator(
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == null
                                  ? "School (select type first)"
                                  : (_selectedSchoolType == "University" ? "Public University" : "Secondary School"),
                              icon: Icons.school_outlined,
                              enabled: _selectedSchoolType != null,
                              suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade600),
                            ).copyWith(errorText: state.errorText),
                            child: Text(
                              _selectedSchool ?? "Tap to select a school",
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedSchool == null ? Colors.grey.shade500 : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                    if (_selectedSchoolType == 'University') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('programType_$_selectedSchoolType'),
                        initialValue: _selectedProgramType,
                        decoration: _fieldDecoration(label: "Program Type", icon: Icons.bookmark_outline),
                        items: const [
                          DropdownMenuItem(value: "Degree", child: Text("Degree")),
                          DropdownMenuItem(value: "Diploma", child: Text("Diploma")),
                          DropdownMenuItem(value: "Certificate", child: Text("Certificate")),
                        ],
                        onChanged: (value) => setState(() => _selectedProgramType = value),
                        validator: (value) => value == null ? "Please select a program type" : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: _fieldDecoration(label: "Year / Form", icon: Icons.calendar_today_outlined, helperText: "e.g., Form 3, Year 2"),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the academic year or form" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStartYear,
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == 'University' ? "Start Year" : "Session Start",
                              icon: Icons.event_outlined,
                            ),
                            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (value) => setState(() => _selectedStartYear = value),
                            validator: (value) => value == null ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedEndYear,
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == 'University' ? "End Year" : "Session End",
                              icon: Icons.event_available_outlined,
                            ),
                            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (value) => setState(() => _selectedEndYear = value),
                            validator: (value) {
                              if (value == null) return "Required";
                              if (_selectedStartYear != null) {
                                final start = int.parse(_selectedStartYear!);
                                final end = int.parse(value);
                                if (end < start) return "Must be ≥ start";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle("Personal Information"),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: _fieldDecoration(label: "Full Name", icon: Icons.person_outline),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the scholar's full name" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSex,
                            decoration: _fieldDecoration(label: "Sex", icon: Icons.wc_outlined),
                            items: _sexOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (value) => setState(() => _selectedSex = value),
                            validator: (value) => value == null ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDateOfBirth(context),
                            decoration: _fieldDecoration(
                              label: "Date of Birth",
                              icon: Icons.cake_outlined,
                              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _homeVillageController,
                      decoration: _fieldDecoration(label: "Home Village", icon: Icons.home_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the home village" : null,
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle("Contact & Sponsorship"),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(label: "Phone Number", icon: Icons.phone_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the phone number" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(label: "Email Address (optional)", icon: Icons.email_outlined),
                      validator: _validateOptionalEmail,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDonor,
                      decoration: _fieldDecoration(label: "Donor / Sponsor", icon: Icons.volunteer_activism_outlined),
                      items: _donors.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _selectedDonor = value),
                      validator: (value) => value == null ? "Please select a donor" : null,
                    ),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Cancel"),
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
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
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
            ),
          ],
        ),
      ),
    );
  }
}