import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class RegisterSchoolComponent extends StatefulWidget {
  final Function(Map<String, dynamic>)? onRegister;
  final Function()? onSuccess;
  const RegisterSchoolComponent({super.key, this.onRegister, this.onSuccess});

  @override
  State<RegisterSchoolComponent> createState() => _RegisterSchoolComponentState();
}

class _RegisterSchoolComponentState extends State<RegisterSchoolComponent> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminRoleController = TextEditingController();
  final TextEditingController _adminPhoneController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown States
  String? _selectedLevel;
  String? _selectedType;
  String? _selectedGenderType;
  String? _selectedRegion;
  String? _selectedDistrict;
  String? _assignedDistrict;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final userData = response.data['data'];
        _assignedDistrict = userData['assignedDistrict'];
        if (_assignedDistrict != null) {
          setState(() {
            _selectedDistrict = _assignedDistrict;
            // Auto-detect region if possible or leave for manual selection
          });
        }
      }
    } catch (e) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Options Lists
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
      'Chitipa', 'Karonga', 'Likoma', 'Mzimba', 'Nkhata Bay', 'Rumphi',
    ],
    'Central Region': [
      'Dedza', 'Dowa', 'Kasungu', 'Lilongwe', 'Mchinji', 'Nkhotakota',
      'Ntcheu', 'Ntchisi', 'Salima',
    ],
    'Southern Region': [
      'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Machinga', 'Mangochi',
      'Mulanje', 'Mwanza', 'Neno', 'Nsanje', 'Phalombe', 'Thyolo', 'Zomba',
    ],
  };

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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final schoolData = <String, dynamic>{
        'name': _nameController.text.trim(),
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

      try {
        final response = await ApiService.createSchool(schoolData);
        if (response.statusCode == 201) {
          if (mounted) {
            final savedSchool = response.data['data'];
            if (widget.onRegister != null) {
               widget.onRegister!(savedSchool);
            }
            _showSuccessDialog(savedSchool['name'], savedSchool['code']);
          }
        } else {
          _showErrorSnackBar(response.data['message'] ?? 'Failed to register school.');
        }
      } catch (e) {
        debugPrint('Error registering school: $e');
        _showErrorSnackBar('An error occurred. Please check your connection.');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String name, String code) {
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
                decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.domain_verification_rounded, color: kBrandOlive, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("Institutional Registry Updated", textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
              const SizedBox(height: 12),
              Text("School '$name' has been assigned code '$code' and is now active in the system.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (widget.onSuccess != null) {
                      widget.onSuccess!();
                    } else {
                      _resetForm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("CLOSE & CONTINUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedLevel = null;
      _selectedType = null;
      _selectedGenderType = null;
      _selectedRegion = null;
      _selectedDistrict = null;
      _nameController.clear();
      _codeController.clear();
      _addressController.clear();
      _phoneController.clear();
      _altPhoneController.clear();
      _emailController.clear();
      _postalController.clear();
      _websiteController.clear();
      _adminNameController.clear();
      _adminRoleController.clear();
      _adminPhoneController.clear();
      _adminEmailController.clear();
      _descriptionController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildExecutiveHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel("ACADEMIC IDENTITY"),
                    const SizedBox(height: 24),
                    _buildIdentitySection(isMobile),

                    const SizedBox(height: 32),
                    _buildSectionLabel("GEOGRAPHIC PLACEMENT"),
                    const SizedBox(height: 24),
                    _buildLocationSection(isMobile),

                    const SizedBox(height: 32),
                    _buildSectionLabel("COMMUNICATION & CHANNELS"),
                    const SizedBox(height: 24),
                    _buildContactSection(isMobile),

                    const SizedBox(height: 32),
                    _buildSectionLabel("ADMINISTRATION & LEADERSHIP"),
                    const SizedBox(height: 24),
                    _buildAdminSection(isMobile),

                    const SizedBox(height: 48),
                    _buildSubmitAction(isMobile),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
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
            decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.domain_add_rounded, color: kBrandBrown, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Register New Institution", 
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text("Enter comprehensive administrative and academic profiles for school onboarding.", 
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive.withValues(alpha: 0.8), letterSpacing: 1.5));
  }

  Widget _buildIdentitySection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        _buildTextField(_nameController, "School Name / Title", Icons.edit_outlined, required: true),
        const SizedBox(height: 24),
        if (isMobile) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedLevel,
            decoration: _inputDeco("Education Level", Icons.layers_outlined),
            items: _schoolLevels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) => setState(() => _selectedLevel = v),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: _inputDeco("School Category", Icons.account_balance_outlined),
            items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: (v) => setState(() => _selectedType = v),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: _inputDeco("Education Level", Icons.layers_outlined),
                  items: _schoolLevels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) => setState(() => _selectedLevel = v),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: _inputDeco("School Category", Icons.account_balance_outlined),
                  items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedRegion,
            decoration: _inputDeco("Region", Icons.map_outlined),
            items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: _assignedDistrict != null ? null : (v) => setState(() {
              _selectedRegion = v;
              _selectedDistrict = null;
            }),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            key: ValueKey('mobile_$_selectedRegion$_assignedDistrict'),
            initialValue: _selectedDistrict,
            decoration: _inputDeco(
              _assignedDistrict != null ? "Assigned District (Locked)" : "District", 
              Icons.my_location_outlined
            ).copyWith(
              helperText: _assignedDistrict != null ? "Monitoring restricted to $_assignedDistrict." : null,
              helperStyle: const TextStyle(color: kBrandOrange, fontWeight: FontWeight.bold, fontSize: 10),
            ),
            items: _assignedDistrict != null 
              ? [DropdownMenuItem(value: _assignedDistrict, child: Text(_assignedDistrict!, style: const TextStyle(fontWeight: FontWeight.w600)))]
              : _activeDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: _assignedDistrict != null ? null : (v) => setState(() => _selectedDistrict = v),
            validator: (v) => v == null ? "Required" : null,
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  decoration: _inputDeco("Region", Icons.map_outlined),
                  items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: _assignedDistrict != null ? null : (v) => setState(() {
                    _selectedRegion = v;
                    _selectedDistrict = null;
                  }),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('$_selectedRegion$_assignedDistrict'),
                  initialValue: _selectedDistrict,
                  decoration: _inputDeco(
                    _assignedDistrict != null ? "Assigned District (Locked)" : "District", 
                    Icons.my_location_outlined
                  ).copyWith(
                    helperText: _assignedDistrict != null ? "Monitoring restricted to $_assignedDistrict." : null,
                    helperStyle: const TextStyle(color: kBrandOrange, fontWeight: FontWeight.bold),
                  ),
                  items: _assignedDistrict != null 
                    ? [DropdownMenuItem(value: _assignedDistrict, child: Text(_assignedDistrict!, style: const TextStyle(fontWeight: FontWeight.w600)))]
                    : _activeDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: _assignedDistrict != null ? null : (v) => setState(() => _selectedDistrict = v),
                  validator: (v) => v == null ? "Required" : null,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildTextField(_addressController, "Physical Address / Landmarks", Icons.home_outlined, maxLines: 2),
      ],
    );
  }

  Widget _buildContactSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildTextField(_phoneController, "Primary Phone", Icons.phone_outlined),
          const SizedBox(height: 24),
          _buildTextField(_emailController, "Institutional Email", Icons.alternate_email_rounded),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildTextField(_phoneController, "Primary Phone", Icons.phone_outlined)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_emailController, "Institutional Email", Icons.alternate_email_rounded)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildTextField(_websiteController, "Website URL (Optional)", Icons.language_outlined),
      ],
    );
  }

  Widget _buildAdminSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildTextField(_adminNameController, "Admin Contact Name", Icons.person_outline),
          const SizedBox(height: 24),
          _buildTextField(_adminRoleController, "Designation", Icons.work_outline),
          const SizedBox(height: 24),
          _buildTextField(_adminPhoneController, "Direct Admin Phone", Icons.phone_android_outlined),
          const SizedBox(height: 24),
          _buildTextField(_adminEmailController, "Direct Admin Email", Icons.email_outlined),
        ] else ...[
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField(_adminNameController, "Admin Contact Name", Icons.person_outline)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_adminRoleController, "Designation", Icons.work_outline)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField(_adminPhoneController, "Direct Admin Phone", Icons.phone_android_outlined)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_adminEmailController, "Direct Admin Email", Icons.email_outlined)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitAction(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _submitForm,
        icon: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.domain_verification_rounded, size: 20),
        label: Text(_isSaving ? "PROCESSING..." : "FINALIZE INSTITUTIONAL REGISTRATION", 
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 11 : 13, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandOlive,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _executiveCard({required List<Widget> children, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
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
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withValues(alpha: 0.4)),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
