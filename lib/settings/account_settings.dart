import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import '../widgets/custom_loaders.dart';

class AccountSettingsComponent extends StatefulWidget {
  const AccountSettingsComponent({super.key});

  @override
  State<AccountSettingsComponent> createState() => _AccountSettingsComponentState();
}

class _AccountSettingsComponentState extends State<AccountSettingsComponent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;
  String _userRole = "Staff Member";
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _nameController.text = data['full_name'] ?? '';
            _usernameController.text = data['username'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _userRole = data['role_name'] ?? 'Staff Member';
            _profileImageUrl = data['profile_picture'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching account profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        setState(() => _isLoading = true);
        final response = await ApiService.uploadProfilePicture(bytes, fileName);

        if (response.statusCode == 200) {
          setState(() {
            _profileImageUrl = response.data['data']['profilePicture'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile avatar updated successfully."), backgroundColor: kBrandOlive),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.updateAccountProfile({
        'fullName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Personal settings synchronized successfully."),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving account settings: $e');
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
        ? const Center(child: BeautifulLoader(isOverlay: false, message: "Syncing Profile"))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfessionalHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAccountSummaryCard(),
                          const SizedBox(height: 40),

                          _sectionLabel("PERSONAL IDENTITY"),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person_rounded)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField(controller: _usernameController, label: "Username Handle", icon: Icons.alternate_email_rounded)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(controller: _emailController, label: "Email Address", icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField(controller: _phoneController, label: "Contact Phone", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
                            ],
                          ),

                          const SizedBox(height: 40),
                          _sectionLabel("SECURITY & CREDENTIALS"),
                          const SizedBox(height: 20),
                          _buildActionTile(
                            icon: Icons.lock_reset_rounded,
                            title: "Change Account Password",
                            subtitle: "Maintain account security with a strong, unique password.",
                            onTap: () => _showChangePasswordDialog(context),
                          ),
                          const SizedBox(height: 12),
                          _buildActionTile(
                            icon: Icons.fingerprint_rounded,
                            title: "Biometric Integration",
                            subtitle: "Configure hardware-level security for faster logins.",
                            onTap: () {},
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

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBrandOlive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.manage_accounts_rounded, color: kBrandOlive, size: 30),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Account Preferences",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                SizedBox(height: 4),
                Text("Update your personal digital identity, security settings and contact information.",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummaryCard() {
    final initials = _nameController.text.isNotEmpty 
        ? _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "U";

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kBrandOlive.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBrandOlive.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: kBrandBrown,
                backgroundImage: _profileImageUrl != null
                  ? NetworkImage(ApiService.getFullUrl(_profileImageUrl))
                  : null,
                child: _profileImageUrl == null
                  ? Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: kBrandOrange, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameController.text.isEmpty ? "User Profile" : _nameController.text,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
                const SizedBox(height: 6),
                Text("@${_usernameController.text}", style: const TextStyle(fontSize: 14, color: kBrandOrange, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: kBrandBrown, borderRadius: BorderRadius.circular(8)),
                  child: Text(_userRole.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (v) => setState(() {}),
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(icon, color: kBrandBrown, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveSettings,
          icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.cloud_upload_rounded),
          label: Text(_isSaving ? "SYNCING..." : "SAVE SETTINGS",
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBrown,
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

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Security Password", style: TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPopupTextField(controller: currentPasswordController, label: "Current Password"),
              const SizedBox(height: 16),
              _buildPopupTextField(controller: newPasswordController, label: "New Password"),
              const SizedBox(height: 16),
              _buildPopupTextField(controller: confirmPasswordController, label: "Confirm Password",
                  validator: (v) => v != newPasswordController.text ? "Passwords do not match" : null),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final response = await ApiService.changePassword(currentPasswordController.text, newPasswordController.text);
                  if (response.statusCode == 200) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Security credentials updated.")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update password."), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("UPDATE CREDENTIALS"),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupTextField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? "Required field" : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
