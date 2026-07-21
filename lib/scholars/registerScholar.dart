import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import '../services/api_service.dart';

class RegisterScholarComponent extends StatefulWidget {
  const RegisterScholarComponent({super.key});

  @override
  State<RegisterScholarComponent> createState() => _RegisterScholarComponentState();
}

class _RegisterScholarComponentState extends State<RegisterScholarComponent> {
  final _formKey = GlobalKey<FormState>();

  // Brand Color Palette (consistent with HomePage)
  static const Color brandBrown = Color(0xFF4C3C32);
  static const Color brandCream = Color(0xFFFAF2DB);
  static const Color brandCreamDark = Color(0xFFF3E7C4);
  static const Color brandOlive = Color(0xFF9AB334);
  static const Color brandOrange = Color(0xFFE05B1C);

  // Form Field States
  bool _isLoading = false;
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

  // Validation patterns
  // Accepts local Malawi numbers starting with 0 (e.g. 0888123456)
  // or international format starting with +265 (e.g. +265888123456).
  // Both forms require exactly 9 digits after the prefix.
  static final RegExp _malawiPhoneRegex = RegExp(r'^(?:\+265|0)[0-9]{9}$');
  static final RegExp _emailRegex =
  RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

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

  // Backend Registered Schools state
  List<Map<String, dynamic>> _registeredSchools = [];
  bool _isLoadingSchools = false;
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredSchools();
    _fullNameController.addListener(_updatePreview);
    _yearController.addListener(_updatePreview);
    _homeVillageController.addListener(_updatePreview);
    _phoneController.addListener(_updatePreview);
    _emailController.addListener(_updatePreview);
    _dobController.addListener(_updatePreview);
  }

  Future<void> _fetchRegisteredSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSchools = data.map((s) => Map<String, dynamic>.from(s)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching registered schools: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSchools = false);
    }
  }

  List<Map<String, dynamic>> _getAvailableSchoolsForScholar() {
    if (_registeredSchools.isEmpty) {
      if (_selectedSchoolType == 'Secondary') {
        return _secondarySchools.map((s) => {'id': null, 'name': s, 'level': 'Secondary School'}).toList();
      } else if (_selectedSchoolType == 'University') {
        return _publicUniversities.map((s) => {'id': null, 'name': s, 'level': 'Tertiary / University'}).toList();
      } else {
        return [
          ..._secondarySchools.map((s) => {'id': null, 'name': s, 'level': 'Secondary School'}),
          ..._publicUniversities.map((s) => {'id': null, 'name': s, 'level': 'Tertiary / University'}),
        ];
      }
    }

    if (_selectedSchoolType == null) {
      return _registeredSchools;
    }

    final typeLower = _selectedSchoolType!.toLowerCase();
    final filtered = _registeredSchools.where((school) {
      final level = (school['level'] ?? '').toString().toLowerCase();
      final type = (school['type'] ?? '').toString().toLowerCase();

      if (typeLower == 'secondary') {
        return level.contains('secondary') || level.contains('high') || type.contains('cdss') || level.contains('primary');
      } else if (typeLower == 'university') {
        return level.contains('university') || level.contains('tertiary') || level.contains('vocational') || type.contains('university');
      }
      return true;
    }).toList();

    return filtered.isNotEmpty ? filtered : _registeredSchools;
  }

  void _updatePreview() {
    setState(() {});
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

  // Returns null when valid (or empty, since phone is required elsewhere
  // and email is optional so emptiness is handled by the caller).
  String? _validateMalawiPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter the phone number";
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!_malawiPhoneRegex.hasMatch(cleaned)) {
      return "Enter a valid Malawi number (e.g. 0888123456 or +265888123456)";
    }
    return null;
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      // Email is optional - empty is fine.
      return null;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: brandBrown,
              onPrimary: Colors.white,
              onSurface: brandBrown,
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final scholarData = {
        'fullName': _fullNameController.text.trim(),
        'schoolType': _selectedSchoolType,
        'schoolName': _selectedSchool,
        'schoolId': _selectedSchoolId != null ? int.tryParse(_selectedSchoolId!) ?? _selectedSchoolId : null,
        'sex': _selectedSex,
        'dob': _dobController.text.trim(),
        'currentClass': _yearController.text.trim(),
        'district': _selectedDistrict,
        'village': _homeVillageController.text.trim(),
        'donor': _selectedDonor,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'programType': _selectedProgramType,
        'startYear': _selectedStartYear,
        'endYear': _selectedEndYear,
      };

      try {
        final response = await ApiService.createScholar(scholarData);

        if (response.statusCode == 201) {
          final newScholar = response.data['data']['scholar'];
          
          // Create local student object to show in success dialog
          final student = Student(
            id: newScholar['id'].toString(),
            name: newScholar['full_name'],
            age: 16, // Placeholder
            schoolType: _selectedSchoolType == 'University' ? SchoolType.university : SchoolType.secondary,
            schoolName: _selectedSchool ?? 'N/A',
            currentClass: _yearController.text.trim(),
            status: 'Active',
            district: _selectedDistrict ?? 'Lilongwe',
            village: _homeVillageController.text.trim(),
            donor: _selectedDonor ?? 'General Fund',
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            sex: _selectedSex ?? 'Female',
            dob: _dobController.text.trim(),
            programType: _selectedProgramType ?? '',
            startYear: _selectedStartYear ?? '2026',
            endYear: _selectedEndYear ?? '2030',
          );

          // Optionally add to local mock database if still using it for other screens
          kStudents.add(student);

          if (mounted) {
            _showSuccessDialog(student);
          }
        } else {
          _showErrorSnackBar(response.data['message'] ?? 'Failed to create scholar.');
        }
      } catch (e) {
        _showErrorSnackBar('An error occurred. Please check your connection.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brandOlive.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: brandOlive, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Registration Complete",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBrown),
                ),
                const SizedBox(height: 8),
                Text(
                  "Scholar ${student.name} has been successfully added to the registry.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _rowDetail("Scholar ID", student.id),
                      const Divider(height: 16),
                      _rowDetail("Institution", student.schoolName),
                      const Divider(height: 16),
                      _rowDetail("Class/Form", student.currentClass),
                      const Divider(height: 16),
                      _rowDetail("District", student.district),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _resetForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text("Go to Registry", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rowDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, color: brandBrown, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedDistrict = null;
      _selectedSchoolType = null;
      _selectedSchool = null;
      _selectedSchoolId = null;
      _selectedProgramType = null;
      _selectedDonor = null;
      _selectedSex = null;
      _selectedDateOfBirth = null;
      _selectedStartYear = null;
      _selectedEndYear = null;
      _fullNameController.clear();
      _yearController.clear();
      _homeVillageController.clear();
      _phoneController.clear();
      _emailController.clear();
      _dobController.clear();
    });
  }

  double _calculateCompletionPercentage() {
    final int total = _getTotalFieldsCount();
    if (total == 0) return 0.0;
    return _getCompletedFieldsCount() / total;
  }

  int _getTotalFieldsCount() {
    // Email is optional, so it is not counted toward the required total.
    return _selectedSchoolType == 'University' ? 13 : 12;
  }

  int _getCompletedFieldsCount() {
    int count = 0;
    if (_fullNameController.text.trim().isNotEmpty) count++;
    if (_dobController.text.isNotEmpty) count++;
    if (_selectedSex != null) count++;
    if (_phoneController.text.trim().isNotEmpty) count++;
    if (_homeVillageController.text.trim().isNotEmpty) count++;
    if (_selectedDistrict != null) count++;
    if (_selectedDonor != null) count++;
    if (_selectedSchoolType != null) count++;
    if (_selectedSchool != null) count++;
    if (_yearController.text.trim().isNotEmpty) count++;
    if (_selectedSchoolType == 'University' && _selectedProgramType != null) count++;
    if (_selectedStartYear != null) count++;
    if (_selectedEndYear != null) count++;
    return count;
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "NS";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, color: brandBrown.withValues(alpha: 0.7)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: brandOlive, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 950;

        final Widget formContent = Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormHeader(),
              const SizedBox(height: 20),
              _buildPersonalDetailsCard(isWide),
              const SizedBox(height: 16),
              _buildAcademicDetailsCard(isWide),
              const SizedBox(height: 16),
              _buildDemographicsCard(isWide),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        );

        final Widget previewContent = _buildPreviewCard();

        if (isWide) {
          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: formContent,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: previewContent,
                  ),
                ),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                previewContent,
                const SizedBox(height: 24),
                formContent,
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brandOlive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: brandOlive,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Register Scholar",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Enter details below to create a new scholar record in the database.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(bool isWide) {
    final Widget nameField = TextFormField(
      controller: _fullNameController,
      decoration: _getInputDecoration(
        labelText: "Full Name",
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Please enter the scholar's full name";
        }
        return null;
      },
    );

    final Widget phoneField = TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _getInputDecoration(
        labelText: "Phone Number",
        prefixIcon: Icons.phone_outlined,
        helperText: "e.g. 0888123456 or +265888123456",
      ),
      validator: _validateMalawiPhone,
    );

    final Widget emailField = TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _getInputDecoration(
        labelText: "Email Address (optional)",
        prefixIcon: Icons.email_outlined,
      ),
      validator: _validateOptionalEmail,
    );

    final Widget sexField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedSex,
      decoration: _getInputDecoration(
        labelText: "Sex",
        prefixIcon: Icons.wc_outlined,
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
    );

    final Widget dobField = TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: () => _selectDateOfBirth(context),
      decoration: _getInputDecoration(
        labelText: "Date of Birth",
        prefixIcon: Icons.cake_outlined,
      ).copyWith(
        suffixIcon: Icon(Icons.calendar_month_outlined, color: brandBrown.withValues(alpha: 0.7)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select a date of birth";
        }
        return null;
      },
    );

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.badge_outlined, color: brandOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (isWide) ...[
              Row(
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 16),
                  Expanded(child: phoneField),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: emailField),
                  const SizedBox(width: 16),
                  Expanded(child: sexField),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: dobField),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ] else ...[
              nameField,
              const SizedBox(height: 16),
              phoneField,
              const SizedBox(height: 16),
              emailField,
              const SizedBox(height: 16),
              sexField,
              const SizedBox(height: 16),
              dobField,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicDetailsCard(bool isWide) {
    final List<String> yearsList = List.generate(21, (index) => (DateTime.now().year - 5 + index).toString());

    final Widget startYearField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedStartYear,
      decoration: _getInputDecoration(
        labelText: _selectedSchoolType == 'University' ? "Program Start Year" : "Session Start Year",
        prefixIcon: Icons.calendar_today,
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
    );

    final Widget endYearField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedEndYear,
      decoration: _getInputDecoration(
        labelText: _selectedSchoolType == 'University' ? "Program End Year" : "Session End Year",
        prefixIcon: Icons.calendar_today,
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
    );

    final Widget schoolTypeField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedSchoolType,
      decoration: _getInputDecoration(
        labelText: "School Type",
        prefixIcon: Icons.category_outlined,
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
          _selectedSchool = null;
          _selectedProgramType = null;
        });
      },
      validator: (value) =>
      value == null ? "Please select a school type" : null,
    );

    final availableSchools = _getAvailableSchoolsForScholar();

    final Widget schoolField = DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('${_selectedSchoolType}_${_registeredSchools.length}'),
      initialValue: _selectedSchool,
      decoration: _getInputDecoration(
        labelText: _isLoadingSchools
            ? "Loading Registered Schools..."
            : (_selectedSchoolType == null
                ? "School (Select School Type first)"
                : (_selectedSchoolType == "University"
                    ? "Registered University"
                    : "Registered Secondary School")),
        prefixIcon: Icons.school_outlined,
        helperText: availableSchools.isEmpty && !_isLoadingSchools
            ? "No schools registered under School component."
            : null,
      ),
      items: availableSchools.map((school) {
        final schoolName = school['name']?.toString() ?? 'Unnamed School';
        return DropdownMenuItem<String>(
          value: schoolName,
          child: Text(schoolName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _selectedSchoolType == null || availableSchools.isEmpty
          ? null
          : (value) {
              setState(() {
                _selectedSchool = value;
                final match = availableSchools.firstWhere(
                  (s) => s['name']?.toString() == value,
                  orElse: () => {},
                );
                _selectedSchoolId = match['id']?.toString();
              });
            },
      validator: (value) =>
          value == null ? "Please select a registered school" : null,
    );

    final Widget yearField = TextFormField(
      controller: _yearController,
      decoration: _getInputDecoration(
        labelText: "Year / Form",
        prefixIcon: Icons.calendar_today_outlined,
        helperText: "e.g., Form 3, 2026",
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Please enter the academic year or form";
        }
        return null;
      },
    );

    final Widget programTypeField = DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('programType_$_selectedSchoolType'),
      initialValue: _selectedProgramType,
      decoration: _getInputDecoration(
        labelText: "Program Type",
        prefixIcon: Icons.bookmark_outline,
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
    );

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.school_outlined, color: brandOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  "Academic Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (isWide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: schoolTypeField),
                  const SizedBox(width: 16),
                  Expanded(child: schoolField),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: yearField),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _selectedSchoolType == 'University'
                        ? programTypeField
                        : const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: startYearField),
                  const SizedBox(width: 16),
                  Expanded(child: endYearField),
                ],
              ),
            ] else ...[
              schoolTypeField,
              const SizedBox(height: 16),
              schoolField,
              const SizedBox(height: 16),
              yearField,
              if (_selectedSchoolType == 'University') ...[
                const SizedBox(height: 16),
                programTypeField,
              ],
              const SizedBox(height: 16),
              startYearField,
              const SizedBox(height: 16),
              endYearField,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicsCard(bool isWide) {
    final Widget districtField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedDistrict,
      decoration: _getInputDecoration(
        labelText: "District",
        prefixIcon: Icons.map_outlined,
        helperText: "Select district in Malawi",
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
    );

    final Widget villageField = TextFormField(
      controller: _homeVillageController,
      decoration: _getInputDecoration(
        labelText: "Home Village",
        prefixIcon: Icons.home_outlined,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Please enter the home village";
        }
        return null;
      },
    );

    final Widget donorField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedDonor,
      decoration: _getInputDecoration(
        labelText: "Donor / Sponsor",
        prefixIcon: Icons.monetization_on_outlined,
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
    );

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.place_outlined, color: brandOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  "Demographics & Sponsorship",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (isWide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: districtField),
                  const SizedBox(width: 16),
                  Expanded(child: villageField),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: donorField),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ] else ...[
              districtField,
              const SizedBox(height: 16),
              villageField,
              const SizedBox(height: 16),
              donorField,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final double completion = _calculateCompletionPercentage();
    final bool isComplete = completion >= 1.0;

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitForm,
      icon: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.person_add_rounded, size: 20),
      label: Text(
        _isLoading ? "Registering..." : "Complete Scholar Registration",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: isComplete ? brandOlive : brandOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: (isComplete ? brandOlive : brandOrange).withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final double completion = _calculateCompletionPercentage();
    final int completed = _getCompletedFieldsCount();
    final int total = _getTotalFieldsCount();
    final String fullName = _fullNameController.text.trim();
    final String initials = _getInitials(fullName);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with banner removed (Clean Design)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: brandBrown.withValues(alpha: 0.1),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: brandBrown,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : "New Scholar Profile",
                        style: const TextStyle(
                          color: brandBrown,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedSchoolType != null
                            ? "$_selectedSchoolType Student"
                            : "Level not selected",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(completion),
              ],
            ),
          ),

          // Body of preview card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Academics Summary Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brandCreamDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, color: brandOrange, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Institution & Year",
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedSchool != null
                                  ? "$_selectedSchool (${_yearController.text.trim().isNotEmpty ? _yearController.text.trim() : 'Year TBD'})"
                                  : "Pending Assignment",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: brandBrown,
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
                const SizedBox(height: 20),

                // Grid of Details
                LayoutBuilder(
                    builder: (context, gridConstraints) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.wc,
                              "Sex",
                              _selectedSex ?? "",
                              brandOlive,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.cake_outlined,
                              "Date of Birth",
                              _dobController.text,
                              brandOrange,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.phone_outlined,
                              "Phone",
                              _phoneController.text.trim(),
                              brandBrown,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.email_outlined,
                              "Email",
                              _emailController.text.trim(),
                              brandOlive,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.map_outlined,
                              "District",
                              _selectedDistrict ?? "",
                              brandOlive,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.home_outlined,
                              "Home Village",
                              _homeVillageController.text.trim(),
                              brandOrange,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.monetization_on_outlined,
                              "Donor",
                              _selectedDonor ?? "",
                              brandBrown,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.calendar_today_outlined,
                              _selectedSchoolType == 'University' ? "Start Year" : "Session Start",
                              _selectedStartYear ?? "",
                              brandOlive,
                            ),
                          ),
                          SizedBox(
                            width: (gridConstraints.maxWidth - 16) / 2,
                            child: _buildPreviewDetailItem(
                              Icons.calendar_today_outlined,
                              _selectedSchoolType == 'University' ? "End Year" : "Session End",
                              _selectedEndYear ?? "",
                              brandOrange,
                            ),
                          ),
                        ],
                      );
                    }
                ),

                const Divider(height: 32),

                // Completion progress meter
                _buildCompletionMeter(completion, completed, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(double completion) {
    String text = "DRAFT";
    Color bg = Colors.grey.shade300;
    Color fg = Colors.grey.shade800;

    if (completion >= 1.0) {
      text = "READY";
      bg = brandOlive.withValues(alpha: 0.2);
      fg = brandOlive;
    } else if (completion >= 0.6) {
      text = "PROGRESS";
      bg = Colors.blue.withValues(alpha: 0.2);
      fg = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPreviewDetailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                value.isNotEmpty ? value : "Not specified",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: value.isNotEmpty ? brandBrown : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionMeter(double completion, int completed, int total) {
    Color progressColor = brandOrange;
    String message = "Drafting Profile";
    if (completion >= 1.0) {
      progressColor = brandOlive;
      message = "Complete & Ready";
    } else if (completion >= 0.6) {
      progressColor = Colors.blue;
      message = "Almost Ready";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
            ),
            Text(
              "${(completion * 100).toInt()}% ($completed of $total)",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandBrown),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completion,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}