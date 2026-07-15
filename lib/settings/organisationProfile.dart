// organisation_profile.dart
import 'package:flutter/material.dart';

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
        content: Text("Organisation profile updated"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            "Organisation Profile",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage your organisation's identity and details.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 16),

          _sectionCard(
            title: "Basic Information",
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: "Organisation Name",
                  icon: Icons.domain,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Name is required" : null,
                ),
                const SizedBox(height: 14),
                _buildDropdownField(
                  icon: Icons.category_outlined,
                  label: "Organisation Type",
                  value: _orgType,
                  options: _orgTypes,
                  onChanged: (v) => setState(() => _orgType = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: "Contact Details",
            child: Column(
              children: [
                _buildTextField(
                  controller: _addressController,
                  label: "Address / Location",
                  icon: Icons.location_on_outlined,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Address is required" : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Email is required";
                    if (!v.contains("@")) return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _websiteController,
                  label: "Website",
                  icon: Icons.language,
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: "Registration",
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  label: "Organisation ID",
                  value: _orgId,
                ),
                const Divider(height: 24),
                _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: "Created",
                  value: _createdDate,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      _isVerified ? Icons.verified : Icons.error_outline,
                      color: _isVerified ? Colors.green.shade600 : Colors.orange.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Status", style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            _isVerified ? "Verified" : "Pending Verification",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isVerified ? "Verified" : "Pending",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text("Save Changes", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------- Sub-widgets ----------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.green,
                child: Text(
                  "AA",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty ? "Organisation Name" : _nameController.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "ID: $_orgId  •  Created: $_createdDate",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: "Members",
            value: "58",
            color: Colors.green.shade50,
            valueColor: Colors.green.shade800,
            icon: Icons.groups_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            label: "Active Projects",
            value: "9",
            color: Colors.orange.shade50,
            valueColor: Colors.orange.shade800,
            icon: Icons.work_outline,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: valueColor, size: 20),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          child,
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
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF6F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF6F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}