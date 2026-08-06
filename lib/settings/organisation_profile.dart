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
    if (!mounted) return;
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kBrandOlive, strokeWidth: 3))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExecutiveHeader(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileOverviewSection(isMobile),
                          const SizedBox(height: 48),

                          if (isMobile)
                            Column(
                              children: [
                                _buildGeneralSettingsSection(),
                                const SizedBox(height: 40),
                                _buildContactSettingsSection(),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildGeneralSettingsSection()),
                                const SizedBox(width: 40),
                                Expanded(flex: 2, child: _buildContactSettingsSection()),
                              ],
                            ),

                          const SizedBox(height: 60),
                          _buildSubmitAction(isMobile),
                          const SizedBox(height: 20),
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

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrandBrown.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.corporate_fare_rounded, color: kBrandBrown, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Organisation Profile", 
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                const Text("Identity and communication channels.",
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverviewSection(bool isMobile) {
    Widget logo = Container(
      width: isMobile ? 100 : 120,
      height: isMobile ? 100 : 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(
            'assets/images/age-logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    Widget details = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_nameController.text.isEmpty ? "ENTITY" : _nameController.text.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
            if (_isVerified) ...[
              const SizedBox(width: 12),
              _verifiedBadge(),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _metaInfoChip("ID: $_orgId", Icons.fingerprint_rounded),
            _metaInfoChip("ESTABLISHED: $_createdDate", Icons.event_available_rounded),
            _metaInfoChip(_orgType.toUpperCase(), Icons.category_rounded),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: kBrandOrange),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_addressController.text.isEmpty ? "Address Pending" : _addressController.text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: isMobile 
        ? Column(
            children: [
              logo,
              const SizedBox(height: 24),
              details,
            ],
          )
        : Row(
            children: [
              logo,
              const SizedBox(width: 40),
              Expanded(child: details),
            ],
          ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kBrandOlive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBrandOlive.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: kBrandOlive),
          SizedBox(width: 6),
          Text("VERIFIED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _metaInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kBrandBrown.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandBrown)),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("ACADEMIC & LEGAL IDENTITY"),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _nameController,
          label: "Full Registered Name",
          hint: "e.g. AGE Africa Malawi",
          icon: Icons.domain_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? "Registered name is required" : null,
        ),
        const SizedBox(height: 20),
        _buildDropdownField(
          label: "Organisation Type",
          value: _orgType,
          options: _orgTypes,
          icon: Icons.account_tree_rounded,
          onChanged: (v) => setState(() => _orgType = v!),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          label: "Registered Physical Address",
          hint: "Postal Box, City, Region",
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
        _sectionLabel("DIGITAL FOOTPRINT"),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _emailController,
          label: "Corporate Email Address",
          hint: "contact@organisation.org",
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: "Switchboard / Primary Phone",
          hint: "+265...",
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _websiteController,
          label: "Official Web Domain",
          hint: "www.organisation.org",
          icon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildSubmitAction(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.verified_user_rounded, size: 20),
        label: Text(_isSaving ? "SYNCHRONIZING..." : "SAVE PROFILE",
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13)),
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

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandOlive.withOpacity(0.8), letterSpacing: 1.5));
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (v) => setState(() {}),
      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : kBrandBrown),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white70 : kBrandBrown.withOpacity(0.4)),
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? theme.dividerColor : const Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
      onChanged: onChanged,
      dropdownColor: theme.cardColor,
      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : kBrandBrown),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white70 : kBrandBrown.withOpacity(0.4)),
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? theme.dividerColor : const Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }
}
