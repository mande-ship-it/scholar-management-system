import 'package:flutter/material.dart';

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
  final _nameController = TextEditingController(text: "Jane Doe");
  final _emailController = TextEditingController(text: "jane.doe@example.com");
  final _phoneController = TextEditingController(text: "+265 999 123 456");

  bool _isSaving = false;

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
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account settings updated successfully."),
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
                    child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Manage your personal profile and security credentials.',
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
                    _buildAccountPreview(),
                    const SizedBox(height: 32),

                    const Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
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
                    const Text("Security & Authentication", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 16),
                    _buildActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Update your account password regularly",
                      onTap: () {},
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
                backgroundColor: kBrandOlive,
                child: Text("JD", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
                Text(_nameController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const SizedBox(height: 4),
                Text(_emailController.text, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text("System Administrator", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown)),
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? kBrandBrown;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
