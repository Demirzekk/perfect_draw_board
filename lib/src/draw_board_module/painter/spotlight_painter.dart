import 'package:flutter/material.dart';

class SpotlightPainter extends CustomPainter {
  final Offset position;

  SpotlightPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Hole logic
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);
    canvas.drawCircle(
      position,
      120.0, // Radius of the spotlight
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SpotlightPainter old) => old.position != position;
}
