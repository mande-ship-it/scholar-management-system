import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

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
  // PROFILE DATA
  // ---------------------------------------------------------------------
  String _username = '';
  String _role = '';
  String _department = '';
  bool _isActive = true;
  DateTime _memberSince = DateTime.now();
  DateTime _lastLogin = DateTime.now();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;

  Map<String, String> _originalValues = {};
  bool _isEditing = false;
  bool _isLoading = false;
  final _profileFormKey = GlobalKey<FormState>();

  int _selectedTab = 0; // 0 = Personal Info, 1 = Security, 2 = Activity

  // Security
  final _securityFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _twoFactorEnabled = false;

  final List<_ActivityEntry> _activity = []; // Could be fetched from API

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _bioController = TextEditingController();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final u = response.data['data'];
        if (mounted) {
          setState(() {
            _username = u['username'] ?? '';
            _role = u['role_name'] ?? '';
            _department = u['department'] ?? '';
            _isActive = u['is_active'] ?? true;
            _memberSince =
                DateTime.tryParse(u['created_at'] ?? '') ?? DateTime.now();
            // Backend might need to return last_login
            _lastLogin = DateTime.now();

            _originalValues = {
              'name': u['full_name'] ?? '',
              'email': u['email'] ?? '',
              'phone': u['phone'] ?? '',
              'location': u['location'] ?? '',
              'bio': u['bio'] ?? '',
            };

            _nameController.text = _originalValues['name']!;
            _emailController.text = _originalValues['email']!;
            _phoneController.text = _originalValues['phone']!;
            _locationController.text = _originalValues['location']!;
            _bioController.text = _originalValues['bio']!;
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

  void _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'fullName': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
    };

    try {
      final response = await ApiService.updateAccountProfile(data);
      if (response.statusCode == 200) {
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile updated successfully."),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error updating profile. Please try again."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content:
            const Text("Are you sure you want to sign out of your account?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOrange, foregroundColor: Colors.white),
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

  void _updatePassword() async {
    if (!_securityFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (response.statusCode == 200) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Password updated successfully."),
            backgroundColor: kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error updating password. Check current password."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading
          ? const Center(
              child: Padding(
              padding: EdgeInsets.all(80.0),
              child: CircularProgressIndicator(),
            ))
          : SingleChildScrollView(
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
                activeThumbColor: kBrandOlive,
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
