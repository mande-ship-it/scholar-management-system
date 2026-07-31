import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

class RegisterScholarComponent extends StatefulWidget {
  final Function(Student)? onRegister;
  const RegisterScholarComponent({super.key, this.onRegister});

  @override
  State<RegisterScholarComponent> createState() => _RegisterScholarComponentState();
}

class _RegisterScholarComponentState extends State<RegisterScholarComponent> {
  final _formKey = GlobalKey<FormState>();

  // Brand Color Palette
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
  final TextEditingController _previousSchoolController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  // Guardian Controllers
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianPhoneController = TextEditingController();
  final TextEditingController _guardianEmailController = TextEditingController();
  final TextEditingController _guardianOccupationController = TextEditingController();

  // Data lists
  final List<String> _relations = ['Mother', 'Father', 'Uncle', 'Aunt', 'Grandmother', 'Grandfather', 'Sibling', 'Legal Guardian', 'Other'];
  String? _selectedGuardianRelation;

  // Validation patterns
  static final RegExp _malawiPhoneRegex = RegExp(r'^(?:\+265|0)[0-9]{9}$');
  static final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  final List<String> _districts = [
    'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa',
    'Dedza', 'Dowa', 'Karonga', 'Kasungu', 'Likoma',
    'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji', 'Mulanje',
    'Mwanza', 'Mzimba', 'Neno', 'Nkhata Bay', 'Nkhotakota',
    'Nsanje', 'Ntcheu', 'Ntchisi', 'Phalombe', 'Rumphi',
    'Salima', 'Thyolo', 'Zomba'
  ];

  final List<String> _schoolTypes = ['Secondary', 'University'];
  final List<String> _sexOptions = ['Female', 'Male', 'Other'];

  // Backend state
  List<Map<String, dynamic>> _registeredSchools = [];
  List<String> _registeredSponsors = [];
  bool _isLoadingSchools = false;
  bool _isLoadingSponsors = false;
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredSchools();
    _fetchRegisteredSponsors();
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

  Future<void> _fetchRegisteredSponsors() async {
    setState(() => _isLoadingSponsors = true);
    try {
      final response = await ApiService.getAllSponsors();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSponsors = data.map((s) => s['name'].toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching registered sponsors: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSponsors = false);
    }
  }

