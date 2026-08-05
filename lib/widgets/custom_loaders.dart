import 'dart:ui';
import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';

/// A professional, high-end loading component that can be used as a full-screen
/// overlay or as a replacement for standard progress indicators.
class BeautifulLoader extends StatelessWidget {
  final String? message;
  final bool isOverlay;

  const BeautifulLoader({
    super.key,
    this.message,
    this.isOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final loader = FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AnimatedBrandLoader(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!.toUpperCase(),
              style: TextStyle(
                color: isOverlay ? Colors.white : kBrandBrown,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ],
      ),
    );

    if (!isOverlay) return loader;

    return Stack(
      children: [
        // 1. Frosted Glass Background with Gradient
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    kBrandBrown.withValues(alpha: 0.8),
                    kBrandBrown.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 2. Subtle Animated Texture
        const Positioned.fill(child: _SubtleGridBackground()),
        // 3. The Loader
        Center(child: loader),
      ],
    );
  }
}

class _AnimatedBrandLoader extends StatefulWidget {
  const _AnimatedBrandLoader();

  @override
  State<_AnimatedBrandLoader> createState() => _AnimatedBrandLoaderState();
}

class _AnimatedBrandLoaderState extends State<_AnimatedBrandLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
            // Outer Ring - Olive
            Transform.rotate(
              angle: _controller.value * 6.28,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kBrandOlive.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: CircularProgressIndicator(
                  value: 0.3,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(kBrandOlive),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            // Middle Ring - Orange
            Transform.rotate(
              angle: -_controller.value * 6.28 * 2,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kBrandOrange.withValues(alpha: 0.1),
                    width: 3,
                  ),
                ),
                child: CircularProgressIndicator(
                  value: 0.4,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(kBrandOrange),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            // Inner Core - Logo
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 10 * _controller.value,
                    spreadRadius: 2 * _controller.value,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/age-logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SubtleGridBackground extends StatelessWidget {
  const _SubtleGridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
