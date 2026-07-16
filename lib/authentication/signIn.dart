import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Method to trigger the custom pop-up dialog
  void _showSignInDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Sign In Dialog",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // Curve the animation
        final curvedValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.8 + (curvedValue * 0.2),
          child: Opacity(
            opacity: anim1.value,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SignInDialogForm(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Brand Color Palette
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandCreamDark = Color(0xFFF3E7C4);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 850;

    return Scaffold(
      backgroundColor: brandCream,
      body: Stack(
        children: [
          // 1. Artistic Corner Background Shapes
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: brandOlive.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: brandOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: brandBrown.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Main Page Layout (Centered split/stacked screen)
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 680),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: brandBrown.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: isDesktop
                        ? Row(
                            children: [
                              // Left split: Welcome message and Brand identity
                              Expanded(
                                flex: 5,
                                child: Container(
                                  color: brandBrown,
                                  child: Stack(
                                    children: [
                                      // Decorative pattern overlay in background
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: WelcomeBackgroundPainter(),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Top Branding Logo / Title
                                            Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.all(6),
                                                  height: 36,
                                                  child: Image.asset(
                                                    'assets/images/age-logo.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  "AGE Africa",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    letterSpacing: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Center Hero Text & Mission
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: brandOlive.withValues(alpha: 0.2),
                                                    border: Border.all(color: brandOlive, width: 1.5),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Text(
                                                    "Scholar Portal",
                                                    style: TextStyle(
                                                      color: brandCream,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  "Creating life-changing\nopportunities for girls.",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    height: 1.2,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'Georgia',
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  "Providing scholarships, life skills, and mentoring program management to empower young women across Africa.",
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                    fontSize: 15,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Bottom footer tag
                                            const Text(
                                              "© 2026 AGE Africa. All rights reserved.",
                                              style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Right split: Onboarding CTA
                              Expanded(
                                flex: 6,
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.waves,
                                        color: brandOrange,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        "Welcome to the Scholar Management System",
                                        style: TextStyle(
                                          color: brandBrown,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "A comprehensive platform to track academic progress, manage sponsors, allocate funding, and evaluate scholar outcomes.",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 48),

                                      // Primary Call to Action Button
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: ElevatedButton(
                                          onPressed: () => _showSignInDialog(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: brandOrange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 4,
                                            shadowColor: brandOrange.withValues(alpha: 0.4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Enter Scholar Portal",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(Icons.arrow_forward, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Icon(Icons.lock_outline, size: 14, color: brandBrown.withValues(alpha: 0.5)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Secured, authorized access only",
                                            style: TextStyle(
                                              color: brandBrown.withValues(alpha: 0.5),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            // Mobile UI layout
                            child: Column(
                              children: [
                                Container(
                                  color: brandBrown,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Logo
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        height: 32,
                                        child: Image.asset(
                                          'assets/images/age-logo.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      const Text(
                                        "AGE Africa",
                                        style: TextStyle(
                                          color: brandCream,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Creating life-changing opportunities for girls.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          height: 1.25,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Georgia',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color: Colors.white,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Scholar Management Portal",
                                        style: TextStyle(
                                          color: brandBrown,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Sign in to manage scholarship profiles, academic records, and sponsorship reports.",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _showSignInDialog(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: brandOrange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Enter Scholar Portal",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward, size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Center(
                                        child: Text(
                                          "Authorized Access Only",
                                          style: TextStyle(
                                            color: brandBrown.withValues(alpha: 0.5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Background painter for the left side of the split screen
class WelcomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFAF2DB).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Draw flowing curves that suggest landscapes or sun rays
    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width, size.height * 0.6);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width, size.height * 0.85);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    // Decorative circle representing a rising sun
    final sunPaint = Paint()
      ..color = const Color(0xFFE05B1C).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 90, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// The pop-up Sign-in Form Dialog Box
class SignInDialogForm extends StatefulWidget {
  const SignInDialogForm({super.key});

  @override
  State<SignInDialogForm> createState() => _SignInDialogFormState();
}

class _SignInDialogFormState extends State<SignInDialogForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: "Edward Young Shaba");
  final _passwordController = TextEditingController(text: "password123");
  bool _isPasswordObscured = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String _selectedRole = "Administrator";

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
          // Close the dialog
          Navigator.pop(context);
          // Route to HomePage and pass username as arguments
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

  @override
  Widget build(BuildContext context) {
    // Brand Colors
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 20,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandCream, width: 2),
          boxShadow: [
            BoxShadow(
              color: brandBrown.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/age-logo.png',
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        color: brandBrown,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Scholar Management System Access",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: brandBrown.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Access Role Selector
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: "Portal Role",
                  labelStyle: const TextStyle(color: brandBrown, fontSize: 13),
                  prefixIcon: const Icon(Icons.security, color: brandBrown, size: 20),
                  filled: true,
                  fillColor: brandCream.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: brandBrown.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOlive, width: 2),
                  ),
                ),
                dropdownColor: Colors.white,
                items: ["Administrator", "Sponsor", "School Coordinator", "Scholar"]
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(color: brandBrown, fontSize: 14),
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
              const SizedBox(height: 16),

              // Username/Email Text Field
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: brandBrown),
                decoration: InputDecoration(
                  labelText: "Username or Email",
                  labelStyle: const TextStyle(color: brandBrown, fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline, color: brandBrown, size: 20),
                  filled: true,
                  fillColor: brandCream.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: brandBrown.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOlive, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Username or email is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Text Field
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                style: const TextStyle(color: brandBrown),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: brandBrown, fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline, color: brandBrown, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: brandBrown,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: brandCream.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: brandBrown.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOlive, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Remember Me & Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: brandOlive,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _rememberMe = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Remember me",
                        style: TextStyle(
                          color: brandBrown,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Demo alert
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password reset links are disabled for demo accounts."),
                          backgroundColor: brandBrown,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: brandOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons: Sign In / Cancel
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandBrown,
                        side: BorderSide(color: brandBrown.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
