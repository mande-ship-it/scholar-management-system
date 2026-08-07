import 'dart:ui';
import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _isObscured = true;

  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _handleRequestCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(_emailController.text.trim());
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reset code sent to your email"), backgroundColor: kBrandOlive),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ApiService.resetPassword(
          _emailController.text.trim(),
          _otpController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password reset successful! Please log in."), backgroundColor: kBrandOlive),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(size),
          Positioned.fill(child: IgnorePointer(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.black.withOpacity(0.1))))),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 40,
                  top: size.height < 600 ? 20 : 60,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            if (!_codeSent) ...[
                              _buildTextField(
                                controller: _emailController,
                                label: "EMAIL ADDRESS",
                                icon: Icons.email_outlined,
                                hint: "Enter your registered email",
                              ),
                              const SizedBox(height: 24),
                              _buildButton("SEND RESET CODE", _handleRequestCode),
                            ] else ...[
                              _buildTextField(
                                controller: _otpController,
                                label: "RESET CODE",
                                icon: Icons.lock_clock_outlined,
                                hint: "6-digit code from email",
                                maxLength: 6,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: "NEW PASSWORD",
                                icon: Icons.lock_outline,
                                hint: "Create a strong password",
                                obscureText: _isObscured,
                                suffix: IconButton(
                                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, size: 18),
                                  onPressed: () => setState(() => _isObscured = !_isObscured),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildButton("UPDATE PASSWORD", _handleReset),
                              TextButton(onPressed: () => setState(() => _codeSent = false), child: const Text("Resend code?")),
                            ],
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Back to Sign In", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.lock_reset_rounded, size: 60, color: kBrandOrange),
        const SizedBox(height: 16),
        const Text("Password Recovery", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown)),
        const SizedBox(height: 8),
        Text(
          _codeSent ? "Verify the code sent to your email and set a new password." : "Enter your email to receive instructions on resetting your password.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, bool obscureText = false, Widget? suffix, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kBrandOlive, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(text, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) => Container(
        color: kBrandBrown,
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.1,
              left: -size.width * 0.1,
              child: Container(width: size.width * 0.7, height: size.width * 0.7, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [kBrandOlive.withOpacity(0.3), Colors.transparent]))),
            ),
          ],
        ),
      ),
    );
  }
}
