import 'package:perfect_draw_board/perfect_draw_board.dart';
import 'package:flutter/material.dart';

class DrawnLine {
  // points is intentionally mutable for performance (no copy on every move)
  final List<Offset> points;
  final Color color;
  final double width;
  final DrawShape shape;
  final String? emoji;
  final bool isEraser;
  final bool isLaser;
  final bool isHighlighter;
  final DateTime creationTime;

  DrawnLine({
    required this.points,
    required this.color,
    required this.width,
    this.shape = DrawShape.line,
    this.emoji,
    this.isEraser = false,
    this.isLaser = false,
    this.isHighlighter = false,
    DateTime? creationTime,
  }) : creationTime = creationTime ?? DateTime.now();

  DrawnLine copyWith({List<Offset>? points}) => DrawnLine(
    points: points ?? List.of(this.points),
    color: color,
    width: width,
    shape: shape,
    emoji: emoji,
    isEraser: isEraser,
    isLaser: isLaser,
    isHighlighter: isHighlighter,
    creationTime: creationTime,
  );
}
