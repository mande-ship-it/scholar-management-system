import 'package:flutter/material.dart';

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

  final _nameController = TextEditingController(text: "AGE Africa");
  final _addressController = TextEditingController(text: "Lilongwe, Malawi");
  final _phoneController = TextEditingController(text: "+265 999 123 456");
  final _emailController = TextEditingController(text: "info@ageafrica.org");
  final _websiteController = TextEditingController(text: "www.ageafrica.org");

  String _orgType = "Non-Profit";
  bool _isVerified = true;
  bool _isSaving = false;

  final List<String> _orgTypes = [
    "Non-Profit",
    "Private Company",
    "Government",
    "Educational Institution",
    "Cooperative",
  ];

  final String _orgId = "AGE-2026-0987";
  final String _createdDate = "July 2026";

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
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Organisation profile updated successfully."),
        backgroundColor: kBrandOlive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Gradient Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kBrandBrown, kBrandOlive]),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organisation Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Manage your organization\'s identity and public details.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
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
                    
                    const Text("Basic Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
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
                    const Text("Contact Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBrandCream.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrandCream),
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
                    Text(_nameController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kBrandBrown),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kBrandBrown),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }
}
