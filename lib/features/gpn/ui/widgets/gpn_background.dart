import 'package:flutter/material.dart';

/// Фон как в CleanApp.jsx — сетка и фиолетовое свечение.
class GpnBackground extends StatelessWidget {
  const GpnBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0015),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                      blurRadius: 120,
                    ),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 40.0;
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
