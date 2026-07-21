import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

/// ---------------------------------------------------------------------
/// SUPPORT MODELS
/// ---------------------------------------------------------------------
class _ActivityEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

/// ---------------------------------------------------------------------
/// USER PROFILE COMPONENT
/// ---------------------------------------------------------------------
class UserProfileComponent extends StatefulWidget {
  const UserProfileComponent({super.key});

  @override
  State<UserProfileComponent> createState() => _UserProfileComponentState();
}

class _UserProfileComponentState extends State<UserProfileComponent> {
  // ---------------------------------------------------------------------
  // PROFILE DATA (mock)
  // ---------------------------------------------------------------------
  final String _username = 'eshaba';
  final String _role = 'Administrator';
  final String _department = 'Information Technology';
  final bool _isActive = true;
  final DateTime _memberSince = DateTime(2024, 1, 10);
  final DateTime _lastLogin = DateTime(2026, 7, 15, 8, 42);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;

  Map<String, String> _originalValues = {};
  bool _isEditing = false;
  final _profileFormKey = GlobalKey<FormState>();

  int _selectedTab = 0; // 0 = Personal Info, 1 = Security, 2 = Activity

  // Security
  final _securityFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _twoFactorEnabled = false;

  final List<_ActivityEntry> _activity = [
    _ActivityEntry(
      icon: Icons.login_rounded,
      color: Colors.green.shade600,
      title: 'Logged in',
      subtitle: 'Signed in from Windows Desktop',
      time: '2 hours ago',
    ),
    _ActivityEntry(
      icon: Icons.edit_rounded,
      color: Colors.blue.shade600,
      title: 'Updated scholar record',
      subtitle: "Edited profile for Chikondi Mwale",
      time: 'Yesterday',
    ),
    _ActivityEntry(
      icon: Icons.person_add_rounded,
      color: Colors.purple.shade600,
      title: 'Created new user',
      subtitle: 'Added Grace Banda as Program Manager',
      time: '3 days ago',
    ),
    _ActivityEntry(
      icon: Icons.lock_reset_rounded,
      color: Colors.orange.shade700,
      title: 'Password changed',
      subtitle: 'Account password was updated',
      time: '1 week ago',
    ),
    _ActivityEntry(
      icon: Icons.download_rounded,
      color: Colors.teal.shade600,
      title: 'Exported report',
      subtitle: 'Downloaded Q2 Attendance Report',
      time: '2 weeks ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _originalValues = {
      'name': 'Edward Shaba',
      'email': 'edward.shaba@ageafrica.org',
      'phone': '+265 991 234 567',
      'location': 'Lilongwe, Malawi',
      'bio': 'System administrator overseeing CHATS platform operations '
          'and user access across AGE Africa.',
    };
    _nameController = TextEditingController(text: _originalValues['name']);
    _emailController = TextEditingController(text: _originalValues['email']);
    _phoneController = TextEditingController(text: _originalValues['phone']);
    _locationController = TextEditingController(text: _originalValues['location']);
    _bioController = TextEditingController(text: _originalValues['bio']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------
  void _startEditing() => setState(() => _isEditing = true);

  void _cancelEditing() {
    setState(() {
      _nameController.text = _originalValues['name']!;
      _emailController.text = _originalValues['email']!;
      _phoneController.text = _originalValues['phone']!;
      _locationController.text = _originalValues['location']!;
      _bioController.text = _originalValues['bio']!;
      _isEditing = false;
    });
  }

  void _saveProfile() {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() {
      _originalValues = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
      };
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Profile updated successfully."),
        backgroundColor: kBrandOlive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out of your account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kBrandOrange, foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _updatePassword() {
    if (!_securityFormKey.currentState!.validate()) return;
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Password updated successfully."),
        backgroundColor: kBrandOlive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${months[d.month - 1]} ${d.year}";
  }

  String _formatDateTime(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return "${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute $period";
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
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
            _buildHeaderCard(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildTabsBar(),
                  const SizedBox(height: 24),
                  if (_selectedTab == 0) _buildPersonalInfoCard(),
                  if (_selectedTab == 1) _buildSecurityCard(),
                  if (_selectedTab == 2) _buildActivityCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER CARD (Banner Removed)
  // ---------------------------------------------------------------------
  Widget _buildHeaderCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 30),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: kBrandBrown.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: kBrandCream, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(_originalValues['name'] ?? 'U'),
                      style: const TextStyle(
                        color: kBrandBrown,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBrandOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _originalValues['name'] ?? '',
                      style: const TextStyle(
                        color: kBrandBrown,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "@$_username • $_role",
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _headerPill(Icons.apartment_rounded, _department),
                        const SizedBox(width: 10),
                        _headerPill(
                          _isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                          _isActive ? 'Active' : 'Inactive',
                          isStatus: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBrown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    label: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ---------------- Stats (Banners Removed) ----------------
      ],
    );
  }

  Widget _headerPill(IconData icon, String label, {bool isStatus = false}) {
    final Color color = isStatus 
        ? (label == 'Active' ? kBrandOlive : Colors.orange) 
        : kBrandBrown.withValues(alpha: 0.6);
    final Color bgColor = color.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TABS BAR
  // ---------------------------------------------------------------------
  Widget _buildTabsBar() {
    final tabs = [
      ("Personal Info", Icons.person_outline_rounded),
      ("Security", Icons.lock_outline_rounded),
      ("Activity", Icons.history_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[index].$2,
                        size: 16,
                        color: isSelected
                            ? kBrandOlive
                            : Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      tabs[index].$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? kBrandBrown : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PERSONAL INFO CARD
  // ---------------------------------------------------------------------
  Widget _buildPersonalInfoCard() {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Account Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    if (_isEditing) Row(
                      children: [
                        TextButton(onPressed: _cancelEditing, child: const Text("Cancel")),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                if (!_isEditing) ...[
                  _infoRow("Full Name", _originalValues['name']!, Icons.person_outline),
                  _infoRow("Email Address", _originalValues['email']!, Icons.email_outlined),
                  _infoRow("Phone Number", _originalValues['phone']!, Icons.phone_outlined),
                  _infoRow("Location", _originalValues['location']!, Icons.location_on_outlined),
                  _infoRow("Professional Bio", _originalValues['bio']!, Icons.notes_rounded),
                ] else ...[
                  _buildTextField(_nameController, "Full Name", Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, "Email Address", Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_locationController, "Location", Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_bioController, "Professional Bio", Icons.notes_rounded, maxLines: 3),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kBrandBrown.withValues(alpha: 0.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kBrandBrown),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECURITY CARD
  // ---------------------------------------------------------------------
  Widget _buildSecurityCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Form(
            key: _securityFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Update Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const Divider(height: 32),
                _buildTextField(_currentPasswordController, "Current Password", Icons.lock_outline, obscureText: true),
                const SizedBox(height: 16),
                _buildTextField(_newPasswordController, "New Password", Icons.lock_reset_rounded, obscureText: true),
                const SizedBox(height: 16),
                _buildTextField(_confirmPasswordController, "Confirm New Password", Icons.lock_reset_rounded, obscureText: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Save New Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: kBrandOlive),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Two-Factor Authentication", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                    Text("Secure your account with 2FA", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(
                value: _twoFactorEnabled,
                activeColor: kBrandOlive,
                onChanged: (v) => setState(() => _twoFactorEnabled = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // ACTIVITY CARD
  // ---------------------------------------------------------------------
  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Account Activity Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const Divider(height: 32),
          ...List.generate(_activity.length, (index) {
            final entry = _activity[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: entry.color.withValues(alpha: 0.1), child: Icon(entry.icon, size: 16, color: entry.color)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown)),
                        Text(entry.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(entry.time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
