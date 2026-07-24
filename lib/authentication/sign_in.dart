import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
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

      Timer(const Duration(milliseconds: 2000), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandBrown,
      body: Stack(
        children: [
          // Minimalist moving background for professionalism
          const Positioned.fill(child: _SubtleMovingBackground()),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: _buildLoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBrandCream.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/age-logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: kBrandBrown),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "SECURE SIGN IN",
                  style: TextStyle(
                    color: kBrandOlive,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Welcome Back",
            style: TextStyle(
              color: kBrandBrown,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your credentials to access your dashboard.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          _inputLabel("PORTAL ROLE"),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: _fieldStyle(Icons.security_rounded),
            dropdownColor: Colors.white,
            items: ["Administrator", "Sponsor", "School Coordinator", "Scholar"]
                .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role, style: const TextStyle(color: kBrandBrown, fontSize: 14, fontWeight: FontWeight.bold)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 20),

          _inputLabel("USERNAME OR EMAIL"),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: _fieldStyle(Icons.person_outline_rounded),
            validator: (value) => (value == null || value.trim().isEmpty) ? "Required" : null,
          ),
          const SizedBox(height: 20),

          _inputLabel("PASSWORD"),
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: _fieldStyle(
              Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: kBrandOlive, size: 20),
                onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
          ),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: kBrandOlive,
                    onChanged: (val) => setState(() => _rememberMe = val!),
                  ),
                  const Text("Remember me", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Reset Password", style: TextStyle(color: kBrandOrange, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text("AUTHENTICATE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(color: kBrandBrown.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  InputDecoration _fieldStyle(IconData icon, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: kBrandOlive, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }
}

class _SubtleMovingBackground extends StatefulWidget {
  const _SubtleMovingBackground();
  @override
  State<_SubtleMovingBackground> createState() => _SubtleMovingBackgroundState();
}

class _SubtleMovingBackgroundState extends State<_SubtleMovingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: _SubtleLinePainter(_controller.value));
      },
    );
  }
}

class _SubtleLinePainter extends CustomPainter {
  final double progress;
  _SubtleLinePainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      paint.color = kBrandOlive.withOpacity(0.05);
      paint.strokeWidth = 200.0;
      final path = Path();
      final startY = (size.height / 8) * i;
      path.moveTo(-size.width, startY);
      path.lineTo(size.width * 2, startY + 500);
      canvas.save();
      canvas.translate((progress * size.width) % size.width, 0);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
