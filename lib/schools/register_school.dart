import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterSchoolComponent extends StatefulWidget {
  const RegisterSchoolComponent({super.key});

  @override
  State<RegisterSchoolComponent> createState() => _RegisterSchoolComponentState();
}

class _RegisterSchoolComponentState extends State<RegisterSchoolComponent> {
  final _formKey = GlobalKey<FormState>();

  // Brand Color Palette
  static const Color brandBrown = Color(0xFF4C3C32);
  static const Color brandCream = Color(0xFFFAF2DB);
  static const Color brandCreamDark = Color(0xFFF3E7C4);
  static const Color brandOlive = Color(0xFF9AB334);
  static const Color brandOrange = Color(0xFFE05B1C);

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
  bool _isSaving = false;

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

  // Required fields count for progress bar
  int _getTotalFieldsCount() => 9;

  int _getCompletedFieldsCount() {
    int count = 0;
    if (_nameController.text.trim().isNotEmpty) count++;
    if (_codeController.text.trim().isNotEmpty) count++;
    if (_selectedLevel != null) count++;
    if (_selectedType != null) count++;
    if (_selectedGenderType != null) count++;
    if (_selectedRegion != null) count++;
    if (_selectedDistrict != null) count++;
    if (_phoneController.text.trim().isNotEmpty) count++;
    if (_emailController.text.trim().isNotEmpty) count++;
    return count;
  }

  double _calculateCompletionPercentage() {
    final int total = _getTotalFieldsCount();
    if (total == 0) return 0.0;
    return _getCompletedFieldsCount() / total;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final schoolData = <String, dynamic>{
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

      try {
        final response = await ApiService.createSchool(schoolData);
        if (response.statusCode == 201) {
          if (mounted) {
            _showSuccessDialog(_nameController.text.trim(), _codeController.text.trim());
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String name, String code) {
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
                  "School $name has been successfully added to the registry.",
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
                      _rowDetail("School Code", code),
                      const Divider(height: 16),
                      _rowDetail("Level", _selectedLevel ?? 'N/A'),
                      const Divider(height: 16),
                      _rowDetail("District", _selectedDistrict ?? 'N/A'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("School registered. Visit the Schools Registry to view details."),
                          backgroundColor: brandOlive,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text("Go to Schools Registry", style: TextStyle(fontWeight: FontWeight.bold)),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;

        return SingleChildScrollView(
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

                  _sectionTitle("1. School Identity & Classification"),
                  const SizedBox(height: 16),
                  _buildIdentityCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("2. Geographic Location"),
                  const SizedBox(height: 16),
                  _buildLocationCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("3. Contact Information"),
                  const SizedBox(height: 16),
                  _buildContactCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("4. Administration & Management"),
                  const SizedBox(height: 16),
                  _buildAdminCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("5. Additional Details"),
                  const SizedBox(height: 16),
                  _buildAdditionalInfoCard(),

                  const SizedBox(height: 48),
                  _buildSubmitButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: brandBrown,
          letterSpacing: 1.2,
        ),
      ),
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
            child: const Icon(Icons.domain_add_rounded, color: brandOlive, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Register School",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBrown),
                ),
                const SizedBox(height: 4),
                Text(
                  "Enter comprehensive details to register a new school partner.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardShell({required String title, required IconData icon, required List<Widget> children}) {
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
              children: [
                Icon(icon, color: brandOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(bool isWide) {
    final nameField = TextFormField(
      controller: _nameController,
      decoration: _getInputDecoration(labelText: "School Name / Title", prefixIcon: Icons.edit_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter school name" : null,
    );

    final codeField = TextFormField(
      controller: _codeController,
      decoration: _getInputDecoration(labelText: "School Code / ID", prefixIcon: Icons.pin_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter code" : null,
    );

    final levelField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedLevel,
      decoration: _getInputDecoration(labelText: "Education Level", prefixIcon: Icons.layers_outlined),
      items: _schoolLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
      onChanged: (v) => setState(() => _selectedLevel = v),
      validator: (v) => v == null ? "Select level" : null,
    );

    final typeField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedType,
      decoration: _getInputDecoration(labelText: "School Type / Agency", prefixIcon: Icons.account_balance_outlined),
      items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _selectedType = v),
      validator: (v) => v == null ? "Select type" : null,
    );

    final genderField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedGenderType,
      decoration: _getInputDecoration(labelText: "Gender Policy", prefixIcon: Icons.wc_outlined),
      items: _genderTypes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (v) => setState(() => _selectedGenderType = v),
      validator: (v) => v == null ? "Select policy" : null,
    );

    return _buildCardShell(
      title: "Identity Information",
      icon: Icons.badge_outlined,
      children: [
        if (isWide) ...[
          Row(
            children: [
              Expanded(flex: 2, child: nameField),
              const SizedBox(width: 16),
              Expanded(child: codeField),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: levelField),
              const SizedBox(width: 16),
              Expanded(child: typeField),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: genderField),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
        ] else ...[
          nameField,
          const SizedBox(height: 16),
          codeField,
          const SizedBox(height: 16),
          levelField,
          const SizedBox(height: 16),
          typeField,
          const SizedBox(height: 16),
          genderField,
        ]
      ],
    );
  }

  Widget _buildLocationCard(bool isWide) {
    final regionField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedRegion,
      decoration: _getInputDecoration(labelText: "Region", prefixIcon: Icons.map_outlined),
      items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (v) => setState(() {
        _selectedRegion = v;
        _selectedDistrict = null;
      }),
      validator: (v) => v == null ? "Select region" : null,
    );

    final districtField = DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey(_selectedRegion),
      initialValue: _selectedDistrict,
      decoration: _getInputDecoration(
        labelText: _selectedRegion == null ? "District (Select Region first)" : "District",
        prefixIcon: Icons.my_location_outlined,
        enabled: _selectedRegion != null,
      ),
      items: _activeDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
      onChanged: _selectedRegion == null ? null : (v) => setState(() => _selectedDistrict = v),
      validator: (v) => v == null ? "Select district" : null,
    );

    final addressField = TextFormField(
      controller: _addressController,
      maxLines: 2,
      decoration: _getInputDecoration(labelText: "Physical Address / Landmarks", prefixIcon: Icons.home_outlined),
    );

    return _buildCardShell(
      title: "Location Details",
      icon: Icons.place_outlined,
      children: [
        if (isWide) ...[
          Row(
            children: [
              Expanded(child: regionField),
              const SizedBox(width: 16),
              Expanded(child: districtField),
            ],
          ),
          const SizedBox(height: 16),
          addressField,
        ] else ...[
          regionField,
          const SizedBox(height: 16),
          districtField,
          const SizedBox(height: 16),
          addressField,
        ]
      ],
    );
  }

  Widget _buildContactCard(bool isWide) {
    final phoneField = TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _getInputDecoration(labelText: "Primary Phone", prefixIcon: Icons.phone_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter primary phone" : null,
    );

    final altPhoneField = TextFormField(
      controller: _altPhoneController,
      keyboardType: TextInputType.phone,
      decoration: _getInputDecoration(labelText: "Alternative Phone", prefixIcon: Icons.phone_android_outlined),
    );

    final emailField = TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _getInputDecoration(labelText: "School Email", prefixIcon: Icons.email_outlined),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Enter email";
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return "Enter valid email";
        return null;
      },
    );

    final postalField = TextFormField(
      controller: _postalController,
      decoration: _getInputDecoration(labelText: "Postal Address", prefixIcon: Icons.local_post_office_outlined),
    );

    final websiteField = TextFormField(
      controller: _websiteController,
      keyboardType: TextInputType.url,
      decoration: _getInputDecoration(
        labelText: "Website URL",
        prefixIcon: Icons.language_outlined,
        helperText: "e.g. www.school.com",
      ),
    );

    return _buildCardShell(
      title: "Contact Information",
      icon: Icons.contact_phone_outlined,
      children: [
        if (isWide) ...[
          Row(
            children: [
              Expanded(child: phoneField),
              const SizedBox(width: 16),
              Expanded(child: altPhoneField),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: emailField),
              const SizedBox(width: 16),
              Expanded(child: postalField),
            ],
          ),
          const SizedBox(height: 16),
          websiteField,
        ] else ...[
          phoneField,
          const SizedBox(height: 16),
          altPhoneField,
          const SizedBox(height: 16),
          emailField,
          const SizedBox(height: 16),
          postalField,
          const SizedBox(height: 16),
          websiteField,
        ]
      ],
    );
  }

  Widget _buildAdminCard(bool isWide) {
    final adminNameField = TextFormField(
      controller: _adminNameController,
      decoration: _getInputDecoration(labelText: "Contact Full Name", prefixIcon: Icons.person_outline),
    );

    final adminRoleField = TextFormField(
      controller: _adminRoleController,
      decoration: _getInputDecoration(
        labelText: "Designation",
        prefixIcon: Icons.work_outline,
        helperText: "e.g. Principal",
      ),
    );

    final adminPhoneField = TextFormField(
      controller: _adminPhoneController,
      keyboardType: TextInputType.phone,
      decoration: _getInputDecoration(labelText: "Contact Phone", prefixIcon: Icons.phone_android_outlined),
    );

    final adminEmailField = TextFormField(
      controller: _adminEmailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _getInputDecoration(labelText: "Contact Email", prefixIcon: Icons.email_outlined),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return "Enter valid email";
        }
        return null;
      },
    );

