import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

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
  String? _profilePicture;
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
  bool _isUploading = false;
  final _profileFormKey = GlobalKey<FormState>();

  int _selectedTab = 0; // 0 = Personal Info, 1 = Security, 2 = Activity

  // Security
  final _securityFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  List<_ActivityEntry> _activity = [];
  bool _isLoadingActivity = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _bioController = TextEditingController();
    _fetchProfile();
    _fetchActivity();
  }

  Future<void> _fetchActivity() async {
    setState(() => _isLoadingActivity = true);
    try {
      final response = await ApiService.getRecentActivities();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _activity = data.map((a) {
              final type = a['type'] ?? 'info';
              Color color = Colors.blue;
              IconData icon = Icons.info_outline;

              if (type == 'success') { color = kBrandOlive; icon = Icons.check_circle_outline; }
              else if (type == 'warning') { color = kBrandOrange; icon = Icons.warning_amber_rounded; }
              else if (type == 'error') { color = Colors.redAccent; icon = Icons.error_outline; }

              return _ActivityEntry(
                icon: icon,
                color: color,
                title: a['message'] ?? 'System Activity',
                subtitle: "Performed by ${a['actor'] ?? 'System'}",
                time: _timeAgo(a['created_at']),
              );
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    } finally {
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return DateFormat('dd MMM').format(date);
    } catch (_) {
      return '';
    }
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
            _profilePicture = u['profile_picture'];
            _memberSince =
                DateTime.tryParse(u['created_at'] ?? '') ?? DateTime.now();
            _lastLogin = DateTime.now();

            _originalValues = {
              'name': u['fullName'] ?? u['full_name'] ?? '',
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

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final file = result.files.single;
      final response = await ApiService.uploadProfilePicture(file.bytes!, file.name);
      if (response.statusCode == 200) {
        setState(() {
          _profilePicture = response.data['data']['profile_picture'];
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated."), backgroundColor: kBrandOlive),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image."), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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

  Widget _buildPortalHeader(bool isVerySmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Account Governance",
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
            icon: const Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Sync Profile",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    final bool isVerySmall = screenWidth < 500;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F2F5), // Facebook-style background
      child: _isLoading
          ? const Center(
              child: Padding(
              padding: EdgeInsets.all(80.0),
              child: CircularProgressIndicator(),
            ))
          : Column(
              children: [
                _buildPortalHeader(isVerySmall),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderCard(isMobile),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 20),
                          child: Column(
                            children: [
                              if (_selectedTab == 0) _buildPersonalInfoCard(isMobile),
                              if (_selectedTab == 1) _buildSecurityCard(isMobile),
                              if (_selectedTab == 2) _buildActivityCard(isMobile),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER CARD
  // ---------------------------------------------------------------------
  Widget _buildHeaderCard(bool isMobile) {
    Widget avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isMobile ? 120 : 160,
          height: isMobile ? 120 : 160,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: (_profilePicture != null)
            ? Image.network(
                ApiService.getFullUrl(_profilePicture),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person_rounded, color: kBrandBrown, size: isMobile ? 60 : 80),
              )
            : Icon(Icons.person_rounded, color: kBrandBrown, size: isMobile ? 60 : 80),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: InkWell(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E6EB),
                shape: BoxShape.circle,
              ),
              child: _isUploading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kBrandBrown))
                : const Icon(Icons.camera_alt_rounded, size: 20, color: kBrandBrown),
            ),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(28, isMobile ? 40 : 60, 28, 0),
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 16),
          Text(
            _originalValues['name'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kBrandBrown,
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _originalValues['bio'] ?? 'No bio provided',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _buildTabsBar(isMobile),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TABS BAR
  // ---------------------------------------------------------------------
  Widget _buildTabsBar(bool isMobile) {
    final tabs = [
      ("About", Icons.info_outline_rounded),
      ("Security", Icons.lock_outline_rounded),
      ("Activity", Icons.history_rounded),
    ];

    return Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedTab == index;
        return InkWell(
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? kBrandOlive : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              tabs[index].$1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? kBrandOlive : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------
  // PERSONAL INFO CARD
  // ---------------------------------------------------------------------
  Widget _buildPersonalInfoCard(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return Column(
            children: [
              _buildAboutSection(),
              const SizedBox(height: 16),
              _buildActionsSection(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildAboutSection()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildActionsSection()),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Intro", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 20),
          _introItem(Icons.work_rounded, "Department: $_department"),
          _introItem(Icons.verified_user_rounded, "Role: $_role"),
          _introItem(Icons.location_on_rounded, "Lives in ${_originalValues['location']}"),
          _introItem(Icons.alternate_email_rounded, "Email: ${_originalValues['email']}"),
          _introItem(Icons.phone_rounded, "Phone: ${_originalValues['phone']}"),
          _introItem(Icons.calendar_month_rounded, "Joined ${DateFormat('MMMM yyyy').format(_memberSince)}"),
          if (!_isEditing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startEditing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4E6EB),
                  foregroundColor: kBrandBrown,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Edit Details", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (_isEditing) ...[
            const Divider(height: 40),
            Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  _buildTextField(_nameController, "Full Name", Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildTextField(_locationController, "Location", Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _buildTextField(_bioController, "Bio", Icons.notes_rounded, maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _cancelEditing, child: const Text("Cancel")),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white),
                        child: const Text("Save Changes"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _introItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 16),
          _actionTile(Icons.logout_rounded, "Log Out", "Exit your current session", Colors.redAccent, _handleLogout),
          _actionTile(Icons.help_outline_rounded, "Help & Support", "Visit documentation", kBrandBrown, () {}),
          _actionTile(Icons.settings_outlined, "Privacy Settings", "Manage account visibility", kBrandBrown, () {}),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
    );
  }

  // ---------------------------------------------------------------------
  // SECURITY CARD
  // ---------------------------------------------------------------------
  Widget _buildSecurityCard(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1)],
          ),
          child: Form(
            key: _securityFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Update Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const Divider(height: 32),
                _buildTextField(_currentPasswordController, "Current Password", Icons.lock_outline, obscureText: true),
                const SizedBox(height: 12),
                _buildTextField(_newPasswordController, "New Password", Icons.lock_reset_rounded, obscureText: true),
                const SizedBox(height: 12),
                _buildTextField(_confirmPasswordController, "Confirm New Password", Icons.lock_reset_rounded, obscureText: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save New Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // ACTIVITY CARD
  // ---------------------------------------------------------------------
  Widget _buildActivityCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Account Activity Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const Divider(height: 32),
          if (_activity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("No recent activities recorded.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          ...List.generate(_activity.length, (index) {
            final entry = _activity[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: entry.color.withOpacity(0.1), child: Icon(entry.icon, size: 16, color: entry.color)),
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
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }
}
