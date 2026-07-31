import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown / toggle state
  String? _selectedRole;
  dynamic _selectedDepartmentId;
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  final List<String> _roles = [];
  final List<dynamic> _departments = [];

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
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _roles.clear();
            _roles.addAll(data.map((r) => r['name'].toString()).toList());
            
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
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await ApiService.getAllDepartments();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
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
      _selectedRole = null;
      _selectedDepartmentId = null;
      _isActive = true;
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
        'departmentId': _selectedDepartmentId,
        'isActive': _isActive,
        'notes': _notesController.text.trim(),
      };

      try {
        final response = await ApiService.createUser(userData);

        if (response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User account created successfully. Activation email sent."),
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _resetForm();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account creation failed. Please check connection."), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("1. Identity & Profile"),
                    const SizedBox(height: 16),
                    _buildIdentityCard(),
                    
                    const SizedBox(height: 32),
                    _sectionTitle("2. System Access & Permissions"),
                    const SizedBox(height: 16),
                    _buildAccessCard(),

                    const SizedBox(height: 32),
                    _sectionTitle("3. Security Credentials"),
                    const SizedBox(height: 16),
                    _buildSecurityCard(strength),

                    const SizedBox(height: 48),
                    _buildSubmitButton(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kBrandOlive.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsOf(_fullNameController.text),
              style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Create User Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                Text("Provision a new system user with specialized role permissions.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
    );
  }

  Widget _buildIdentityCard() {
    return _cardShell(
      children: [
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
        const SizedBox(height: 20),
        _buildTextField(_emailController, "Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress, helper: "Notifications and password resets will be sent here."),
      ],
    );
  }

  Widget _buildAccessCard() {
    return _cardShell(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown("Assigned Role", _selectedRole, _roles, Icons.shield_outlined, (v) => setState(() => _selectedRole = v)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: DropdownButtonFormField<dynamic>(
                value: _selectedDepartmentId,
                isExpanded: true,
                decoration: _inputDeco("Department", Icons.apartment_rounded),
                items: _departments.map((d) => DropdownMenuItem(value: d['id'], child: Text(d['name'], overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedDepartmentId = v),
                validator: (v) => v == null ? "Required" : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(_usernameController, "System Username", Icons.alternate_email_rounded, helper: "Must be unique. Used for signing in."),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: SwitchListTile(
            title: const Text("Enable Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text("Allow this user to sign in immediately upon registration.", style: TextStyle(fontSize: 12)),
            value: _isActive,
            activeColor: kBrandOlive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(int strength) {
    return _cardShell(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          decoration: _inputDeco("Secure Password", Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
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
              Text(_strengthLabel(strength), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _strengthColor(strength))),
            ],
          ),
        ],
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDeco("Confirm Password", Icons.lock_reset_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitForm,
        icon: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_rounded, size: 20),
        label: Text(_isSubmitting ? "CREATING ACCOUNT..." : "REGISTER USER ACCOUNT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 22),
          backgroundColor: kBrandOlive,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _cardShell({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
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
