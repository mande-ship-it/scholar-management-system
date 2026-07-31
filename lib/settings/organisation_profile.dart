import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class OrganisationProfileComponent extends StatefulWidget {
  const OrganisationProfileComponent({super.key});

  @override
  State<OrganisationProfileComponent> createState() =>
      _OrganisationProfileComponentState();
}

class _OrganisationProfileComponentState
    extends State<OrganisationProfileComponent> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  String _orgType = "Non-Profit";
  bool _isVerified = false;
  bool _isSaving = false;
  bool _isLoading = false;

  final List<String> _orgTypes = [
    "Non-Profit",
    "Private Company",
    "Government",
    "Educational Institution",
    "Cooperative",
  ];

  String _orgId = "N/A";
  String _createdDate = "N/A";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getOrganisationProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _addressController.text = data['address'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _emailController.text = data['email'] ?? '';
            _websiteController.text = data['website'] ?? '';
            _orgType = data['type'] ?? "Non-Profit";
            _isVerified = data['is_verified'] ?? false;
            _orgId = data['org_id'] ?? "N/A";
            _createdDate = data['created_date'] ?? "N/A";
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching organisation profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.updateOrganisationProfile({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'type': _orgType,
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text("Organisation profile updated successfully."),
              ],
            ),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving organisation profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save changes."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileOverviewCard(),
                          const SizedBox(height: 32),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildGeneralSettingsSection()),
                              const SizedBox(width: 32),
                              Expanded(flex: 2, child: _buildContactSettingsSection()),
                            ],
                          ),

                          const SizedBox(height: 48),
                          _buildSubmitSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildProfileOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kBrandBrown.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBrandBrown.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kBrandBrown,
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/age-logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: _nameController.text.isEmpty
                  ? const Icon(Icons.business_rounded, color: Colors.white, size: 40)
                  : null,
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: kBrandOrange, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_nameController.text.isEmpty ? "Institution Name" : _nameController.text,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
                    if (_isVerified) ...[
                      const SizedBox(width: 10),
                      const Tooltip(
                        message: "Verified Institution",
                        child: Icon(Icons.verified_rounded, size: 22, color: kBrandOlive),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge("REG ID: $_orgId", Icons.fingerprint_rounded),
                    const SizedBox(width: 12),
                    _badge("EST: $_createdDate", Icons.event_available_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_addressController.text.isEmpty ? "Location not set" : _addressController.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kBrandOlive),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandBrown)),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("INSTITUTIONAL IDENTITY"),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nameController,
          label: "Full Registered Name",
          hint: "e.g. AGE Africa Malawi",
          icon: Icons.domain_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? "Registered name is required" : null,
        ),
        const SizedBox(height: 20),
        _buildDropdownField(
          label: "Entity Type",
          value: _orgType,
          options: _orgTypes,
          icon: Icons.category_rounded,
          onChanged: (v) => setState(() => _orgType = v!),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          label: "Physical Office Address",
          hint: "Street, City, Country",
          icon: Icons.location_on_rounded,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildContactSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("COMMUNICATION CHANNELS"),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _emailController,
          label: "Official Email",
          hint: "info@organisation.org",
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: "Primary Contact Number",
          hint: "+265...",
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _websiteController,
          label: "Public Website",
          hint: "www.organisation.org",
          icon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildSubmitSection() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveProfile,
          icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.verified_user_rounded),
          label: Text(_isSaving ? "SYNCING..." : "UPDATE PROFILE",
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandOlive,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (v) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kBrandBrown),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kBrandBrown),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }
}
