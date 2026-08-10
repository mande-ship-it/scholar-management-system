import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

typedef OnScholarRegistered = Future<void> Function(Student scholar);

class RegisterScholarComponent extends StatefulWidget {
  final OnScholarRegistered? onRegister;
  final String? forcedSchoolType;
  const RegisterScholarComponent({super.key, this.onRegister, this.forcedSchoolType});

  @override
  State<RegisterScholarComponent> createState() => _RegisterScholarComponentState();
}

class _RegisterScholarComponentState extends State<RegisterScholarComponent> {
  final _formKey = GlobalKey<FormState>();

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
  int? _selectedDuration;

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
  List<Map<String, dynamic>> _registeredSponsors = [];
  bool _isLoadingSchools = false;
  bool _isLoadingSponsors = false;
  String? _selectedSchoolId;
  String? _selectedSponsorId;
  String? _assignedDistrict; // From user profile

  @override
  void initState() {
    super.initState();
    _selectedSchoolType = widget.forcedSchoolType;
    _fetchProfileAndData();
    for (final c in [_fullNameController, _yearController, _phoneController, _emailController]) {
      c.addListener(() => setState(() {}));
    }
  }

  Future<void> _fetchProfileAndData() async {
    setState(() => _isLoading = true);
    try {
      final profileRes = await ApiService.getAccountProfile();
      if (profileRes.statusCode == 200) {
        final userData = profileRes.data['data'];
        _assignedDistrict = userData['assignedDistrict'];
        if (_assignedDistrict != null) {
          setState(() {
            _selectedDistrict = _assignedDistrict;
          });
        }
      }
      await Future.wait([
        _fetchRegisteredSchools(),
        _fetchRegisteredSponsors(),
      ]);
    } catch (e) {
      debugPrint('Error during initialization: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            _registeredSponsors = data.map((s) => Map<String, dynamic>.from(s)).toList();
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
    if (_selectedSchoolType == null) return [];

    final typeLower = _selectedSchoolType!.toLowerCase();
    return _registeredSchools.where((school) {
      final level = (school['level'] ?? '').toString().toLowerCase();

      if (typeLower == 'secondary') {
        // Match Secondary type to schools with Secondary or High School level
        return level.contains('secondary') || level.contains('high');
      } else if (typeLower == 'university') {
        // Match University type to schools with University, Tertiary or College level
        return level.contains('university') || level.contains('tertiary') || level.contains('college');
      }
      return false;
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
    if (value == null || value.trim().isEmpty) return null; // Make phone optional
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
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kBrandBrown, onPrimary: Colors.white, onSurface: kBrandBrown)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _updateGraduationYear() {
    if (_selectedStartYear != null && _selectedDuration != null) {
      final start = int.parse(_selectedStartYear!);
      setState(() {
        _selectedEndYear = (start + _selectedDuration! - 1).toString();
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
        'schoolId': _selectedSchoolId,
        'sponsorId': _selectedSponsorId,
        'sex': _selectedSex,
        'dob': _dobController.text.trim(),
        'registeredClass': _yearController.text.trim(), // Spec Section 1
        'programDurationYears': _selectedDuration ?? 4, // Spec Section 1
        'academicYear': _yearController.text.trim(),
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
        'status': 'Pending', // Explicitly set for workflow clarity
      };

      try {
        final response = await ApiService.createScholar(scholarData);

        if (response.statusCode == 201) {
          final student = Student.fromMap(response.data['data']);

          if (widget.onRegister != null) {
            await widget.onRegister!(student);
          }
          if (mounted) _showSuccessDialog(student);
        } else {
          _showErrorSnackBar(response.data['message'] ?? "Registration failed.");
        }
      } catch (e) {
        String msg = "An unexpected error occurred.";
        if (e is DioException) {
          msg = e.response?.data['message'] ?? "Connection failed.";
        }
        _showErrorSnackBar(msg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessDialog(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.school_rounded, color: kBrandOlive, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("Enrolment Submitted", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
              const SizedBox(height: 12),
              Text("Scholar '${student.name}' has been successfully registered and is currently AWAITING APPROVAL by the program management.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("RETURN TO REGISTRY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDistrict = null; _selectedSchoolType = null; _selectedSchool = null; _selectedSchoolId = null; _selectedProgramType = null;
      _selectedDonor = null; _selectedSex = null; _selectedDateOfBirth = null; _selectedStartYear = null; _selectedEndYear = null;
      _fullNameController.clear(); _yearController.clear(); _homeVillageController.clear(); _phoneController.clear(); _emailController.clear();
      _dobController.clear(); _previousSchoolController.clear(); _programNameController.clear(); _guardianNameController.clear();
      _guardianPhoneController.clear(); _guardianEmailController.clear(); _selectedGuardianRelation = null; _guardianOccupationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionPortalHeader("PERSONAL IDENTITY", Icons.person_outline_rounded),
                        const SizedBox(height: 24),
                        _buildPersonalSection(isMobile),

                        const SizedBox(height: 48),
                        _sectionPortalHeader("GUARDIANSHIP & CONTACT", Icons.supervisor_account_rounded),
                        const SizedBox(height: 24),
                        _buildGuardianSection(isMobile),

                        const SizedBox(height: 48),
                        _sectionPortalHeader("ACADEMIC PLACEMENT", Icons.school_outlined),
                        const SizedBox(height: 24),
                        _buildAcademicSection(isMobile),

                        const SizedBox(height: 48),
                        _sectionPortalHeader("ORIGIN & SPONSORSHIP", Icons.map_outlined),
                        const SizedBox(height: 24),
                        _buildDemographicsSection(isMobile),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildPortalFixedFooter(isMobile),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              "Scholar Enrolment",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          IconButton(
            onPressed: _resetForm,
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Reset Form",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _sectionPortalHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          title, 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            color: Colors.grey.shade500, 
            letterSpacing: 1.2
          )
        ),
      ],
    );
  }

  Widget _buildPortalFixedFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isMobile) ...[
            TextButton(
              onPressed: () => _resetForm(),
              child: const Text("CLEAR ALL FIELDS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
            ),
            const SizedBox(width: 24),
          ],
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitForm,
            icon: _isLoading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.how_to_reg_rounded, size: 18),
            label: Text(_isLoading ? "AUDITING..." : "FINALIZE REGISTRATION",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C3C32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(bool isMobile) {
    return isMobile ? const Divider(height: 1) : const SizedBox.shrink();
  }

  Widget _buildFixedFooter(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isMobile) ...[
            OutlinedButton(
              onPressed: () => _resetForm(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: Colors.grey,
              ),
              child: const Text("DISCARD DRAFT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_user_rounded, size: 18),
              label: Text(_isLoading ? "PROCESSING..." : "FINALIZE ENROLMENT",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          if (isMobile) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _resetForm(),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Discard Draft",
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person_add_alt_1_rounded, color: kBrandBrown, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Register New Scholar", 
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text("Enrol a new student into the scholarship management ecosystem.", 
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive.withOpacity(0.8), letterSpacing: 1.5));
  }

  Widget _buildPersonalSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        _buildTextField(_fullNameController, "Full Legal Name", Icons.person_outline, required: true),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildTextField(_phoneController, "Primary Phone Number", Icons.phone_outlined),
          const SizedBox(height: 24),
          _buildTextField(_emailController, "Personal Email Address", Icons.alternate_email_rounded),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedSex,
            decoration: _inputDeco("Sex / Gender", Icons.wc_outlined),
            items: _sexOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) => setState(() => _selectedSex = v),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDateOfBirth(context),
            style: const TextStyle(fontWeight: FontWeight.w600, color: kBrandBrown),
            decoration: _inputDeco("Date of Birth", Icons.calendar_today_rounded),
            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          ),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildTextField(_phoneController, "Primary Phone Number", Icons.phone_outlined)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_emailController, "Personal Email Address", Icons.alternate_email_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSex,
                  decoration: _inputDeco("Sex / Gender", Icons.wc_outlined),
                  items: _sexOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) => setState(() => _selectedSex = v),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDateOfBirth(context),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kBrandBrown),
                  decoration: _inputDeco("Date of Birth", Icons.calendar_today_rounded),
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGuardianSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildTextField(_guardianNameController, "Guardian Full Name", Icons.supervisor_account_outlined, required: true),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedGuardianRelation,
            decoration: _inputDeco("Relationship", Icons.family_restroom_outlined),
            items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) => setState(() => _selectedGuardianRelation = v),
          ),
          const SizedBox(height: 24),
          _buildTextField(_guardianPhoneController, "Guardian Phone", Icons.phone_android_outlined),
          const SizedBox(height: 24),
          _buildTextField(_guardianEmailController, "Guardian Email", Icons.email_outlined),
        ] else ...[
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField(_guardianNameController, "Guardian Full Name", Icons.supervisor_account_outlined, required: true)),
              const SizedBox(width: 24),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedGuardianRelation,
                  decoration: _inputDeco("Relationship", Icons.family_restroom_outlined),
                  items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) => setState(() => _selectedGuardianRelation = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField(_guardianPhoneController, "Guardian Phone", Icons.phone_android_outlined)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_guardianEmailController, "Guardian Email", Icons.email_outlined)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildTextField(_guardianOccupationController, "Guardian Occupation", Icons.work_outline),
      ],
    );
  }

  Widget _buildAcademicSection(bool isMobile) {
    final List<String> years = academicYearOptions();
    final schools = _getAvailableSchoolsForScholar();
    final int currentYear = DateTime.now().year;

    bool showClassField = true;
    if (_selectedEndYear != null) {
      final int endY = int.tryParse(_selectedEndYear!) ?? 0;
      if (endY < currentYear) {
        showClassField = false;
      }
    }

    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          IgnorePointer(
            ignoring: widget.forcedSchoolType != null,
            child: Opacity(
              opacity: widget.forcedSchoolType != null ? 0.7 : 1.0,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSchoolType,
                decoration: _inputDeco("Level of Study", Icons.category_outlined),
                items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedSchoolType = v;
                    _selectedSchool = null;
                    _selectedSchoolId = null;
                  });
                },
                validator: (v) => v == null ? "Required" : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            key: ValueKey('school_name_mobile_$_selectedSchoolType'),
            initialValue: _selectedSchool,
            isExpanded: true,
            decoration: _inputDeco(
              _isLoadingSchools 
                ? "Loading Institutions..." 
                : (schools.isEmpty && _selectedSchoolType != null ? "No matching schools found" : "Institution Name"), 
              Icons.school_outlined
            ),
            items: schools.map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'].toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedSchool = v;
                try {
                  final found = schools.firstWhere((s) => s['name'] == v);
                  _selectedSchoolId = (found['id'] ?? found['_id'] ?? found['scholar_id']).toString();
                } catch (_) {
                  _selectedSchoolId = null;
                }
              });
            },
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedStartYear,
            decoration: _inputDeco("Enrolment Year", Icons.event_available_rounded),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedStartYear = v;
                _updateGraduationYear();
              });
            },
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            initialValue: _selectedDuration,
            decoration: _inputDeco("Program Duration", Icons.timer_outlined),
            items: [1, 2, 3, 4, 5, 6].map((d) => DropdownMenuItem(value: d, child: Text("$d Years", style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedDuration = v;
                _updateGraduationYear();
              });
            },
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            key: ValueKey('end_year_mobile_${_selectedStartYear}_$_selectedDuration'),
            initialValue: _selectedEndYear,
            decoration: _inputDeco("Expected Graduation", Icons.event_busy_rounded),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) => setState(() => _selectedEndYear = v),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: IgnorePointer(
                  ignoring: widget.forcedSchoolType != null,
                  child: Opacity(
                    opacity: widget.forcedSchoolType != null ? 0.7 : 1.0,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSchoolType,
                      decoration: _inputDeco("Level of Study", Icons.category_outlined),
                      items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedSchoolType = v;
                          _selectedSchool = null;
                          _selectedSchoolId = null;
                        });
                      },
                      validator: (v) => v == null ? "Required" : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('school_name_$_selectedSchoolType'),
                  initialValue: _selectedSchool,
                  isExpanded: true,
                  decoration: _inputDeco(
                    _isLoadingSchools 
                      ? "Loading Institutions..." 
                      : (schools.isEmpty && _selectedSchoolType != null ? "No matching schools found" : "Institution Name"), 
                    Icons.school_outlined
                  ),
                  items: schools.map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'].toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedSchool = v;
                      try {
                        final found = schools.firstWhere((s) => s['name'] == v);
                        _selectedSchoolId = (found['id'] ?? found['_id'] ?? found['scholar_id']).toString();
                      } catch (_) {
                        _selectedSchoolId = null;
                      }
                    });
                  },
                  validator: (v) => v == null ? "Required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStartYear,
                  decoration: _inputDeco("Enrolment Year", Icons.event_available_rounded),
                  items: years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedStartYear = v;
                      _updateGraduationYear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedDuration,
                  decoration: _inputDeco("Program Duration", Icons.timer_outlined),
                  items: [1, 2, 3, 4, 5, 6].map((d) => DropdownMenuItem(value: d, child: Text("$d Years", style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedDuration = v;
                      _updateGraduationYear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('end_year_${_selectedStartYear}_$_selectedDuration'),
                  initialValue: _selectedEndYear,
                  decoration: _inputDeco("Expected Graduation", Icons.event_busy_rounded),
                  items: years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) => setState(() => _selectedEndYear = v),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (isMobile) ...[
          if (showClassField) ...[
            _buildTextField(_yearController, "Current Form / Class", Icons.calendar_month_rounded),
            const SizedBox(height: 24),
          ],
          _buildTextField(_previousSchoolController, "Previous Institution", Icons.history_edu_rounded),
        ] else ...[
          if (showClassField)
            Row(
              children: [
                Expanded(child: _buildTextField(_yearController, "Current Form / Class", Icons.calendar_month_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _buildTextField(_previousSchoolController, "Previous Institution", Icons.history_edu_rounded)),
              ],
            )
          else
            _buildTextField(_previousSchoolController, "Previous Institution", Icons.history_edu_rounded),
        ],
        if (_selectedSchoolType == 'University') ...[
          const SizedBox(height: 24),
          if (isMobile) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedProgramType,
              decoration: _inputDeco("Qualification", Icons.bookmark_outline_rounded),
              items: const [
                DropdownMenuItem(value: "Degree", child: Text("Degree", style: TextStyle(fontWeight: FontWeight.w600))),
                DropdownMenuItem(value: "Diploma", child: Text("Diploma", style: TextStyle(fontWeight: FontWeight.w600))),
                DropdownMenuItem(value: "Certificate", child: Text("Certificate", style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              onChanged: (v) => setState(() => _selectedProgramType = v),
            ),
            const SizedBox(height: 24),
            _buildTextField(_programNameController, "Specific Course Name", Icons.assignment_outlined),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedProgramType,
                    decoration: _inputDeco("Qualification", Icons.bookmark_outline_rounded),
                    items: const [
                      DropdownMenuItem(value: "Degree", child: Text("Degree", style: TextStyle(fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: "Diploma", child: Text("Diploma", style: TextStyle(fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: "Certificate", child: Text("Certificate", style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    onChanged: (v) => setState(() => _selectedProgramType = v),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: _buildTextField(_programNameController, "Specific Course Name", Icons.assignment_outlined)),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDemographicsSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedDistrict,
            decoration: _inputDeco(
              _assignedDistrict != null ? "Assigned District (Locked)" : "District of Origin",
              Icons.map_outlined
            ).copyWith(
              helperText: _assignedDistrict != null ? "Locked to your monitoring district." : null,
              helperStyle: const TextStyle(color: kBrandOrange, fontWeight: FontWeight.bold, fontSize: 10),
            ),
            items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: _assignedDistrict != null ? null : (v) => setState(() => _selectedDistrict = v),
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 24),
          _buildTextField(_homeVillageController, "Home Village / T.A.", Icons.home_outlined),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  decoration: _inputDeco(
                    _assignedDistrict != null ? "Assigned District (Locked)" : "District of Origin",
                    Icons.map_outlined
                  ).copyWith(
                    helperText: _assignedDistrict != null ? "Registration is restricted to your monitoring district." : null,
                    helperStyle: const TextStyle(color: kBrandOrange, fontWeight: FontWeight.bold),
                  ),
                  items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: _assignedDistrict != null ? null : (v) => setState(() => _selectedDistrict = v),
                  validator: (v) => v == null ? "Required" : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_homeVillageController, "Home Village / T.A.", Icons.home_outlined)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: _selectedDonor,
          decoration: _inputDeco(_isLoadingSponsors ? "Loading Sponsors..." : "Assigned Program Donor", Icons.monetization_on_outlined),
          items: _registeredSponsors.map((d) => DropdownMenuItem(value: d['name'].toString(), child: Text(d['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          onChanged: (v) {
            setState(() {
              _selectedDonor = v;
              try {
                final found = _registeredSponsors.firstWhere((s) => s['name'] == v);
                _selectedSponsorId = (found['id'] ?? found['_id']).toString();
              } catch (_) {
                _selectedSponsorId = null;
              }
            });
          },
        ),
      ],
    );
  }


  Widget _executiveCard({required List<Widget> children, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, color: kBrandBrown),
      decoration: _inputDeco(label, icon),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? "Required Field" : null : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.4)),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