  List<Map<String, dynamic>> _getAvailableSchoolsForScholar() {
    if (_selectedSchoolType == null) return _registeredSchools;
    final typeLower = _selectedSchoolType!.toLowerCase();
    return _registeredSchools.where((school) {
      final level = (school['level'] ?? '').toString().toLowerCase();
      if (typeLower == 'secondary') {
        return level.contains('secondary') || level.contains('high') || level.contains('primary');
      } else if (typeLower == 'university') {
        return level.contains('university') || level.contains('tertiary') || level.contains('vocational');
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _yearController.dispose();
    _homeVillageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _previousSchoolController.dispose();
    _programNameController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianEmailController.dispose();
    _guardianOccupationController.dispose();
    super.dispose();
  }

  String? _validateMalawiPhone(String? value) {
    if (value == null || value.trim().isEmpty) return "Phone number is required";
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!_malawiPhoneRegex.hasMatch(cleaned)) return "Enter a valid Malawi number";
    return null;
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailRegex.hasMatch(value.trim())) return "Enter a valid email address";
    return null;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: brandBrown, onPrimary: Colors.white, onSurface: brandBrown)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final scholarData = {
        'fullName': _fullNameController.text.trim(),
        'schoolType': _selectedSchoolType,
        'schoolName': _selectedSchool,
        'schoolId': _selectedSchoolId != null ? int.tryParse(_selectedSchoolId!) : null,
        'sex': _selectedSex,
        'dob': _dobController.text.trim(),
        'currentClass': _yearController.text.trim(),
        'district': _selectedDistrict,
        'village': _homeVillageController.text.trim(),
        'donor': _selectedDonor,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'programType': _selectedProgramType,
        'programName': _programNameController.text.trim(),
        'startYear': _selectedStartYear,
        'endYear': _selectedEndYear,
        'previousSchool': _previousSchoolController.text.trim(),
        'guardianName': _guardianNameController.text.trim(),
        'guardianPhone': _guardianPhoneController.text.trim(),
        'guardianEmail': _guardianEmailController.text.trim(),
        'guardianRelation': _selectedGuardianRelation,
        'guardianOccupation': _guardianOccupationController.text.trim(),
      };

      try {
        final response = await ApiService.createScholar(scholarData);

        if (response.statusCode == 201) {
          final newScholar = response.data['data']['scholar'];
          final student = Student(
            id: newScholar['id'].toString(),
            scholarId: newScholar['scholar_id'].toString(),
            name: newScholar['full_name'] ?? _fullNameController.text.trim(),
            age: _selectedDateOfBirth != null ? DateTime.now().year - _selectedDateOfBirth!.year : 16,
            schoolType: _selectedSchoolType == 'University' ? SchoolType.university : SchoolType.secondary,
            schoolName: _selectedSchool ?? 'N/A',
            currentClass: _yearController.text.trim(),
            status: 'Pending',
            district: _selectedDistrict ?? 'Lilongwe',
            village: _homeVillageController.text.trim(),
            donor: _selectedDonor ?? 'General Fund',
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            sex: _selectedSex ?? 'Female',
            dob: _dobController.text.trim(),
            programType: _selectedProgramType ?? '',
            programName: _programNameController.text.trim(),
            previousSchool: _previousSchoolController.text.trim(),
            startYear: _selectedStartYear ?? '2026',
            endYear: _selectedEndYear ?? '2030',
          );

          kStudents.add(student);
          if (mounted) _showSuccessDialog(student);
        }
      } catch (e) {
        String msg = "An unexpected error occurred.";
        if (e is DioException) {
          if (e.response?.data != null && e.response?.data['message'] != null) {
            msg = e.response?.data['message'];
          } else {
            msg = "Connection failed. Please check your network.";
          }
        }
        _showErrorSnackBar(msg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  void _showSuccessDialog(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: brandOlive.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: brandOlive, size: 48)),
              const SizedBox(height: 20),
              const Text("Registration Complete", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBrown)),
              const SizedBox(height: 8),
              Text("Scholar ${student.name} has been successfully added.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    _rowDetail("Scholar ID", student.scholarId),
                    const Divider(height: 16),
                    _rowDetail("Institution", student.schoolName),
                    const Divider(height: 16),
                    _rowDetail("Class/Form", student.currentClass),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (widget.onRegister != null) {
                      widget.onRegister!(student);
                    } else {
                      _resetForm();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: brandOlive, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  child: const Text("Go to Registry", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowDetail(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)), Text(value, style: const TextStyle(fontSize: 12, color: brandBrown, fontWeight: FontWeight.bold))]);
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedDistrict = null; _selectedSchoolType = null; _selectedSchool = null; _selectedSchoolId = null; _selectedProgramType = null;
      _selectedDonor = null; _selectedSex = null; _selectedDateOfBirth = null; _selectedStartYear = null; _selectedEndYear = null;
      _fullNameController.clear(); _yearController.clear(); _homeVillageController.clear(); _phoneController.clear(); _emailController.clear();
      _dobController.clear(); _previousSchoolController.clear(); _programNameController.clear(); _guardianNameController.clear();
      _guardianPhoneController.clear(); _guardianEmailController.clear(); _selectedGuardianRelation = null; _guardianOccupationController.clear();
    });
  }

  InputDecoration _getInputDecoration({required String labelText, required IconData prefixIcon, String? helperText}) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, color: brandBrown.withValues(alpha: 0.7)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: brandOlive, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;
        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormHeader(),
                    const SizedBox(height: 40),
                    _sectionTitle("1. Basic Personal Information"),
                    const SizedBox(height: 16),
                    _buildPersonalDetailsCard(isWide),
                    const SizedBox(height: 32),
                    _sectionTitle("2. Parent or Guardian Information"),
                    const SizedBox(height: 16),
                    _buildGuardianDetailsCard(isWide),
                    const SizedBox(height: 32),
                    _sectionTitle("3. Academic & Institutional Details"),
                    const SizedBox(height: 16),
                    _buildAcademicDetailsCard(isWide),
                    const SizedBox(height: 32),
                    _sectionTitle("4. Demographics & Sponsorship"),
                    const SizedBox(height: 16),
                    _buildDemographicsCard(isWide),
                    const SizedBox(height: 48),
                    _buildSubmitButton(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandBrown, letterSpacing: 1.2)));
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: brandOlive.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_add_alt_1_rounded, color: brandOlive, size: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Register Scholar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBrown)),
                const SizedBox(height: 4),
                Text("Enter details below to create a new scholar record.", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(bool isWide) {
    final Widget nameField = TextFormField(controller: _fullNameController, decoration: _getInputDecoration(labelText: "Full Name", prefixIcon: Icons.person_outline), validator: (value) => (value == null || value.trim().isEmpty) ? "Name is required" : null);
    final Widget phoneField = TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _getInputDecoration(labelText: "Phone Number", prefixIcon: Icons.phone_outlined, helperText: "e.g. 0888123456"), validator: _validateMalawiPhone);
    final Widget emailField = TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _getInputDecoration(labelText: "Email Address (optional)", prefixIcon: Icons.email_outlined), validator: _validateOptionalEmail);
    final Widget sexField = DropdownButtonFormField<String>(isExpanded: true, initialValue: _selectedSex, decoration: _getInputDecoration(labelText: "Sex", prefixIcon: Icons.wc_outlined), items: _sexOptions.map((sex) => DropdownMenuItem<String>(value: sex, child: Text(sex))).toList(), onChanged: (value) => setState(() => _selectedSex = value), validator: (value) => value == null ? "Select sex" : null);
    final Widget dobField = TextFormField(controller: _dobController, readOnly: true, onTap: () => _selectDateOfBirth(context), decoration: _getInputDecoration(labelText: "Date of Birth", prefixIcon: Icons.cake_outlined).copyWith(suffixIcon: Icon(Icons.calendar_month_outlined, color: brandBrown.withValues(alpha: 0.7))), validator: (value) => (value == null || value.isEmpty) ? "Required" : null);

    return Card(
      elevation: 1, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: const [Icon(Icons.badge_outlined, color: brandOrange, size: 20), SizedBox(width: 8), Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown))]),
            const Divider(height: 24),
            if (isWide) ...[
              Row(children: [Expanded(child: nameField), const SizedBox(width: 16), Expanded(child: phoneField)]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: emailField), const SizedBox(width: 16), Expanded(child: sexField)]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: dobField), const SizedBox(width: 16), const Expanded(child: SizedBox())]),
            ] else ...[
              nameField, const SizedBox(height: 16), phoneField, const SizedBox(height: 16), emailField, const SizedBox(height: 16), sexField, const SizedBox(height: 16), dobField,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianDetailsCard(bool isWide) {
    final Widget gName = TextFormField(controller: _guardianNameController, decoration: _getInputDecoration(labelText: "Guardian Full Name", prefixIcon: Icons.supervisor_account_outlined), validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null);
    final Widget gRel = DropdownButtonFormField<String>(isExpanded: true, initialValue: _selectedGuardianRelation, decoration: _getInputDecoration(labelText: "Relationship", prefixIcon: Icons.family_restroom_outlined), items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => _selectedGuardianRelation = v), validator: (v) => v == null ? "Required" : null);
    final Widget gPhone = TextFormField(controller: _guardianPhoneController, keyboardType: TextInputType.phone, decoration: _getInputDecoration(labelText: "Guardian Phone", prefixIcon: Icons.phone_android_outlined), validator: _validateMalawiPhone);
    final Widget gEmail = TextFormField(controller: _guardianEmailController, keyboardType: TextInputType.emailAddress, decoration: _getInputDecoration(labelText: "Guardian Email (optional)", prefixIcon: Icons.email_outlined), validator: _validateOptionalEmail);
    final Widget gOcc = TextFormField(controller: _guardianOccupationController, decoration: _getInputDecoration(labelText: "Guardian Occupation", prefixIcon: Icons.work_outline));

    return Card(
      elevation: 1, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: const [Icon(Icons.gite_outlined, color: brandOrange, size: 20), SizedBox(width: 8), Text("Guardian Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown))]),
            const Divider(height: 24),
            if (isWide) ...[
              Row(children: [Expanded(child: gName), const SizedBox(width: 16), Expanded(child: gRel)]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: gPhone), const SizedBox(width: 16), Expanded(child: gEmail)]),
              const SizedBox(height: 16),
              gOcc,
            ] else ...[
              gName, const SizedBox(height: 16), gRel, const SizedBox(height: 16), gPhone, const SizedBox(height: 16), gEmail, const SizedBox(height: 16), gOcc,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicDetailsCard(bool isWide) {
    final List<String> years = academicYearOptions();

    final Widget startYear = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedStartYear,
      decoration: _getInputDecoration(labelText: "Start Year", prefixIcon: Icons.calendar_today),
      items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
      onChanged: (v) => setState(() => _selectedStartYear = v),
      validator: (v) => v == null ? "Required" : null
    );

    final Widget endYear = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedEndYear,
      decoration: _getInputDecoration(labelText: "End Year", prefixIcon: Icons.calendar_today),
      items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
      onChanged: (v) => setState(() => _selectedEndYear = v),
      validator: (v) => v == null ? "Required" : null
    );
    final Widget schoolType = DropdownButtonFormField<String>(isExpanded: true, initialValue: _selectedSchoolType, decoration: _getInputDecoration(labelText: "School Type", prefixIcon: Icons.category_outlined), items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) { setState(() { _selectedSchoolType = v; _selectedSchool = null; _selectedSchoolId = null; }); }, validator: (v) => v == null ? "Required" : null);
    
    final schools = _getAvailableSchoolsForScholar();
    final Widget school = DropdownButtonFormField<String>(
      isExpanded: true, initialValue: _selectedSchool,
      decoration: _getInputDecoration(labelText: _isLoadingSchools ? "Loading..." : "Institution", prefixIcon: Icons.school_outlined),
      items: schools.map((s) => DropdownMenuItem<String>(value: s['name'].toString(), child: Text(s['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) {
        setState(() {
          _selectedSchool = v;
          _selectedSchoolId = schools.firstWhere((s) => s['name'] == v)['id'].toString();
        });
      },
      validator: (v) => v == null ? "Required" : null,
    );

    final Widget year = TextFormField(controller: _yearController, decoration: _getInputDecoration(labelText: "Current Class / Year", prefixIcon: Icons.calendar_today_outlined), validator: (v) => (v == null || v.isEmpty) ? "Required" : null);
    final Widget prev = TextFormField(controller: _previousSchoolController, decoration: _getInputDecoration(labelText: "Previous Institution", prefixIcon: Icons.history_edu_outlined), validator: (v) => (v == null || v.isEmpty) ? "Required" : null);
    final Widget progType = DropdownButtonFormField<String>(isExpanded: true, initialValue: _selectedProgramType, decoration: _getInputDecoration(labelText: "Qualification", prefixIcon: Icons.bookmark_outline), items: const [DropdownMenuItem(value: "Degree", child: Text("Degree")), DropdownMenuItem(value: "Diploma", child: Text("Diploma")), DropdownMenuItem(value: "Certificate", child: Text("Certificate"))], onChanged: (v) => setState(() => _selectedProgramType = v));
    final Widget progName = TextFormField(controller: _programNameController, decoration: _getInputDecoration(labelText: "Program Name", prefixIcon: Icons.assignment_outlined));

    return Card(
      elevation: 1, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: const [Icon(Icons.school_outlined, color: brandOrange, size: 20), SizedBox(width: 8), Text("Academic Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown))]),
            const Divider(height: 24),
            if (isWide) ...[
              Row(children: [Expanded(child: schoolType), const SizedBox(width: 16), Expanded(child: school)]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: year), const SizedBox(width: 16), Expanded(child: prev)]),
              if (_selectedSchoolType == 'University') ...[
                const SizedBox(height: 16),
                Row(children: [Expanded(child: progType), const SizedBox(width: 16), Expanded(child: progName)]),
              ],
              const SizedBox(height: 16),
              Row(children: [Expanded(child: startYear), const SizedBox(width: 16), Expanded(child: endYear)]),
            ] else ...[
              schoolType, const SizedBox(height: 16), school, const SizedBox(height: 16), year, const SizedBox(height: 16), prev,
              if (_selectedSchoolType == 'University') ...[ const SizedBox(height: 16), progType, const SizedBox(height: 16), progName ],
              const SizedBox(height: 16), startYear, const SizedBox(height: 16), endYear,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicsCard(bool isWide) {
    final Widget district = DropdownButtonFormField<String>(isExpanded: true, initialValue: _selectedDistrict, decoration: _getInputDecoration(labelText: "District", prefixIcon: Icons.map_outlined), items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _selectedDistrict = v), validator: (v) => v == null ? "Required" : null);
    final Widget village = TextFormField(controller: _homeVillageController, decoration: _getInputDecoration(labelText: "Home Village", prefixIcon: Icons.home_outlined), validator: (v) => (v == null || v.isEmpty) ? "Required" : null);
    final Widget donor = DropdownButtonFormField<String>(isExpanded: true, initialValue: _selectedDonor, decoration: _getInputDecoration(labelText: "Donor / Sponsor", prefixIcon: Icons.monetization_on_outlined), items: _registeredSponsors.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _selectedDonor = v), validator: (v) => v == null ? "Required" : null);

    return Card(
      elevation: 1, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: const [Icon(Icons.place_outlined, color: brandOrange, size: 20), SizedBox(width: 8), Text("Sponsorship", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown))]),
            const Divider(height: 24),
            if (isWide) ...[
              Row(children: [Expanded(child: district), const SizedBox(width: 16), Expanded(child: village)]),
              const SizedBox(height: 16),
              donor,
            ] else ...[
              district, const SizedBox(height: 16), village, const SizedBox(height: 16), donor,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_add_rounded, size: 20),
        label: Text(_isLoading ? "Registering..." : "Complete Scholar Registration", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: brandOlive, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}
