import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final filteredScholars = _getFilteredScholars();
    final availableSchools = _getAvailableSchoolsForFilter();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Scholars Registry",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Showing ${filteredScholars.length} of ${_allScholars.length} scholars • Tap a row to view profile",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
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
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      labelText: "Search by Name",
                      hintText: "Enter name...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      labelText: "School Type",
                      prefixIcon: const Icon(Icons.category_outlined, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      labelText: "School Name",
                      prefixIcon: const Icon(Icons.school_outlined, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      labelText: "Sex",
                      prefixIcon: const Icon(Icons.wc_outlined, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
          const Divider(height: 1),

          // 3. Scrollable Table
          Expanded(
            child: filteredScholars.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      "No Scholars Found",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Try loosening your filters or clearing search text.",
                      style: TextStyle(color: Colors.grey),
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
                    headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
                    columnSpacing: 24,
                    horizontalMargin: 24,
                    columns: const [
                      DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("School Type", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("School", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Year / Form", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Program", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredScholars.map((scholar) {
                      final isActive = scholar['status'] == 'Active';
                      final hasProgram = scholar['programType'] != null && scholar['programType']!.isNotEmpty;
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected != null) {
                            Navigator.pushNamed(
                              context,
                              '/scholarProfile',
                              arguments: scholar,
                            );
                          }
                        },
                        cells: [
                          DataCell(Text(scholar['id']!)),
                          DataCell(
                            Text(
                              scholar['name']!,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scholar['schoolType'] == 'University'
                                    ? Colors.blue.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                scholar['schoolType']!,
                                style: TextStyle(
                                  color: scholar['schoolType'] == 'University'
                                      ? Colors.blue.shade800
                                      : Colors.orange.shade900,
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
                                color: hasProgram ? Colors.blue.shade900 : Colors.grey,
                                fontStyle: hasProgram ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                scholar['status']!,
                                style: TextStyle(
                                  color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blue),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/editScholar',
                                  arguments: scholar,
                                );
                              },
                              tooltip: "Edit Scholar",
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
        ],
      ),
    );
  }
}