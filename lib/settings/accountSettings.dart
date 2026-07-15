// account_settings.dart
import 'package:flutter/material.dart';

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

  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _darkMode = false;
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
    await Future.delayed(const Duration(milliseconds: 900)); // simulate API call
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Settings saved successfully"),
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
            "Account Settings",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage your profile, preferences, and security.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _sectionCard(
            title: "Personal Information",
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Name is required" : null,
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
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: "Preferences",
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "Email Notifications",
                  subtitle: "Receive updates and alerts via email",
                  icon: Icons.mark_email_unread_outlined,
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
                const Divider(height: 24),
                _buildSwitchTile(
                  title: "Push Notifications",
                  subtitle: "Get real-time alerts on this device",
                  icon: Icons.notifications_none,
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                const Divider(height: 24),
                _buildSwitchTile(
                  title: "Dark Mode",
                  subtitle: "Use a darker color theme",
                  icon: Icons.dark_mode_outlined,
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: "Security",
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.lock_outline,
                  label: "Change Password",
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.shield_outlined,
                  label: "Two-Factor Authentication",
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.delete_outline,
                  label: "Delete Account",
                  labelColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
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
        ],
      ),
    );
  }

  // ---------- Sub-widgets ----------

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Colors.deepPurple.shade100,
          child: const Text(
            "JD",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameController.text.isEmpty ? "Your Name" : _nameController.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _emailController.text,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.camera_alt_outlined),
          tooltip: "Change photo",
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: "Active Count",
            value: "124",
            color: Colors.green.shade50,
            valueColor: Colors.green.shade800,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            label: "Pending Items",
            value: "12",
            color: Colors.orange.shade50,
            valueColor: Colors.orange.shade800,
            icon: Icons.hourglass_bottom,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade700),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: labelColor ?? Colors.black87),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
        content: const Text(
          "This action is permanent and cannot be undone. Are you sure you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}