import 'package:flutter/material.dart';

class RegisterSchoolComponent extends StatefulWidget {
  const RegisterSchoolComponent({super.key});

  @override
  State<RegisterSchoolComponent> createState() => _RegisterSchoolComponentState();
}

class _RegisterSchoolComponentState extends State<RegisterSchoolComponent> {
  final _formKey = GlobalKey<FormState>();

  // Brand Color Palette (consistent with HomePage / Scholar registration)
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
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _codeController,
      _addressController,
      _phoneController,
      _altPhoneController,
      _emailController,
      _postalController,
      _websiteController,
      _adminNameController,
      _adminRoleController,
      _adminPhoneController,
      _adminEmailController,
      _descriptionController,
      _notesController,
    ]) {
      c.addListener(_updatePreview);
    }
  }

  void _updatePreview() => setState(() {});

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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "SC";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Required fields: name, code, level, type, genderType, region, district, phone, email
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
    final total = _getTotalFieldsCount();
    if (total == 0) return 0.0;
    return _getCompletedFieldsCount() / total;
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final schoolName = _nameController.text;
      final schoolCode = _codeController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("School '$schoolName' ($schoolCode) successfully registered!"),
          backgroundColor: brandOlive,
          duration: const Duration(seconds: 4),
        ),
      );

      _formKey.currentState!.reset();
      for (final c in [
        _nameController,
        _codeController,
        _addressController,
        _phoneController,
        _altPhoneController,
        _emailController,
        _postalController,
        _websiteController,
        _adminNameController,
        _adminRoleController,
        _adminPhoneController,
        _adminEmailController,
        _descriptionController,
        _notesController,
      ]) {
        c.clear();
      }

      setState(() {
        _selectedLevel = null;
        _selectedType = null;
        _selectedGenderType = null;
        _selectedRegion = null;
        _selectedDistrict = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please correct the errors in the form."),
          backgroundColor: brandOrange,
        ),
      );
    }
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
              _buildIdentityCard(isWide),
              const SizedBox(height: 16),
              _buildLocationCard(isWide),
              const SizedBox(height: 16),
              _buildContactCard(isWide),
              const SizedBox(height: 16),
              _buildAdminCard(isWide),
              const SizedBox(height: 16),
              _buildAdditionalInfoCard(),
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
        }

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
      initialValue: _selectedLevel,
      decoration: _getInputDecoration(labelText: "Education Level", prefixIcon: Icons.layers_outlined),
      items: _schoolLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
      onChanged: (v) => setState(() => _selectedLevel = v),
      validator: (v) => v == null ? "Select level" : null,
    );

    final typeField = DropdownButtonFormField<String>(
      initialValue: _selectedType,
      decoration: _getInputDecoration(labelText: "School Type / Agency", prefixIcon: Icons.account_balance_outlined),
      items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _selectedType = v),
      validator: (v) => v == null ? "Select type" : null,
    );

    final genderField = DropdownButtonFormField<String>(
      initialValue: _selectedGenderType,
      decoration: _getInputDecoration(labelText: "Gender Policy", prefixIcon: Icons.wc_outlined),
      items: _genderTypes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (v) => setState(() => _selectedGenderType = v),
      validator: (v) => v == null ? "Select policy" : null,
    );

    return _buildCardShell(
      title: "School Identity Details",
      icon: Icons.school_outlined,
      children: isWide
          ? [
        Row(children: [Expanded(flex: 2, child: nameField), const SizedBox(width: 16), Expanded(child: codeField)]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: levelField), const SizedBox(width: 16), Expanded(child: typeField)]),
        const SizedBox(height: 16),
        genderField,
      ]
          : [
        nameField,
        const SizedBox(height: 16),
        codeField,
        const SizedBox(height: 16),
        levelField,
        const SizedBox(height: 16),
        typeField,
        const SizedBox(height: 16),
        genderField,
      ],
    );
  }

  Widget _buildLocationCard(bool isWide) {
    final regionField = DropdownButtonFormField<String>(
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
      children: isWide
          ? [
        Row(children: [Expanded(child: regionField), const SizedBox(width: 16), Expanded(child: districtField)]),
        const SizedBox(height: 16),
        addressField,
      ]
          : [
        regionField,
        const SizedBox(height: 16),
        districtField,
        const SizedBox(height: 16),
        addressField,
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
      title: "School Contacts",
      icon: Icons.contact_phone_outlined,
      children: isWide
          ? [
        Row(children: [Expanded(child: phoneField), const SizedBox(width: 16), Expanded(child: altPhoneField)]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: emailField), const SizedBox(width: 16), Expanded(child: postalField)]),
        const SizedBox(height: 16),
        websiteField,
      ]
          : [
        phoneField,
        const SizedBox(height: 16),
        altPhoneField,
        const SizedBox(height: 16),
        emailField,
        const SizedBox(height: 16),
        postalField,
        const SizedBox(height: 16),
        websiteField,
      ],
    );
  }

  Widget _buildAdminCard(bool isWide) {
    final adminNameField = TextFormField(
      controller: _adminNameController,
      decoration: _getInputDecoration(labelText: "Contact Full Name", prefixIcon: Icons.badge_outlined),
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
      decoration: _getInputDecoration(labelText: "Contact Phone", prefixIcon: Icons.contact_phone_outlined),
    );

    final adminEmailField = TextFormField(
      controller: _adminEmailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _getInputDecoration(labelText: "Contact Email", prefixIcon: Icons.contact_mail_outlined),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return "Enter valid email";
        }
        return null;
      },
    );

    return _buildCardShell(
      title: "Contact Person / Headteacher",
      icon: Icons.person_outline,
      children: isWide
          ? [
        Row(children: [Expanded(flex: 2, child: adminNameField), const SizedBox(width: 16), Expanded(child: adminRoleField)]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: adminPhoneField), const SizedBox(width: 16), Expanded(child: adminEmailField)]),
      ]
          : [
        adminNameField,
        const SizedBox(height: 16),
        adminRoleField,
        const SizedBox(height: 16),
        adminPhoneField,
        const SizedBox(height: 16),
        adminEmailField,
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    return _buildCardShell(
      title: "Additional Information",
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
    final completion = _calculateCompletionPercentage();
    final isComplete = completion >= 1.0;

    return ElevatedButton.icon(
      onPressed: _submitForm,
      icon: const Icon(Icons.save_rounded, size: 20),
      label: const Text(
        "Save School Record",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildPreviewCard() {
    final completion = _calculateCompletionPercentage();
    final completed = _getCompletedFieldsCount();
    final total = _getTotalFieldsCount();
    final name = _nameController.text.trim();
    final initials = _getInitials(name);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [brandBrown, brandOlive],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandBrown),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : "New School Profile",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedLevel ?? "Level not selected",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(completion),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brandCreamDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined, color: brandOrange, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Location",
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedDistrict != null
                                  ? "$_selectedDistrict, ${_selectedRegion ?? ''}"
                                  : "Pending Assignment",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandBrown),
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
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final w = (gridConstraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.pin_outlined, "Code", _codeController.text.trim(), brandOlive)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.account_balance_outlined, "Type", _selectedType ?? "", brandOrange)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.wc_outlined, "Gender Policy", _selectedGenderType ?? "", brandBrown)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.phone_outlined, "Phone", _phoneController.text.trim(), brandOlive)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.email_outlined, "Email", _emailController.text.trim(), brandOrange)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.person_outline, "Contact Person", _adminNameController.text.trim(), brandBrown)),
                      ],
                    );
                  },
                ),
                const Divider(height: 32),
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
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
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
            Text(message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
            Text(
              "${(completion * 100).toInt()}% ($completed of $total)",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandBrown),
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