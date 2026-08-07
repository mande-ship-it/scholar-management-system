import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();

    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    if (ApiService.isAuthenticated) {
      try {
        final response = await ApiService.getAccountProfile();
        if (response.statusCode == 200 && mounted) {
          final userData = response.data['data'];
          PermissionService.init(userData);

          final String role = userData['role_name'] ?? userData['role'] ?? 'User';
          final String normalizedRole = role.trim().toLowerCase();

          String targetRoute = '/home';
          if (normalizedRole == 'administrator') {
            targetRoute = '/admin/home';
          } else if ([
            'field officer',
            'field coordinator',
            'field operations',
            'operational officer'
          ].contains(normalizedRole)) {
            targetRoute = '/field-operations/home';
          }

          Navigator.pushReplacementNamed(
            context,
            targetRoute,
            arguments: {
              'username': userData['full_name'] ?? userData['fullName'] ?? 'User',
              'role': role,
              'profilePicture': userData['profile_picture'] ?? userData['profilePicture'],
            },
          );
        }
      } catch (e) {
        // Token expired
        ApiService.logout();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await ApiService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (response.statusCode == 200) {
          final responseBody = response.data;
          final data = responseBody['data'];
          final String token = data['token'];
          final userData = data['user'];

          ApiService.setToken(token, persist: _rememberMe);
          PermissionService.init(userData);

          if (mounted) {
            setState(() => _isLoading = false);
            
            final String role = userData['role'] ?? userData['role_name'] ?? 'User';
            final String normalizedRole = role.trim().toLowerCase();

            if (userData['mustResetPassword'] == true || userData['isFirstLogin'] == true) {
              Navigator.pushReplacementNamed(context, '/password-reset');
              return;
            }

            final bool hasAdminAccess = [
              'administrator', 'program manager', 'program coordinator', 'country director'
            ].contains(normalizedRole);

            final bool isFieldOfficer = [
              'field officer', 'field coordinator', 'field operations'
            ].contains(normalizedRole);

            if (hasAdminAccess) {
              Navigator.pushReplacementNamed(context, '/admin/home', arguments: {
                'username': userData['fullName'] ?? _usernameController.text.trim(),
                'role': role,
                'profilePicture': userData['profilePicture'],
              });
            } else if (isFieldOfficer) {
              Navigator.pushReplacementNamed(context, '/field-operations/home', arguments: {
                'username': userData['fullName'] ?? _usernameController.text.trim(),
                'role': role,
                'profilePicture': userData['profilePicture'],
              });
            } else {
              Navigator.pushReplacementNamed(context, '/home', arguments: {
                'username': userData['fullName'] ?? _usernameController.text.trim(),
                'role': role,
                'profilePicture': userData['profilePicture'],
              });
            }
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.data['message'] ?? "Invalid username or password."),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to connect to server. Please check your connection."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24, 
            vertical: 40,
          ),
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 40, 
                vertical: isSmallScreen ? 28 : 40
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 32),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildLoginForm(isSmallScreen),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                // Professional Logo matching Windows
                Container(
                  height: isSmallScreen ? 64 : 80,
                  width: isSmallScreen ? 64 : 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Image.asset(
                    'assets/images/age-logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, _, __) => const Icon(Icons.school_rounded, size: 40, color: kBrandOlive),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                Text(
                  "AGE AFRICA SYSTEM",
                  style: TextStyle(
                    color: kBrandOlive,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Portal Login",
                  style: TextStyle(
                    color: kBrandBrown,
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),

          _buildLabel("ACCOUNT IDENTITY"),
          TextFormField(
            controller: _usernameController,
            decoration: _inputDeco(Icons.person_outline_rounded, "Username or Email"),
            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          ),
          const SizedBox(height: 20),

          _buildLabel("SECURITY KEY"),
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            decoration: _inputDeco(
              Icons.lock_open_rounded, 
              "••••••••",
              suffix: IconButton(
                icon: Icon(_isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 20, width: 20,
                    child: Checkbox(
                      value: _rememberMe, 
                      onChanged: (v) => setState(() => _rememberMe = v!),
                      activeColor: kBrandOlive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("Stay signed in", style: TextStyle(fontSize: 12, color: kBrandBrown)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text("Reset Access?", style: TextStyle(color: kBrandOrange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("SIGN IN TO SYSTEM", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Need help?", style: TextStyle(color: Colors.grey, fontSize: 12)),
              TextButton(onPressed: () {}, child: const Text("Contact Technical Support", style: TextStyle(color: kBrandOlive, fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    );
  }

  InputDecoration _inputDeco(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: kBrandOlive, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }
}

