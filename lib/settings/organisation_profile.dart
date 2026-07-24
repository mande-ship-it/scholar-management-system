import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

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
          const SnackBar(
            content: Text("Organisation profile updated successfully."),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving organisation profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
        ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Clean Header ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBrandBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_rounded, color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organisation Profile', 
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown)),
                        const SizedBox(height: 4),
                        const Text('Manage your organization\'s identity and public details.',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfilePreview(),
                    const SizedBox(height: 32),
                    
                    Text("Basic Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? theme.colorScheme.primary : kBrandBrown)),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: "Organisation Name",
                      icon: Icons.domain,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      icon: Icons.category_outlined,
                      label: "Organisation Type",
                      value: _orgType,
                      options: _orgTypes,
                      onChanged: (v) => setState(() => _orgType = v!),
                    ),

                    const SizedBox(height: 32),
                    Text("Contact Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? theme.colorScheme.primary : kBrandBrown)),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: "Address / Location",
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Address is required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            label: "Phone Number",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _websiteController,
                      label: "Website",
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? "Saving..." : "Save Profile Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: kBrandOlive,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : kBrandCream.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? theme.dividerColor : kBrandCream),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: kBrandBrown,
                child: Text("AA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: kBrandOrange, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_nameController.text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown)),
                    if (_isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, size: 18, color: kBrandOlive),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text("Org ID: $_orgId", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text("Registered since $_createdDate", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white70 : kBrandBrown),
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: theme.cardColor,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white70 : kBrandBrown),
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBrandOlive, width: 2)),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }
}
