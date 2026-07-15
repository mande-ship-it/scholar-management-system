import 'package:flutter/material.dart';

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

class _SessionEntry {
  final String device;
  final IconData icon;
  final String location;
  final String lastActive;
  final bool isCurrent;

  const _SessionEntry({
    required this.device,
    required this.icon,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
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
  // PROFILE DATA (mock — replace with real user/session data)
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
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _twoFactorEnabled = false;

  final List<_SessionEntry> _sessions = const [
    _SessionEntry(
      device: 'Windows Desktop — CHATS App',
      icon: Icons.desktop_windows_rounded,
      location: 'Lilongwe, Malawi',
      lastActive: 'Active now',
      isCurrent: true,
    ),
    _SessionEntry(
      device: 'Chrome on Windows',
      icon: Icons.language_rounded,
      location: 'Lilongwe, Malawi',
      lastActive: '2 hours ago',
      isCurrent: false,
    ),
    _SessionEntry(
      device: 'CHATS Mobile App',
      icon: Icons.phone_android_rounded,
      location: 'Blantyre, Malawi',
      lastActive: '3 days ago',
      isCurrent: false,
    ),
  ];

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
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _passwordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;
    return score;
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 0:
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade600;
      case 3:
        return Colors.amber.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 0:
      case 1:
        return "Weak";
      case 2:
        return "Fair";
      case 3:
        return "Good";
      default:
        return "Strong";
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
        backgroundColor: Colors.green.shade700,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildTabsBar(),
          const SizedBox(height: 16),
          if (_selectedTab == 0) _buildPersonalInfoCard(),
          if (_selectedTab == 1) _buildSecurityCard(),
          if (_selectedTab == 2) _buildActivityCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER CARD
  // ---------------------------------------------------------------------
  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade800, Colors.green.shade600],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(_originalValues['name'] ?? 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  "Hook this up to an image picker to change your photo."),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.shade700, width: 1.5),
                          ),
                          child: Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.green.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _originalValues['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "@$_username",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _headerPill(Icons.shield_rounded, _role),
                          _headerPill(Icons.apartment_rounded, _department),
                          _headerPill(
                            _isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_rounded,
                            _isActive ? 'Active' : 'Inactive',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  OutlinedButton.icon(
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                    label: const Text("Edit Profile",
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _quickStat(Icons.calendar_today_rounded, "Member Since",
                      _formatDate(_memberSince)),
                ),
                _verticalDivider(),
                Expanded(
                  child: _quickStat(Icons.access_time_rounded, "Last Login",
                      _formatDateTime(_lastLogin)),
                ),
                _verticalDivider(),
                Expanded(
                  child: _quickStat(
                      Icons.badge_outlined, "User ID", "CHATS-${_username.toUpperCase()}"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _quickStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.grey.shade200,
  );

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
                padding: const EdgeInsets.symmetric(vertical: 11),
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
                            ? Colors.green.shade700
                            : Colors.grey.shade500),
                    const SizedBox(width: 7),
                    Text(
                      tabs[index].$1,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.green.shade800 : Colors.grey.shade600,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("Personal Information",
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                  ),
                  if (_isEditing) ...[
                    TextButton(
                      onPressed: _cancelEditing,
                      child: Text("Cancel",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle:
                        const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 28),
              if (!_isEditing) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _infoTile(Icons.badge_outlined, "Full Name",
                            _originalValues['name']!)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _infoTile(Icons.alternate_email_rounded, "Username",
                            "@$_username")),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _infoTile(Icons.email_outlined, "Email",
                            _originalValues['email']!)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _infoTile(Icons.phone_outlined, "Phone",
                            _originalValues['phone']!)),
                  ],
                ),
                const SizedBox(height: 18),
                _infoTile(Icons.location_on_outlined, "Location",
                    _originalValues['location']!),
                const SizedBox(height: 18),
                _infoTile(Icons.notes_outlined, "About", _originalValues['bio']!),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: _fieldDecoration("Full Name *", Icons.badge_outlined),
                        validator: (v) =>
                        (v == null || v.trim().length < 3) ? "Enter a valid name" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration:
                        _fieldDecoration("Phone Number", Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration("Email Address *", Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Enter an email address";
                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!regex.hasMatch(v.trim())) return "Enter a valid email address";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration:
                  _fieldDecoration("Location", Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: _fieldDecoration("About", Icons.notes_outlined),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade400, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // ---------------------------------------------------------------------
  // SECURITY CARD
  // ---------------------------------------------------------------------
  Widget _buildSecurityCard() {
    final strength = _passwordStrength(_newPasswordController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _securityFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.password_rounded, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text("Change Password",
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 28),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    decoration: _fieldDecoration(
                        "Current Password *", Icons.lock_outline)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? "Enter your current password" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDecoration("New Password *", Icons.lock_reset_outlined)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter a new password";
                      if (v.length < 8) return "Password must be at least 8 characters";
                      return null;
                    },
                  ),
                  if (_newPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: strength / 4,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(_strengthColor(strength)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(_strengthLabel(strength),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _strengthColor(strength))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: _fieldDecoration(
                        "Confirm New Password *", Icons.lock_reset_outlined)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Confirm your new password";
                      if (v != _newPasswordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _updatePassword,
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text("Update Password"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text("Two-Factor Authentication",
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                    ),
                    Switch(
                      value: _twoFactorEnabled,
                      activeColor: Colors.green.shade700,
                      onChanged: (val) => setState(() => _twoFactorEnabled = val),
                    ),
                  ],
                ),
                Text(
                  _twoFactorEnabled
                      ? "Two-factor authentication is enabled for your account."
                      : "Add an extra layer of security to your account at sign-in.",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.devices_rounded, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text("Active Sessions",
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 28),
                ..._sessions.map((s) => _sessionTile(s)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sessionTile(_SessionEntry session) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(session.icon, size: 17, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(session.device,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    if (session.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("THIS DEVICE",
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text("${session.location} • ${session.lastActive}",
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
          if (!session.isCurrent)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Signed out of ${session.device}."),
                    behavior: SnackBarBehavior.floating,
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Text("Log out",
                  style: TextStyle(color: Colors.red.shade500, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ACTIVITY CARD
  // ---------------------------------------------------------------------
  Widget _buildActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text("Recent Activity",
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 28),
            ...List.generate(_activity.length, (index) {
              final isLast = index == _activity.length - 1;
              return _activityTile(_activity[index], isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(_ActivityEntry entry, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon, size: 15, color: entry.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(entry.title,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      Text(entry.time,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(entry.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}