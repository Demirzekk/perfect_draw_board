import 'dart:math';

import 'package:perfect_draw_board/perfect_draw_board.dart';
import 'package:flutter/material.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Painter
//
// repaint: Listenable.merge([drawingState, transform])
//   → drawingState.notifyListeners()  : pointer move sırasında tetiklenir
//   → transform value değişimi        : zoom/pan sırasında tetiklenir
//   → Her iki durumda da SADECE bu CustomPaint repaint olur.
//     Widget tree rebuild olmaz → 60fps+ çizim performansı.
//
// canvas.transform(matrix)
//   → Board koordinatlarındaki tüm çizimler otomatik olarak doğru
//     ekran pozisyonuna ve ölçeğe map edilir.
//   → Zoom in → çizimler görsel ile birlikte büyür ✅
//   → Zoom out → çizimler görsel ile birlikte küçülür ✅
//   → Pan → çizimler görsel ile birlikte kayar ✅
// ─────────────────────────────────────────────────────────────────────────────

class WorldSpacePainter extends CustomPainter {
  final DrawingState drawingState;
  final TransformationController transform;
  final int currentIndex;
  final bool applyTransform;

  WorldSpacePainter({
    required this.drawingState,
    required this.transform,
    required this.currentIndex,
    this.applyTransform = true,
  }) : super(repaint: Listenable.merge([drawingState, transform]));

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer: eraser BlendMode.clear'ın doğru çalışması için zorunlu
    canvas.saveLayer(Offset.zero & size, Paint());

    // Eğer CustomPaint, InteractiveViewer'ın DIŞINDAYSA (eski kullanım), transform uygulanmalı.
    // Eğer İÇİNDEYSE (yeni paket kullanımı), applyTransform false geçilerek bu adım atlanmalı.
    if (applyTransform) {
      canvas.transform(transform.value.storage);
    }

    final lines = drawingState.pageLines[currentIndex] ?? [];
    for (final line in lines) {
      if (line.isHighlighter) {
        _drawHighlighterLine(canvas, size, line);
      } else {
        _drawLine(canvas, line);
      }
    }

    // Lazer çizgilerini çiz (fading efekti ile)
    final now = DateTime.now();
    for (final line in drawingState.laserLines) {
      final age = now.difference(line.creationTime).inMilliseconds / 1000.0;
      final opacity = (1.0 - (age / 1.5)).clamp(0.0, 1.0);
      if (opacity > 0) {
        _drawLine(canvas, line, opacity: opacity);
      }
    }

    if (drawingState.currentLine != null) {
      if (drawingState.currentLine!.isLaser) {
        _drawLine(canvas, drawingState.currentLine!, opacity: 1.0);
      } else if (drawingState.currentLine!.isHighlighter) {
        _drawHighlighterLine(canvas, size, drawingState.currentLine!);
      } else {
        _drawLine(canvas, drawingState.currentLine!);
      }
    }

    // ── Selection indicator ──────────────────────────────────────────────────
    final selBounds = drawingState.getSelectedBounds(currentIndex);
    if (selBounds != null) {
      final selPaint = Paint()
        ..color = const Color(0xFF2196F3)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final inflated = selBounds.inflate(8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inflated, const Radius.circular(6)),
        selPaint,
      );

      // --- Delete Button (Top Right) ---
      final deletePos = inflated.topRight + const Offset(5, -5);
      final deletePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(deletePos, 12, deletePaint);

      final xPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      const xSize = 5.0;
      canvas.drawLine(
        deletePos + const Offset(-xSize, -xSize),
        deletePos + const Offset(xSize, xSize),
        xPaint,
      );
      canvas.drawLine(
        deletePos + const Offset(xSize, -xSize),
        deletePos + const Offset(-xSize, xSize),
        xPaint,
      );

      // --- Rotation Handle (Top Center) ---
      final topCenter = Offset(inflated.center.dx, inflated.top);
      final handlePos = topCenter + const Offset(0, -30);

