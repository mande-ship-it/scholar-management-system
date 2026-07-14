import 'package:flutter/material.dart';

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
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/schools/profile',
                                arguments: school,
                              );
                            },
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