    return _buildCardShell(
      title: "Administration Details",
      icon: Icons.supervisor_account_outlined,
      children: [
        if (isWide) ...[
          Row(
            children: [
              Expanded(flex: 2, child: adminNameField),
              const SizedBox(width: 16),
              Expanded(child: adminRoleField),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: adminPhoneField),
              const SizedBox(width: 16),
              Expanded(child: adminEmailField),
            ],
          ),
        ] else ...[
          adminNameField,
          const SizedBox(height: 16),
          adminRoleField,
          const SizedBox(height: 16),
          adminPhoneField,
          const SizedBox(height: 16),
          adminEmailField,
        ]
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    return _buildCardShell(
      title: "Additional Details",
      icon: Icons.info_outline,
      children: [
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: _getInputDecoration(labelText: "Details / Description", prefixIcon: Icons.description_outlined),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: _getInputDecoration(labelText: "Additional Notes", prefixIcon: Icons.sticky_note_2_outlined),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final double completion = _calculateCompletionPercentage();
    final bool isComplete = completion >= 1.0;

    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _submitForm,
      icon: _isSaving 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.domain_add_rounded, size: 20),
      label: Text(
        _isSaving ? "Registering..." : "Complete School Registration",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: isComplete ? brandOlive : brandOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: (isComplete ? brandOlive : brandOrange).withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? helperText,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, color: brandBrown.withValues(alpha: 0.7)),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
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
}
