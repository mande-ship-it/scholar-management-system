import 'package:flutter/material.dart';
import '../../schools/register_school.dart';
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';

class RegisterSchoolPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBack;
  const RegisterSchoolPage({super.key, this.onSuccess, this.onBack});

  @override
  State<RegisterSchoolPage> createState() => _RegisterSchoolPageState();
}

class _RegisterSchoolPageState extends State<RegisterSchoolPage> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _isAdmin = (data['role_name'] == 'Administrator');
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: kBrandOlive),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_person_rounded,
                        size: 48,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "ACCESS RESTRICTED",
                      style: TextStyle(
                        color: kBrandBrown,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "This administrative component is restricted to System Administrators only. You do not have permission to register new schools.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onBack ?? () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Return to Dashboard",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RegisterSchoolComponent(
      onBack: widget.onBack,
      onRegister: widget.onSuccess != null ? (_) => widget.onSuccess!() : null
    );
  }
}
