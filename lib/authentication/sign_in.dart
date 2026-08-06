import 'dart:async';
import 'dart:ui';
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
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _backgroundController.dispose();
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

          // Save token in ApiService for subsequent requests
          ApiService.setToken(token, persist: _rememberMe);
          
          // Initialize Permissions
          PermissionService.init(userData);

          if (mounted) {
            setState(() => _isLoading = false);
            
            final String role = userData['role'] ?? 'User';
            final String normalizedRole = role.trim().toLowerCase();
            
            debugPrint('LOGIN DEBUG: Detected role is "$role", normalized to "$normalizedRole"');

            // 1. Admin Group
            final bool hasAdminAccess = [
              'administrator', 
              'program manager', 
              'program coordinator', 
              'country director'
            ].contains(normalizedRole);

            // 2. Field Operations Group
            final bool isFieldOfficer = [
              'field officer', 
              'field coordinator', 
              'field operations', 
              'operational officer'
            ].contains(normalizedRole);

            debugPrint('LOGIN DEBUG: hasAdminAccess=$hasAdminAccess, isFieldOfficer=$isFieldOfficer');

            if (userData['mustResetPassword'] == true || userData['isFirstLogin'] == true) {
              Navigator.pushReplacementNamed(context, '/password-reset');
              return;
            }

            if (hasAdminAccess) {
              Navigator.pushReplacementNamed(
                context,
                '/admin/home',
                arguments: {
                  'username': userData['fullName'] ?? _usernameController.text.trim(),
                  'role': role,
                  'profilePicture': userData['profile_picture'] ?? userData['profilePicture'],
                },
              );
            } else if (isFieldOfficer) {
              debugPrint('LOGIN DEBUG: Routing to Field Operations Portal...');
              Navigator.pushReplacementNamed(
                context,
                '/field-operations/home',
                arguments: {
                  'username': userData['fullName'] ?? _usernameController.text.trim(),
                  'role': role,
                  'profilePicture': userData['profile_picture'] ?? userData['profilePicture'],
                },
              );
            } else {
              debugPrint('LOGIN DEBUG: Routing to standard Operations Dashboard...');
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: {
                  'username': userData['fullName'] ?? _usernameController.text.trim(),
                  'role': role,
                  'profilePicture': userData['profile_picture'] ?? userData['profilePicture'],
                },
              );
            }
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            final String message = response.data['message'] ?? "Invalid username or password.";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text("Authentication Failed: $message")),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          String errorMessage = "Authentication failed. Please check your credentials.";
          
          if (e is DioException) {
            if (e.response?.data != null && e.response?.data['message'] != null) {
              errorMessage = e.response?.data['message'];
            } else if (e.response?.statusCode == 401) {
              errorMessage = "Invalid username/email or password.";
            } else if (e.response?.statusCode == 403) {
              errorMessage = "Your account is disabled. Please contact the administrator.";
            } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
              errorMessage = "Server connection timed out. Please try again later.";
            } else if (e.type == DioExceptionType.connectionError) {
              errorMessage = "Unable to connect to the server. Check your internet connection.";
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Animated Background
          _buildAnimatedBackground(size),

          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.1)),
              ),
            ),
          ),

          // 3. Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: 40),
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
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 40, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 30 : 40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _buildLoginForm(isSmallScreen),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Footer attribution
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "© 2026 AGE Africa • AGE Africa System",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            // Static Base
            Container(color: kBrandBrown),

            // Dynamic Gradients
            Positioned(
              top: -size.height * 0.2 + (20 * _backgroundController.value),
              left: -size.width * 0.2 + (40 * _backgroundController.value),
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kBrandOlive.withOpacity(0.4),
                      kBrandOlive.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1 - (30 * _backgroundController.value),
              right: -size.width * 0.1 - (20 * _backgroundController.value),
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kBrandOrange.withOpacity(0.3),
                      kBrandOrange.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo & Branding
          Center(
            child: Column(
              children: [
                Container(
                  height: isSmallScreen ? 70 : 90,
                  width: isSmallScreen ? 70 : 90,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kBrandBrown.withValues(alpha: 0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/age-logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.school_rounded,
                      size: isSmallScreen ? 35 : 45,
                      color: kBrandOlive,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                const Text(
                  "PORTAL ACCESS",
                  style: TextStyle(
                    color: kBrandOlive,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    color: kBrandBrown,
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),

          // Fields
          _buildInputLabel("USERNAME OR EMAIL"),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kBrandBrown),
            decoration: _fieldDecoration(Icons.person_outline_rounded, hint: "Enter your username"),
            validator: (value) => (value == null || value.trim().isEmpty) ? "Username is required" : null,
          ),
          const SizedBox(height: 20),

          _buildInputLabel("PASSWORD"),
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kBrandBrown),
            decoration: _fieldDecoration(
              Icons.lock_open_rounded,
              hint: "••••••••",
              suffix: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kBrandBrown.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? "Password is required" : null,
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: kBrandOlive,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _rememberMe = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Keep me signed in",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kBrandBrown,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: kBrandOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: kBrandBrown.withValues(alpha: 0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "SIGN IN TO PORTAL",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    ApiService.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Session cleared. Try logging in again.")),
                    );
                  },
                  child: const Text(
                    "Clear Session",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("|", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Contact Admin",
                    style: TextStyle(
                      color: kBrandOlive,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: kBrandBrown.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(IconData icon, {String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
      prefixIcon: Icon(icon, color: kBrandOlive, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kBrandOlive, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
