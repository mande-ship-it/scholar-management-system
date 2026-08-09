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
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, 
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut)
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
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleRequestCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError("Please enter a valid email address.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.forgotPassword(_emailController.text.trim());
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Reset code sent to your email"), 
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showError(response.data['message'] ?? "Failed to send reset code.");
      }
    } catch (e) {
      _showError("Connection error. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiService.resetPassword(
          _emailController.text.trim(),
          _otpController.text.trim(),
          _passwordController.text,
        );
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Password reset successful! Please log in."), 
                backgroundColor: kBrandOlive,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          _showError(response.data['message'] ?? "Invalid reset code or request.");
        }
      } catch (e) {
        _showError("Unable to complete request.");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: Navigator.canPop(context) 
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBrandBrown, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
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
              child: _buildRecoveryForm(isSmallScreen),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoHeader(isSmallScreen),
          const SizedBox(height: 32),
          
          if (!_codeSent) ...[
            _buildLabel("EMAIL ADDRESS"),
            TextFormField(
              controller: _emailController,
              decoration: _inputDeco(Icons.email_outlined, "Enter your registered email"),
              validator: (v) => (v == null || !v.contains('@')) ? "Valid email required" : null,
            ),
            const SizedBox(height: 24),
            _buildMainButton("SEND RESET CODE", _handleRequestCode),
          ] else ...[
            _buildLabel("RESET CODE"),
            TextFormField(
              controller: _otpController,
              maxLength: 6,
              style: const TextStyle(letterSpacing: 8, fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: _inputDeco(Icons.lock_clock_outlined, "••••••").copyWith(counterText: ""),
              validator: (v) => (v == null || v.length < 4) ? "Code required" : null,
            ),
            const SizedBox(height: 20),
            _buildLabel("NEW SECURITY KEY"),
            TextFormField(
              controller: _passwordController,
              obscureText: _isObscured,
              decoration: _inputDeco(
                Icons.lock_outline_rounded, 
                "New Password",
                suffix: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? "Too short" : null,
            ),
            const SizedBox(height: 24),
            _buildMainButton("UPDATE PASSWORD", _handleReset),
            TextButton(
              onPressed: () => setState(() => _codeSent = false), 
              child: const Text("Resend code?", style: TextStyle(color: kBrandOlive, fontWeight: FontWeight.bold))
            ),
          ],
          
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back to Sign In", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(bool isSmallScreen) {
    return Center(
      child: Column(
        children: [
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
          const SizedBox(height: 24),
          Text(
            "PASSWORD RECOVERY",
            style: TextStyle(
              color: kBrandOlive,
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _codeSent ? "Verify Access" : "Account Access",
            style: TextStyle(
              color: kBrandBrown,
              fontSize: isSmallScreen ? 22 : 26,
              fontWeight: FontWeight.w900,
            ),
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

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(text, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }
}
