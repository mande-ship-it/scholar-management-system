import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../academics/academics_utils.dart';

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

    Timer(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
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
          // Moving background lines
          const Positioned.fill(child: _MovingLinesBackground()),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // High-end Branding
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/age-logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school_rounded,
                        size: 70,
                        color: kBrandOlive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    "AGE AFRICA",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    "SCHOLAR MANAGEMENT SYSTEM",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kBrandOlive.withOpacity(0.9),
                      letterSpacing: 4,
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                  
                  // Professional Loader
                  const _MultiColorLoader(),
                  
                  const SizedBox(height: 40),
                  Text(
                    "INITIALIZING SECURE PORTAL",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 2,
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
}

class _MovingLinesBackground extends StatefulWidget {
  const _MovingLinesBackground();

  @override
  State<_MovingLinesBackground> createState() => _MovingLinesBackgroundState();
}

class _MovingLinesBackgroundState extends State<_MovingLinesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
          painter: _LinePainter(_controller.value),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  final double progress;
  _LinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final opacity = (random.nextDouble() * 0.15).clamp(0.05, 0.15);
      paint.color = kBrandOlive.withOpacity(opacity);
      paint.strokeWidth = random.nextDouble() * 100 + 50;

      final path = Path();
      final startY = random.nextDouble() * size.height;
      final offset = progress * size.width;
      
      path.moveTo(-size.width, startY);
      path.quadraticBezierTo(
        size.width * 0.5, 
        startY + (math.sin(progress * math.pi * 2 + i) * 200), 
        size.width * 2, 
        startY + 100
      );

      canvas.save();
      canvas.translate((offset + (i * 100)) % (size.width * 3) - size.width, 0);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MultiColorLoader extends StatefulWidget {
  const _MultiColorLoader();

  @override
  State<_MultiColorLoader> createState() => _MultiColorLoaderState();
}

class _MultiColorLoaderState extends State<_MultiColorLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
        return Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  value: 0.3,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(kBrandOlive),
                ),
              ),
            ),
            RotationTransition(
              turns: ReverseAnimation(_controller),
              child: const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  value: 0.3,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(kBrandOrange),
                ),
              ),
            ),
            RotationTransition(
              turns: _controller.drive(CurveTween(curve: Curves.easeInOut)),
              child: const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  value: 0.3,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(kBrandCream),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
