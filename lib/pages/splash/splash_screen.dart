import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../academics/academics_utils.dart';
import '../../services/api_service.dart';
import '../../services/permission_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    _initialize();
  }

  Future<void> _initialize() async {
    await ApiService.init();

    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      if (ApiService.isAuthenticated) {
        // Try to fetch profile to see if token is still valid
        try {
          final response = await ApiService.getAccountProfile();
          if (response.statusCode == 200 && mounted) {
            final userData = response.data['data'];

            // Initialize Permissions
            PermissionService.init(userData);

            final String role = userData['role_name'] ?? userData['role'] ?? 'Staff';
            final String normalizedRole = role.trim().toLowerCase();

            String targetRoute = '/home';
            // 1. Strict Administrator -> Admin Portal
            if (normalizedRole == 'administrator') {
              targetRoute = '/admin/home';
            }
            // 2. Field Operations Group -> Field Operations Portal
            else if ([
              'field officer',
              'field coordinator',
              'field operations',
              'operational officer'
            ].contains(normalizedRole)) {
              targetRoute = '/field-operations/home';
            }
            // 3. All other roles (Country Director, Program Coordinator, etc.) -> General Dashboard (/home)

            Navigator.pushReplacementNamed(
              context,
              targetRoute,
              arguments: {
                'username': userData['full_name'] ?? 'User',
                'role': role,
                'profilePicture': userData['profile_picture'],
              },
            );
            return;
          }
        } catch (e) {
          // Token probably expired
          ApiService.logout();
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandBrown,
      body: Stack(
        children: [
          // 1. New Professional Background Pattern
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBrandBrown, Color(0xFF2C241D)],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _AnimatedRadialBackground()),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // High-end Branding
                  Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/age-logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school_rounded,
                        size: 80,
                        color: kBrandOlive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  const Text(
                    "AGE AFRICA",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "AGE AFRICA SYSTEM",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kBrandOlive,
                      letterSpacing: 4,
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Loader
                  const CircularProgressIndicator(color: kBrandOlive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedRadialBackground extends StatefulWidget {
  const _AnimatedRadialBackground();

  @override
  State<_AnimatedRadialBackground> createState() => _AnimatedRadialBackgroundState();
}

class _AnimatedRadialBackgroundState extends State<_AnimatedRadialBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
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
        return CustomPaint(
          painter: _RadialPainter(_controller.value),
        );
      },
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double progress;
  _RadialPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          kBrandOlive.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
        size.width * 0.2 + (size.width * 0.6 * progress),
        size.height * 0.2 + (size.height * 0.6 * (1 - progress)),
        size.width,
        size.height,
      ));

    canvas.drawCircle(
      Offset(
        size.width * 0.5 + (math.cos(progress * 2 * math.pi) * 100),
        size.height * 0.5 + (math.sin(progress * 2 * math.pi) * 100),
      ),
      size.width * 0.8,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