      canvas.drawLine(topCenter, handlePos, selPaint);

      final handlePaint = Paint()
        ..color = const Color(0xFF2196F3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(handlePos, 8, handlePaint);

      // Corner handles (optional, original ones)
      const cornerSize = 8.0;
      for (final corner in [
        inflated.topLeft,
        inflated.bottomLeft,
        inflated.bottomRight,
      ]) {
        canvas.drawCircle(corner, cornerSize / 2, handlePaint);
      }
    }

    canvas.restore();
  }

  /// Highlighter: Her çizgiyi kendi saveLayer'ında çizerek,
  /// çizginin kendi üzerinden geçen kısımların renk birikmesini önler.
  /// Sonuç: Temiz, düz, yarı-saydam bir fosforlu kalem efekti.
  void _drawHighlighterLine(Canvas canvas, Size size, DrawnLine line) {
    if (line.points.isEmpty) return;

    // Highlighter'ı ayrı bir layer'da yarı-saydam çiz
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    final paint = Paint()
      ..color = line.color.withValues(alpha: 1.0) // Tam opak renk
      ..strokeWidth = line.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (line.points.length == 1) {
      canvas.drawCircle(line.points.first, line.width / 2, paint);
    } else if (line.points.length == 2) {
      canvas.drawLine(line.points[0], line.points[1], paint);
    } else {
      final path = Path()..moveTo(line.points.first.dx, line.points.first.dy);
      for (int i = 1; i < line.points.length - 1; i++) {
        final p1 = line.points[i];
        final p2 = line.points[i + 1];
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
      }
      path.lineTo(line.points.last.dx, line.points.last.dy);
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  void _drawLine(Canvas canvas, DrawnLine line, {double opacity = 1.0}) {
    if (line.points.isEmpty) return;

    Color drawColor = line.color;
    if (opacity < 1.0) {
      drawColor = drawColor.withValues(alpha: drawColor.a * opacity);
    }

    final paint = Paint()
      ..color = line.isEraser ? Colors.transparent : drawColor
      ..strokeWidth = line.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (line.isEraser) {
      paint.blendMode = BlendMode.clear;
    }

    switch (line.shape) {
      case DrawShape.line:
        if (line.points.length == 1) {
          canvas.drawCircle(
            line.points.first,
            line.width / 2,
            Paint()
              ..color = line.isEraser ? Colors.transparent : drawColor
              ..blendMode = line.isEraser ? BlendMode.clear : BlendMode.srcOver,
          );
        } else if (line.points.length == 2) {
          canvas.drawLine(line.points[0], line.points[1], paint);
        } else {
          final path = Path()
            ..moveTo(line.points.first.dx, line.points.first.dy);
          for (int i = 1; i < line.points.length - 1; i++) {
            final p1 = line.points[i];
            final p2 = line.points[i + 1];
            final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
            path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
          }
          path.lineTo(line.points.last.dx, line.points.last.dy);
          canvas.drawPath(path, paint);
        }
        break;

      case DrawShape.linearLine:
        if (line.points.length >= 2) {
          canvas.drawLine(line.points.first, line.points.last, paint);
        }
        break;

      case DrawShape.arrow:
        if (line.points.length >= 2) {
          final start = line.points.first;
          final end = line.points.last;
          canvas.drawLine(start, end, paint);
          final dX = end.dx - start.dx;
          final dY = end.dy - start.dy;
          final angle = atan2(dY, dX);
          const arrowAngle = pi / 6;
          const arrowLength = 20.0;
          final p1 = Offset(
            end.dx - arrowLength * cos(angle - arrowAngle),
            end.dy - arrowLength * sin(angle - arrowAngle),
          );
          final p2 = Offset(
            end.dx - arrowLength * cos(angle + arrowAngle),
            end.dy - arrowLength * sin(angle + arrowAngle),
          );
          canvas.drawLine(end, p1, paint);
          canvas.drawLine(end, p2, paint);
        }
        break;

      case DrawShape.dashedLine:
        if (line.points.length >= 2) {
          _drawDashedLine(canvas, line.points.first, line.points.last, paint);
        }
        break;

      case DrawShape.diamond:
        if (line.points.length >= 2) {
          _drawRotatedShape(
            canvas,
            line.points.first,
            line.points.last,
            paint,
            (c, r) => _drawPolygonAtOrigin(c, r, 4, paint),
          );
        }
        break;

      case DrawShape.rectangle:
        if (line.points.length >= 2) {
          _drawRotatedShape(
            canvas,
            line.points.first,
            line.points.last,
            paint,
            (c, r) => c.drawRect(Rect.fromLTRB(-r, -r, r, r), paint),
          );
        }
        break;

      case DrawShape.circle:
        if (line.points.length >= 2) {
          final start = line.points.first;
          final end = line.points.last;
          canvas.drawCircle(start, (end - start).distance, paint);
        }
        break;

      case DrawShape.emoji:
        if (line.points.length >= 2 && line.emoji != null) {
          _drawRotatedShape(
            canvas,
            line.points.first,
            line.points.last,
            paint,
            (c, r) {
              final emojiSize = max(r * 2.0, 10.0);

              // Draw a faint background to show the hit area
              final bgPaint = Paint()
                ..color = line.color.withValues(alpha: 0.1)
                ..style = PaintingStyle.fill;
              c.drawCircle(Offset.zero, r, bgPaint);

              final textPainter = TextPainter(
                text: TextSpan(
                  text: line.emoji,
                  style: TextStyle(
                    fontSize: emojiSize,
                    height: 1.0,
                    color: line.color,
                  ),
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
              )..layout();

              textPainter.paint(
                c,
                Offset(-textPainter.width / 2, -textPainter.height / 2),
              );
            },
          );
        }
        break;

      default: // Çokgenler
        if (line.points.length >= 2) {
          _drawRotatedShape(
            canvas,
            line.points.first,
            line.points.last,
            paint,
            (c, r) => _drawPolygonAtOrigin(c, r, _sides(line.shape), paint),
          );
        }
        break;
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 8.0;
    final distance = (p2 - p1).distance;
    if (distance < 1) return;
    final normalized = (p2 - p1) / distance;
    double currentDistance = 0;
    while (currentDistance < distance) {
      final start = p1 + normalized * currentDistance;
      currentDistance = min(currentDistance + dashWidth, distance);
      final end = p1 + normalized * currentDistance;
      canvas.drawLine(start, end, paint);
      currentDistance += dashSpace;
    }
  }

  /// Helper for 360 degree rotation.
  /// Center = start, Size/Rotation = end
  void _drawRotatedShape(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    void Function(Canvas, double radius) drawFn,
  ) {
    final distance = (end - start).distance;
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);

    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(angle);
    drawFn(canvas, distance);
    canvas.restore();
  }

  void _drawPolygonAtOrigin(
    Canvas canvas,
    double radius,
    int sides,
    Paint paint,
  ) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - (pi / 2); // Start at top
      final pt = Offset(radius * cos(angle), radius * sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  int _sides(DrawShape s) {
    switch (s) {
      case DrawShape.triangle:
        return 3;
      case DrawShape.diamond:
        return 4;
      case DrawShape.pentagon:
        return 5;
      case DrawShape.hexagon:
        return 6;
      case DrawShape.heptagon:
        return 7;
      case DrawShape.octagon:
        return 8;
      default:
        return 4;
    }
  }

  @override
  bool shouldRepaint(WorldSpacePainter old) => old.currentIndex != currentIndex;
  // Not: drawingState ve transform değişimleri zaten repaint Listenable
  // üzerinden otomatik handle edilir. Burada sadece index değişimi yeterli.
}
