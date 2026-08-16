import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class CreateUserComponent extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;
  final bool showBackButton;
  const CreateUserComponent({super.key, this.onBack, this.onSuccess, this.showBackButton = true});

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown / toggle state
  String? _selectedRole;
  String? _assignedDistrict;
  dynamic _selectedDepartmentId;
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  final List<dynamic> _roles = [];
  final List<dynamic> _departments = [];

  dynamic _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _fetchDepartments();
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await ApiService.getAllRoles();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];

        if (mounted) {
          setState(() {
            _roles.clear();
            _roles.addAll(data);
            
            if (_roles.isNotEmpty && _selectedRoleId == null) {
              try {
                final adminRole = _roles.firstWhere((r) => r['name'] == 'Administrator');
                _selectedRoleId = adminRole['id'] ?? adminRole['_id'];
              } catch (_) {
                _selectedRoleId = _roles.first['id'] ?? _roles.first['_id'];
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await ApiService.getAllDepartments();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];

        if (mounted) {
          setState(() {
            _departments.clear();
            _departments.addAll(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
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
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      default: return kBrandOlive;
    }
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1: return "Weak";
      case 2: return "Fair";
      case 3: return "Good";
      default: return "Strong";
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
      _selectedRoleId = null;
      _selectedDepartmentId = null;
      _isActive = true;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError("Passwords do not match.");
        return;
      }

      setState(() => _isSubmitting = true);

      final userData = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'roleId': _selectedRoleId,
        'assignedDistrict': _assignedDistrict,
        'departmentId': _selectedDepartmentId,
        'isActive': _isActive,
        'notes': _notesController.text.trim(),
      };

      try {
        final response = await ApiService.createUser(userData);

        if (response.statusCode == 201 || response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("User account synchronized with central directory."),
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (widget.onBack != null) {
            widget.onBack!();
          } else {
            _resetForm();
          }
        } else {
          _showError(response.data['message'] ?? "Creation failed.");
        }
      } catch (e) {
        _showError("Critical system error: Failed to reach identity server.");
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    final strength = _passwordStrength(_passwordController.text);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          _buildHeader(isMobile),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("1. Identity & Profile"),
                    const SizedBox(height: 16),
                    _buildIdentityCard(isMobile),
                    
                    const SizedBox(height: 32),
                    _sectionTitle("2. System Access"),
                    const SizedBox(height: 16),
                    _buildAccessCard(isMobile),

                    const SizedBox(height: 32),
                    _sectionTitle("3. Security Credentials"),
                    const SizedBox(height: 16),
                    _buildSecurityCard(strength, isMobile),

                    const SizedBox(height: 48),
                    _buildSubmitButton(isMobile),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
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
          if (widget.showBackButton) ...[
            IconButton(
              onPressed: widget.onBack ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              "Identity Provisioning",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          IconButton(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Reset Form",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
    );
  }

  Widget _buildIdentityCard(bool isMobile) {
    return _cardShell(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildTextField(_fullNameController, "Full Name", Icons.badge_outlined, onChanged: (v) => setState(() {})),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined, keyboardType: TextInputType.phone),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildTextField(_fullNameController, "Full Name", Icons.badge_outlined, onChanged: (v) => setState(() {})),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined, keyboardType: TextInputType.phone),
              ),
            ],
          ),
        const SizedBox(height: 16),
        _buildTextField(_emailController, "Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress, helper: "Used for notifications and resets."),
      ],
    );
  }

  Widget _buildAccessCard(bool isMobile) {
    final String? selectedRoleName = _roles.firstWhere(
      (r) => (r['id'] ?? r['_id']) == _selectedRoleId, 
      orElse: () => {'name': ''}
    )['name'];
    final bool isFieldRole = selectedRoleName?.toLowerCase().contains('field') ?? false;

    return _cardShell(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildRoleDropdown(),
          const SizedBox(height: 16),
          _buildDepartmentDropdown(),
        ] else
          Row(
            children: [
              Expanded(child: _buildRoleDropdown()),
              const SizedBox(width: 20),
              Expanded(child: _buildDepartmentDropdown()),
            ],
          ),
        if (isFieldRole) ...[
          const SizedBox(height: 16),
          _buildDropdown("Assigned Monitoring District", _assignedDistrict, kMalawiDistricts, Icons.location_on_rounded, (v) => setState(() => _assignedDistrict = v)),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text("Restricted scope for field operations.", style: TextStyle(fontSize: 10, color: kBrandOrange, fontWeight: FontWeight.bold)),
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(_usernameController, "System Username", Icons.alternate_email_rounded, helper: "Must be unique. Used for signing in."),
        const SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Enable Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            value: _isActive,
            activeColor: kBrandOlive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(int strength, bool isMobile) {
    return _cardShell(
      isMobile: isMobile,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          decoration: _inputDeco("Secure Password", Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: strength / 4, minHeight: 6, color: _strengthColor(strength), backgroundColor: Colors.grey.shade100),
                ),
              ),
              const SizedBox(width: 12),
              Text(_strengthLabel(strength), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _strengthColor(strength))),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDeco("Confirm Password", Icons.lock_reset_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitForm,
        icon: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_rounded, size: 18),
        label: Text(_isSubmitting ? "PROVISIONING..." : "REGISTER USER ACCOUNT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: kBrandOlive,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _cardShell({required List<Widget> children, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? helper, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: _inputDeco(label, icon).copyWith(helperText: helper),
      validator: (v) => (v == null || v.isEmpty) ? "Field is required" : null,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<dynamic>(
      value: _selectedRoleId,
      isExpanded: true,
      decoration: _inputDeco("Assigned Role", Icons.shield_outlined),
      items: _roles.map((r) => DropdownMenuItem(value: r['id'] ?? r['_id'], child: Text(r['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() => _selectedRoleId = v),
      validator: (v) => v == null ? "Required" : null,
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<dynamic>(
      value: _selectedDepartmentId,
      isExpanded: true,
      decoration: _inputDeco("Department", Icons.apartment_rounded),
      items: _departments.map((d) => DropdownMenuItem(value: d['id'] ?? d['_id'], child: Text(d['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() => _selectedDepartmentId = v),
      validator: (v) => v == null ? "Required" : null,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDeco(label, icon),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.6)),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      helperStyle: const TextStyle(fontSize: 10),
    );
  }
}
