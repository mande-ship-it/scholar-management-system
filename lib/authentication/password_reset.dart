import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordObscured = true;

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
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiService.changeFirstPassword(_passwordController.text);
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Security update successful! Please sign in."),
                backgroundColor: kBrandOlive,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          _showError(response.data['message'] ?? "Password update failed.");
        }
      } catch (e) {
        _showError("Connection error. Please try again.");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
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
              constraints: const BoxConstraints(maxWidth: 480),
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
              child: _buildResetForm(isSmallScreen),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoHeader(isSmallScreen),
          const SizedBox(height: 32),

          _buildInputLabel("NEW SECURITY KEY"),
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kBrandBrown),
            decoration: _fieldDecoration(Icons.lock_outline_rounded, hint: "••••••••"),
            validator: (value) => (value == null || value.length < 6) ? "Minimum 6 characters required" : null,
          ),
          const SizedBox(height: 20),

          _buildInputLabel("CONFIRM SECURITY KEY"),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isPasswordObscured,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kBrandBrown),
            decoration: _fieldDecoration(Icons.lock_reset_rounded, hint: "••••••••"),
            validator: (value) => (value != _passwordController.text) ? "Passwords do not match" : null,
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                : const Text("ACTIVATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text(
              "Cancel & Return to Login",
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
            ),
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
              errorBuilder: (ctx, _, __) => const Icon(Icons.shield_rounded, size: 40, color: kBrandOlive),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "SECURITY UPDATE",
            style: TextStyle(
              color: kBrandOlive,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Set Your Password",
            style: TextStyle(
              color: kBrandBrown,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
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
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(IconData icon, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: kBrandOlive, size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBrandOlive, width: 2),
      ),
    );
  }
}
