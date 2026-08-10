import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

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
    if (!mounted) return;
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
            _profileImageUrl = response.data['data']['profile_picture'];
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

  Widget _buildExecutiveHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              "Account Preferences",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          IconButton(
            onPressed: _fetchProfile,
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Sync Profile",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExecutiveHeader(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAccountSummarySection(isMobile),
                          const SizedBox(height: 48),

                          _sectionLabel("PERSONAL IDENTITY"),
                          const SizedBox(height: 24),
                          if (isMobile) ...[
                            _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person_rounded),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _usernameController, label: "Username Handle", icon: Icons.alternate_email_rounded),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _emailController, label: "Email Address", icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _phoneController, label: "Contact Phone", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                          ] else ...[
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
                          ],

                          const SizedBox(height: 48),
                          _sectionLabel("SECURITY & CREDENTIALS"),
                          const SizedBox(height: 24),
                          _buildActionTile(
                            icon: Icons.lock_reset_rounded,
                            title: "Change Account Password",
                            subtitle: "Maintain account security with a unique password.",
                            onTap: () => _showChangePasswordDialog(context),
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 12),
                          _buildActionTile(
                            icon: Icons.fingerprint_rounded,
                            title: "Biometric Integration",
                            subtitle: "Configure hardware-level security.",
                            onTap: () {},
                            isMobile: isMobile,
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

  Widget _buildAccountSummarySection(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget avatar = Stack(
      children: [
        Container(
          width: isMobile ? 80 : 100,
          height: isMobile ? 80 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: kBrandBrown,
            backgroundImage: _profileImageUrl != null
              ? NetworkImage(ApiService.getFullUrl(_profileImageUrl))
              : null,
            child: _profileImageUrl == null
              ? Icon(Icons.person_rounded, size: isMobile ? 40 : 48, color: Colors.white)
              : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: kBrandOrange, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );

    Widget info = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(_nameController.text.isEmpty ? "User Profile" : _nameController.text,
          style: TextStyle(fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown)),
        const SizedBox(height: 4),
        Text("@${_usernameController.text}", style: const TextStyle(fontSize: 14, color: kBrandOrange, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : kBrandBrown).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (isDark ? Colors.white : kBrandBrown).withOpacity(0.1)),
          ),
          child: Text(_userRole.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: 1.0)),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: isMobile 
        ? Column(
            children: [
              avatar,
              const SizedBox(height: 20),
              info,
            ],
          )
        : Row(
            children: [
              avatar,
              const SizedBox(width: 32),
              Expanded(child: info),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (v) => setState(() {}),
      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : kBrandBrown),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white70 : kBrandBrown.withOpacity(0.4)),
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isMobile = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? theme.dividerColor : Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isDark ? Colors.white : kBrandBrown).withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(icon, color: isDark ? Colors.white70 : kBrandBrown, size: 20),
              ),
              const SizedBox(width: 20),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, fontSize: isMobile ? 14 : 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitAction(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveSettings,
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
