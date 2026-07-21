import 'dart:async';
import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: "Edward Young Shaba");
  final _passwordController = TextEditingController(text: "password123");
  bool _isPasswordObscured = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String _selectedRole = "Administrator";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate a network loading state to make the portal feel realistic
      Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {
              'username': _usernameController.text.trim(),
              'role': _selectedRole,
            },
          );
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 850;

    return Scaffold(
      backgroundColor: kBrandCream.withValues(alpha: 0.2),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isDesktop
              ? Row(
                  children: [
                    // Left split: Hero Image Banner
                    const Expanded(
                      flex: 12,
                      child: _HeroBannerWidget(isMobile: false),
                    ),
                    // Right split: Form Panel
                    Expanded(
                      flex: 11,
                      child: Container(
                        height: double.infinity,
                        alignment: Alignment.center,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 480),
                                padding: const EdgeInsets.all(48),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kBrandBrown.withValues(alpha: 0.08),
                                      blurRadius: 40,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: _buildLoginForm(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const _HeroBannerWidget(isMobile: true),
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 450),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: kBrandBrown.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _buildLoginForm(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Builder for the login form panel contents
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand Logo in a "White Card" style container
          Center(
            child: Column(
              children: [
                Container(
                  height: 90,
                  width: 90,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kBrandBrown.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: kBrandCream.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Image.asset(
                    'assets/images/age-logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: kBrandBrown),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "AGE Africa Portal",
                  style: TextStyle(
                    color: kBrandOlive,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Welcome Back",
            style: TextStyle(
              color: kBrandBrown,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in to access the Scholar Management Portal.",
            style: TextStyle(
              color: kBrandBrown.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Role dropdown selection
          const _FieldLabelWidget(labelText: "Select Portal Role"),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: _buildInputDecoration(
              icon: Icons.security,
              fillColor: kBrandCream.withValues(alpha: 0.15),
            ),
            dropdownColor: Colors.white,
            items: ["Administrator", "Sponsor", "School Coordinator", "Scholar"]
                .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style: const TextStyle(color: kBrandBrown, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedRole = val;
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // Username field
          const _FieldLabelWidget(labelText: "Username or Email"),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.w500, fontSize: 14),
            decoration: _buildInputDecoration(
              icon: Icons.person_outline,
              fillColor: kBrandCream.withValues(alpha: 0.15),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Username or email is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password field
          const _FieldLabelWidget(labelText: "Password"),
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.w500, fontSize: 14),
            decoration: _buildInputDecoration(
              icon: Icons.lock_outline,
              fillColor: kBrandCream.withValues(alpha: 0.15),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kBrandBrown.withValues(alpha: 0.6),
                  size: 20,
                  ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Remember me / Forgot password row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: kBrandOlive,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(color: kBrandBrown.withValues(alpha: 0.2), width: 1.5),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rememberMe = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Keep me signed in",
                    style: TextStyle(
                      color: kBrandBrown.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: kBrandOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Sign In to Portal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Security details
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kBrandCream.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person_outlined, size: 14, color: kBrandOlive),
                  const SizedBox(width: 8),
                  Text(
                    "Secure SSL Encrypted Access",
                    style: TextStyle(
                      color: kBrandBrown.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  // Input decoration helper
  InputDecoration _buildInputDecoration({
    required IconData icon,
    required Color fillColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: kBrandBrown.withValues(alpha: 0.4), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBrandOlive, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: const TextStyle(fontSize: 12),
    );
  }
}

// Separate Widget for Field Labels
class _FieldLabelWidget extends StatelessWidget {
  final String labelText;

  const _FieldLabelWidget({required this.labelText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        labelText,
        style: TextStyle(
          color: kBrandBrown.withValues(alpha: 0.8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Separate Widget for the Hero Visual Section (Covers full screen height on desktop)
class _HeroBannerWidget extends StatelessWidget {
  final bool isMobile;

  const _HeroBannerWidget({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isMobile ? 360 : double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/age.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 64,
          vertical: isMobile ? 48 : 64,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              kBrandBrown.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kBrandOlive,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "SINCE 2005",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Creating life-changing\nopportunities for girls.",
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 52,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            if (!isMobile)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  "Providing scholarships, life skills, and mentoring program management to empower young women across Africa.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            if (!isMobile) const SizedBox(height: 40),
            if (!isMobile)
              const Text(
                "© 2026 AGE Africa. All rights reserved.",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
