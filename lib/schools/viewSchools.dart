import 'package:flutter/material.dart';

// ============================================================
// VIEW SCHOOLS COMPONENT (list + entry point for the pop-ups)
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

  // Opens the professional profile pop-up for a given school.
  // From there the user can launch the Edit pop-up, and any saved
  // changes are written back into _allSchools.
  void _openSchoolProfile(Map<String, String> school) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return SchoolProfileDialog(
          school: school,
          onEdit: () async {
            Navigator.pop(dialogContext); // close profile pop-up first

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
        );
      },
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "View Schools",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "View and manage partner educational institutions (${filteredSchools.length} listed)",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_list_off),
                      label: const Text("Reset Filters"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/schools/register');
                      },
                      icon: const Icon(Icons.add_business),
                      label: const Text("Register School"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Search & Filter Bar
            Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Search schools by name, code or district",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Level Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: "Education Level",
                      prefixIcon: Icon(Icons.layers),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _schoolLevels.map((l) {
                      return DropdownMenuItem(value: l, child: Text(l));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedLevel = val ?? 'All';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Region Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedRegion,
                    decoration: const InputDecoration(
                      labelText: "Region",
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _regions.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
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
            const SizedBox(height: 24),

            // School Data Table / List
            Expanded(
              child: filteredSchools.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "No schools match the search/filter criteria.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              )
                  : Scrollbar(
                child: ListView.separated(
                  itemCount: filteredSchools.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    final isActive = school['status'] == 'Active';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        radius: 24,
                        child: Icon(
                          school['level'] == 'Tertiary / University'
                              ? Icons.account_balance
                              : Icons.school,
                          color: Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        school['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text("Code: ${school['code']!}"),
                            const SizedBox(width: 12),
                            const Icon(Icons.circle, size: 4, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(school['level']!),
                            const SizedBox(width: 12),
                            const Icon(Icons.circle, size: 4, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(school['district']!),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              school['status']!,
                              style: TextStyle(
                                color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      // Opens the professional profile as a pop-up instead
                      // of navigating to a separate page/route.
                      onTap: () => _openSchoolProfile(school),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// SCHOOL PROFILE POP-UP
// ============================================================

/// A professional, read-only pop-up dialog that displays full details
/// for a single school. Triggered by tapping a school in ViewSchoolsComponent.
class SchoolProfileDialog extends StatelessWidget {
  final Map<String, String> school;
  final VoidCallback onEdit;

  const SchoolProfileDialog({
    super.key,
    required this.school,
    required this.onEdit,
  });

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Skip rendering entirely if every row would be empty
    final visibleChildren = children.where((w) => w is! SizedBox).toList();
    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = school['status'] == 'Active';
    final isTertiary = school['level'] == 'Tertiary / University';
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 760 ? screenWidth * 0.94 : 720.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 12, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(
                      isTertiary ? Icons.account_balance : Icons.school,
                      color: Colors.green.shade700,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              school['code'] ?? '',
                              style: TextStyle(
                                color: Colors.green.shade50,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withOpacity(0.22)
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                school['status'] ?? '',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.red.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 20),

                    if ((school['description'] ?? '').isNotEmpty) ...[
                      Text(
                        school['description']!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _sectionCard(
                      title: "LOCATION",
                      icon: Icons.location_on,
                      children: [
                        _infoRow(Icons.map, "Region", school['region'] ?? ''),
                        _infoRow(
                            Icons.my_location, "District", school['district'] ?? ''),
                        _infoRow(Icons.home, "Address", school['address'] ?? ''),
                        _infoRow(Icons.local_post_office, "Postal",
                            school['postal'] ?? ''),
                      ],
                    ),

                    _sectionCard(
                      title: "SCHOOL CONTACTS",
                      icon: Icons.contact_phone,
                      children: [
                        _infoRow(Icons.phone, "Phone", school['phone'] ?? ''),
                        _infoRow(Icons.phone_android, "Alt. Phone",
                            school['altPhone'] ?? ''),
                        _infoRow(Icons.email, "Email", school['email'] ?? ''),
                        _infoRow(
                            Icons.language, "Website", school['website'] ?? ''),
                      ],
                    ),

                    _sectionCard(
                      title: "ADMINISTRATOR",
                      icon: Icons.person,
                      children: [
                        _infoRow(Icons.badge, "Name", school['adminName'] ?? ''),
                        _infoRow(Icons.work, "Role", school['adminRole'] ?? ''),
                        _infoRow(Icons.contact_phone, "Phone",
                            school['adminPhone'] ?? ''),
                        _infoRow(Icons.contact_mail, "Email",
                            school['adminEmail'] ?? ''),
                      ],
                    ),

                    if ((school['notes'] ?? '').isNotEmpty)
                      _sectionCard(
                        title: "NOTES",
                        icon: Icons.info,
                        children: [
                          Text(
                            school['notes']!,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                  ],
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
                    icon: const Icon(Icons.close),
                    label: const Text("Close"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit School"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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


// ============================================================
// EDIT SCHOOL POP-UP
// ============================================================

/// A professional pop-up (modal) version of the Edit School form.
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
    _descriptionController =
        TextEditingController(text: args['description'] ?? '');
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
    if (_selectedGenderType != null &&
        !_genderTypes.contains(_selectedGenderType)) {
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
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Changes to '${updatedSchool['name']}' (${updatedSchool['code']}) successfully saved!"),
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, updatedSchool);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please correct the errors in the form."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Update details for ${widget.school['name'] ?? 'this school'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.green.shade50,
                            fontSize: 12.5,
                          ),
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
                              decoration: const InputDecoration(
                                labelText: "School Name / Title *",
                                prefixIcon: Icon(Icons.edit),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter school name";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: "School Code / ID *",
                                prefixIcon: Icon(Icons.pin),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter code";
                                }
                                return null;
                              },
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
                              decoration: const InputDecoration(
                                labelText: "Education Level *",
                                prefixIcon: Icon(Icons.layers),
                                border: OutlineInputBorder(),
                              ),
                              items: _schoolLevels.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedLevel = val),
                              validator: (val) => val == null ? "Select level" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: const InputDecoration(
                                labelText: "School Type / Agency *",
                                prefixIcon: Icon(Icons.account_balance),
                                border: OutlineInputBorder(),
                              ),
                              items: _schoolTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedType = val),
                              validator: (val) => val == null ? "Select type" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGenderType,
                        decoration: const InputDecoration(
                          labelText: "Gender Policy *",
                          prefixIcon: Icon(Icons.wc),
                          border: OutlineInputBorder(),
                        ),
                        items: _genderTypes.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedGenderType = val),
                        validator: (val) => val == null ? "Select policy" : null,
                      ),

                      const SizedBox(height: 16),

                      // SECTION 2: Location Information
                      _buildSectionHeader("Location Details", Icons.location_on),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedRegion,
                              decoration: const InputDecoration(
                                labelText: "Region *",
                                prefixIcon: Icon(Icons.map),
                                border: OutlineInputBorder(),
                              ),
                              items: _regions.map((region) {
                                return DropdownMenuItem(
                                  value: region,
                                  child: Text(region),
                                );
                              }).toList(),
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
                              decoration: InputDecoration(
                                labelText: "District *",
                                prefixIcon: const Icon(Icons.my_location),
                                border: const OutlineInputBorder(),
                                enabled: _selectedRegion != null,
                              ),
                              items: _activeDistricts.map((district) {
                                return DropdownMenuItem(
                                  value: district,
                                  child: Text(district),
                                );
                              }).toList(),
                              onChanged: _selectedRegion == null
                                  ? null
                                  : (val) => setState(() => _selectedDistrict = val),
                              validator: (val) =>
                              val == null ? "Select district" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Physical Address / Landmarks",
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _postalController,
                        decoration: const InputDecoration(
                          labelText: "Postal Address",
                          prefixIcon: Icon(Icons.local_post_office),
                          border: OutlineInputBorder(),
                        ),
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
                              decoration: const InputDecoration(
                                labelText: "Primary Phone *",
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter primary phone";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _altPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Alternative Phone",
                                prefixIcon: Icon(Icons.phone_android),
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: "School Email *",
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter email";
                                }
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return "Enter valid email";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: "Website URL (e.g. www.school.com)",
                                prefixIcon: Icon(Icons.language),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 4: Headteacher / Administrator Contact
                      _buildSectionHeader(
                          "Contact Person / Headteacher", Icons.person),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _adminNameController,
                              decoration: const InputDecoration(
                                labelText: "Contact Full Name",
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _adminRoleController,
                              decoration: const InputDecoration(
                                labelText: "Designation (e.g. Principal)",
                                prefixIcon: Icon(Icons.work),
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: "Contact Phone",
                                prefixIcon: Icon(Icons.contact_phone),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _adminEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: "Contact Email",
                                prefixIcon: Icon(Icons.contact_mail),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final emailRegex =
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return "Enter valid email";
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 5: Additional Info & Description
                      _buildSectionHeader(
                          "Additional Information", Icons.info_outline),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Details / Description",
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Additional Notes",
                          prefixIcon: Icon(Icons.info),
                          border: OutlineInputBorder(),
                        ),
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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Save Changes",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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