import 'package:flutter/material.dart';

class WavesBackground extends StatelessWidget {
  const WavesBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF21527D), Color(0xFF1C9FE2)],
        ),
      ),
      child: CustomPaint(painter: _WavesPainter()),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ola 1 (oscura)
    final p1 = Path()
      ..lineTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.50,
        size.width * 0.5,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.66,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, 0)
      ..close();

    final paint1 = Paint()
      ..color = const Color(0xFF21527D).withValues(alpha: 0.25);
    canvas.drawPath(p1, paint1);

    // Ola 2 (intermedia)
    final p2 = Path()
      ..lineTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.63,
        size.width * 0.5,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.77,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, 0)
      ..close();

    final paint2 = Paint()
      ..color = const Color(0xFF1C9FE2).withValues(alpha: 0.22);
    canvas.drawPath(p2, paint2);

    // Ola 3 (clara)
    final p3 = Path()
      ..lineTo(0, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.80,
        size.width * 0.5,
        size.height * 0.86,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.92,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, 0)
      ..close();

    final paint3 = Paint()
      ..color = const Color(0xFF74D3E1).withValues(alpha: 0.22);
    canvas.drawPath(p3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
