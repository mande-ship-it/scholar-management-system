import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class AccountSettingsComponent extends StatefulWidget {
  const AccountSettingsComponent({super.key});

  @override
  State<AccountSettingsComponent> createState() => _AccountSettingsComponentState();
}

class _AccountSettingsComponentState extends State<AccountSettingsComponent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;
  String _userRole = "Staff";

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
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _userRole = data['role_name'] ?? 'Staff';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account settings updated successfully."),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
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
                    child: const Icon(Icons.manage_accounts_rounded, color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Settings', 
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown)),
                        const SizedBox(height: 4),
                        const Text('Manage your personal profile and security credentials.',
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
                    _buildAccountPreview(),
                    const SizedBox(height: 32),

                    Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? theme.colorScheme.primary : kBrandBrown)),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? "Valid email required" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 32),
                    Text("Security & Authentication", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? theme.colorScheme.primary : kBrandBrown)),
                    const SizedBox(height: 16),
                    _buildActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Update your account password regularly",
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.shield_outlined,
                      title: "Two-Factor Authentication",
                      subtitle: "Add an extra layer of security",
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.delete_outline_rounded,
                      title: "Close Account",
                      subtitle: "Permanently delete your profile and data",
                      color: Colors.red,
                      onTap: () => _confirmDelete(context),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? "Saving..." : "Save Account Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildAccountPreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials = _nameController.text.isNotEmpty 
        ? _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "U";

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
              CircleAvatar(
                radius: 40,
                backgroundColor: kBrandOlive,
                child: Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
                Text(_nameController.text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown)),
                const SizedBox(height: 4),
                Text(_emailController.text, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_userRole, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : kBrandBrown)),
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = color ?? (isDark ? Colors.white70 : kBrandBrown);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: activeColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: activeColor, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: activeColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Password"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
                validator: (v) => (v == null || v.length < 6) ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
                validator: (v) => v != newPasswordController.text ? "Passwords match failed" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final response = await ApiService.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  if (response.statusCode == 200) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password changed successfully")),
                    );
                  }
                } catch (e) {
                  debugPrint('Error changing password: $e');
                }
              }
            },
            child: const Text("Update Password"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to permanently delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete Account"),
          ),
        ],
      ),
    );
  }
}
