import 'package:flutter/material.dart';

class EditScholarComponent extends StatefulWidget {
  const EditScholarComponent({super.key});

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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        _selectedDistrict = args['district'];
        _selectedSchoolType = args['schoolType'];
        _selectedSchool = args['school'];
        _selectedProgramType = args['programType'];
        _selectedDonor = args['donor'];
        _selectedSex = args['sex'];
        _selectedStartYear = args['startYear'];
        _selectedEndYear = args['endYear'];
        
        _fullNameController.text = args['name'] ?? '';
        _yearController.text = args['class'] ?? '';
        _homeVillageController.text = args['village'] ?? '';
        _phoneController.text = args['phone'] ?? '';
        _dobController.text = args['dob'] ?? '';

        if (args['dob'] != null) {
          try {
            _selectedDateOfBirth = DateTime.parse(args['dob']);
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
    _dobController.dispose();
    super.dispose();
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
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Scholar ${_fullNameController.text} Updated Successfully!"),
          backgroundColor: Colors.blue.shade700,
        ),
      );
      // Go back to previous screen
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Edit Scholar Profile",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Update the scholar's profile and information",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1.2),

                // 1. District Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: "District",
                    helperText: "Select district in Malawi",
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _districts.map((district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select a district" : null,
                ),
                const SizedBox(height: 20),

                // 2a. School Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSchoolType,
                  decoration: const InputDecoration(
                    labelText: "School Type",
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _schoolTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSchoolType = value;
                      _selectedSchool = null; // Clear chosen school when type changes
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select a school type" : null,
                ),
                const SizedBox(height: 20),

                // 2b. School Dropdown (dynamic options)
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedSchoolType),
                  initialValue: _selectedSchool,
                  decoration: InputDecoration(
                    labelText: _selectedSchoolType == null
                        ? "School (Select School Type first)"
                        : (_selectedSchoolType == "University"
                            ? "Public University"
                            : "Secondary School"),
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: const OutlineInputBorder(),
                    enabled: _selectedSchoolType != null,
                  ),
                  items: _selectedSchoolType == null
                      ? []
                      : (_selectedSchoolType == 'Secondary'
                              ? _secondarySchools
                              : _publicUniversities)
                          .map((school) {
                          return DropdownMenuItem<String>(
                            value: school,
                            child: Text(school),
                          );
                        }).toList(),
                  onChanged: _selectedSchoolType == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSchool = value;
                          });
                        },
                  validator: (value) =>
                      value == null ? "Please select a school" : null,
                ),
                const SizedBox(height: 20),

                if (_selectedSchoolType == 'University') ...[
                  // 2c. Program Type Dropdown (only for University)
                  DropdownButtonFormField<String>(
                    key: ValueKey('programType_$_selectedSchoolType'),
                    initialValue: _selectedProgramType,
                    decoration: const InputDecoration(
                      labelText: "Program Type",
                      prefixIcon: Icon(Icons.bookmark_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Degree", child: Text("Degree")),
                      DropdownMenuItem(value: "Diploma", child: Text("Diploma")),
                      DropdownMenuItem(value: "Certificate", child: Text("Certificate")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProgramType = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Please select a program type" : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Donor Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDonor,
                  decoration: const InputDecoration(
                    labelText: "Donor",
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _donors.map((donor) {
                    return DropdownMenuItem<String>(
                      value: donor,
                      child: Text(donor),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDonor = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select a donor" : null,
                ),
                const SizedBox(height: 20),

                // 4. Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter the scholar's full name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 5. Year
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: "Year / Form",
                    helperText: "e.g., Form 3, 2026",
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter the academic year or form";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Starting Year Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStartYear,
                  decoration: InputDecoration(
                    labelText: _selectedSchoolType == 'University' ? "Program Start Year" : "Session Start Year",
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: yearsList.map((year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStartYear = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select start year" : null,
                ),
                const SizedBox(height: 20),

                // Ending Year Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedEndYear,
                  decoration: InputDecoration(
                    labelText: _selectedSchoolType == 'University' ? "Program End Year" : "Session End Year",
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: yearsList.map((year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEndYear = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return "Please select end year";
                    }
                    if (_selectedStartYear != null) {
                      final int start = int.parse(_selectedStartYear!);
                      final int end = int.parse(value);
                      if (end < start) {
                        return "End year must be >= start year";
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 6. Sex Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSex,
                  decoration: const InputDecoration(
                    labelText: "Sex",
                    prefixIcon: Icon(Icons.wc_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _sexOptions.map((sex) {
                    return DropdownMenuItem<String>(
                      value: sex,
                      child: Text(sex),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSex = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select the scholar's sex" : null,
                ),
                const SizedBox(height: 20),

                // 7. Date of Birth Picker
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDateOfBirth(context),
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select a date of birth";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 8. Home Village
                TextFormField(
                  controller: _homeVillageController,
                  decoration: const InputDecoration(
                    labelText: "Home Village",
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter the home village";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 9. Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter the phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}