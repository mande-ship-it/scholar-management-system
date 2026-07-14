import 'package:flutter/material.dart';

class EditSchoolComponent extends StatefulWidget {
  const EditSchoolComponent({super.key});

  @override
  State<EditSchoolComponent> createState() => _EditSchoolComponentState();
}

class _EditSchoolComponentState extends State<EditSchoolComponent> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
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

  // Dropdown States
  String? _selectedLevel;
  String? _selectedType;
  String? _selectedGenderType;
  String? _selectedRegion;
  String? _selectedDistrict;

  // Flag to avoid double initialization
  bool _isInitialized = false;

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

  // Mapping of Regions to Malawian Districts
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;

      _nameController = TextEditingController(text: args?['name'] ?? '');
      _codeController = TextEditingController(text: args?['code'] ?? '');
      _addressController = TextEditingController(text: args?['address'] ?? '');
      _phoneController = TextEditingController(text: args?['phone'] ?? '');
      _altPhoneController = TextEditingController(text: args?['altPhone'] ?? '');
      _emailController = TextEditingController(text: args?['email'] ?? '');
      _postalController = TextEditingController(text: args?['postal'] ?? '');
      _websiteController = TextEditingController(text: args?['website'] ?? '');
      _adminNameController = TextEditingController(text: args?['adminName'] ?? '');
      _adminRoleController = TextEditingController(text: args?['adminRole'] ?? '');
      _adminPhoneController = TextEditingController(text: args?['adminPhone'] ?? '');
      _adminEmailController = TextEditingController(text: args?['adminEmail'] ?? '');
      _descriptionController = TextEditingController(text: args?['description'] ?? '');
      _notesController = TextEditingController(text: args?['notes'] ?? '');

      _selectedLevel = args?['level'];
      if (_selectedLevel != null && !_schoolLevels.contains(_selectedLevel)) {
        _selectedLevel = null;
      }

      _selectedType = args?['type'];
      if (_selectedType != null && !_schoolTypes.contains(_selectedType)) {
        _selectedType = null;
      }

      _selectedGenderType = args?['genderPolicy'];
      if (_selectedGenderType != null && !_genderTypes.contains(_selectedGenderType)) {
        _selectedGenderType = null;
      }

      _selectedRegion = args?['region'];
      if (_selectedRegion != null && !_regions.contains(_selectedRegion)) {
        _selectedRegion = null;
      }

      _selectedDistrict = args?['district'];
      if (_selectedRegion != null && _selectedDistrict != null) {
        final dists = _regionDistricts[_selectedRegion] ?? [];
        if (!dists.contains(_selectedDistrict)) {
          _selectedDistrict = null;
        }
      }

      _isInitialized = true;
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

  // Get active list of districts based on selected region
  List<String> get _activeDistricts {
    if (_selectedRegion == null) return [];
    return _regionDistricts[_selectedRegion] ?? [];
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final schoolName = _nameController.text;
      final schoolCode = _codeController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Changes to '$schoolName' ($schoolCode) successfully saved!"),
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        ),
      );

      // Return back to school profile screen
      Navigator.pop(context);
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
            Icon(icon, color: Theme.of(context).primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Edit School Details",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Update details for this school partner",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1.2),

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
                        onChanged: (val) => setState(() => _selectedLevel = val),
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
                        onChanged: (val) => setState(() => _selectedType = val),
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
                  onChanged: (val) => setState(() => _selectedGenderType = val),
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
                            _selectedDistrict = null; // reset district
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
                        validator: (val) => val == null ? "Select district" : null,
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
                _buildSectionHeader("Contact Person / Headteacher", Icons.person),
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
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
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
                _buildSectionHeader("Additional Information", Icons.info_outline),
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

                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
