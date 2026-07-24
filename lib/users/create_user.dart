import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateUserComponent extends StatefulWidget {
  const CreateUserComponent({super.key});

  @override
  State<CreateUserComponent> createState() => _CreateUserComponentState();
}

class _CreateUserComponentState extends State<CreateUserComponent> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown / toggle state
  String? _selectedRole;
  String? _selectedDepartment;
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  final List<String> _roles = [];
  final List<String> _departments = [
    'Programs',
    'Finance & Administration',
    'Human Resources',
    'Procurement',
    'Information Technology',
    'Field Operations',
    'Monitoring & Evaluation',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await ApiService.getAllRoles();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _roles.clear();
            _roles.addAll(data.map((r) => r['name'].toString()).toList());
            
            // Auto-select "Administrator" or first role if none selected
            if (_roles.isNotEmpty && _selectedRole == null) {
              if (_roles.contains('Administrator')) {
                _selectedRole = 'Administrator';
              } else {
                _selectedRole = _roles.first;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load roles: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  // Simple password strength estimation (0-4)
  int _passwordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;
    return score;
  }

  Color _strengthColor(int strength) {
    switch (strength) {
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

  String _strengthLabel(int strength) {
    switch (strength) {
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _fullNameController.clear();
      _usernameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _notesController.clear();
      _selectedRole = null;
      _selectedDepartment = null;
      _isActive = true;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final userData = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'roleName': _selectedRole,
        'department': _selectedDepartment,
        'isActive': _isActive,
        'notes': _notesController.text.trim(),
      };

      try {
        final response = await ApiService.createUser(userData);

        if (response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "User '${_fullNameController.text.trim()}' created successfully! Notification email sent.",
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
          _resetForm();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? "Failed to create user."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Connection error. Please try again."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.green.shade700),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_passwordController.text);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------------- Clean Header ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade100, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _fullNameController,
                    builder: (context, _) {
                      final initials = _initialsOf(_fullNameController.text);
                      return Text(
                        initials.isEmpty ? '?' : initials,
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Create New User",
                        style: TextStyle(
                          color: Color(0xFF4C3C32),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Provision a new system account with role-based access.",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        "New Account",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20, height: 32),

          // ---------------- Form body (scrollable, fills remaining space) ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION 1: Personal Information
                    _sectionHeader("Personal Information", Icons.person_outline),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _fullNameController,
                            decoration: _fieldDecoration(
                              label: "Full Name *",
                              icon: Icons.badge_outlined,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Enter the user's full name";
                              }
                              if (value.trim().length < 3) {
                                return "Name is too short";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _fieldDecoration(
                              label: "Phone Number",
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(
                        label: "Email Address *",
                        icon: Icons.email_outlined,
                        helperText: "Used for login notifications and password resets",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Enter an email address";
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2: Account & Access
                    _sectionHeader("Account & Access", Icons.admin_panel_settings_outlined),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _fieldDecoration(
                        label: "Username *",
                        icon: Icons.alternate_email,
                        helperText: "Must be unique; used to sign in to the system",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Enter a username";
                        }
                        if (value.trim().contains(' ')) {
                          return "Username cannot contain spaces";
                        }
                        if (value.trim().length < 4) {
                          return "Username must be at least 4 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            decoration: _fieldDecoration(
                              label: "Role *",
                              icon: Icons.shield_outlined,
                              suffixIcon: _roles.isEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: _fetchRoles,
                                    tooltip: "Retry loading roles",
                                  )
                                : null,
                            ),
                            items: _roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedRole = val),
                            validator: (val) => val == null ? "Select a role" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedDepartment,
                            isExpanded: true,
                            decoration: _fieldDecoration(
                              label: "Department",
                              icon: Icons.apartment_outlined,
                            ),
                            items: _departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept,
                                child: Text(dept, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedDepartment = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Account Status",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          _isActive
                              ? "Active — user can sign in immediately"
                              : "Inactive — user access is disabled",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _isActive ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                        ),
                        value: _isActive,
                        activeThumbColor: Colors.green.shade700,
                        onChanged: (val) => setState(() => _isActive = val),
                        secondary: Icon(
                          _isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                          color: _isActive ? Colors.green.shade700 : Colors.grey.shade500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 3: Security
                    _sectionHeader("Security", Icons.lock_outline),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _fieldDecoration(
                        label: "Password *",
                        icon: Icons.lock_outline,
                        helperText: "At least 8 characters, with a number and a symbol",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter a password";
                        }
                        if (value.length < 8) {
                          return "Password must be at least 8 characters";
                        }
                        return null;
                      },
                    ),
                    if (_passwordController.text.isNotEmpty) ...[
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _strengthColor(strength),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _strengthLabel(strength),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _strengthColor(strength),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _fieldDecoration(
                        label: "Confirm Password *",
                        icon: Icons.lock_reset_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm the password";
                        }
                        if (value != _passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // SECTION 4: Additional Notes
                    _sectionHeader("Additional Information", Icons.info_outline),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        label: "Additional Notes",
                        icon: Icons.notes_outlined,
                        helperText: "Optional — any extra context about this user",
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ---------------- Footer actions ----------------
          Container(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _resetForm,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Clear Form"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isSubmitting ? "Creating User..." : "Save User",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}