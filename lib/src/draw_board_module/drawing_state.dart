import 'dart:math';
import 'package:perfect_draw_board/perfect_draw_board.dart';
import 'package:flutter/material.dart';

class DrawingState extends ChangeNotifier {
  final Map<int, List<DrawnLine>> pageLines = {};
  final Map<int, List<DrawnLine>> redoPageLines = {};
  final List<DrawnLine> laserLines = [];
  DrawnLine? currentLine;

  // ── Selection ──────────────────────────────────────────────────────────────
  int? selectedLineIndex;

  void initPages(int count) {
    for (int i = 0; i < count; i++) {
      pageLines[i] ??= [];
    }
  }

  void startLine(DrawnLine line, int pageIndex) {
    currentLine = line;
    redoPageLines[pageIndex]?.clear();
    notifyListeners();
  }

  void updateLine(Offset boardPoint, DrawShape shape) {
    final line = currentLine;
    if (line == null) return;

    if (shape != DrawShape.line) {
      currentLine = line.copyWith(points: [line.points.first, boardPoint]);
    } else {
      line.points.add(boardPoint);
    }
    notifyListeners();
  }

  void endLine(int pageIndex) {
    final line = currentLine;
    if (line == null) return;

    if (line.isLaser) {
      laserLines.add(line);
    } else {
      pageLines[pageIndex] ??= [];
      pageLines[pageIndex]!.add(line);
    }

    currentLine = null;
    notifyListeners();
  }

  void tick() {
    if (laserLines.isEmpty && currentLine?.isLaser != true) return;

    final now = DateTime.now();
    bool changed = false;

    laserLines.removeWhere((line) {
      final age = now.difference(line.creationTime).inMilliseconds / 1000.0;
      if (age > 2.0) {
        changed = true;
        return true;
      }
      return false;
    });

    if (laserLines.isNotEmpty || currentLine?.isLaser == true) {
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void cancelLine() {
    if (currentLine == null) return;
    currentLine = null;
    notifyListeners();
  }

  void undo(int pageIndex) {
    if (pageLines[pageIndex]?.isNotEmpty == true) {
      final line = pageLines[pageIndex]!.removeLast();
      redoPageLines[pageIndex] ??= [];
      redoPageLines[pageIndex]!.add(line);
      selectedLineIndex = null;
      notifyListeners();
    }
  }

  void redo(int pageIndex) {
    if (redoPageLines[pageIndex]?.isNotEmpty == true) {
      final line = redoPageLines[pageIndex]!.removeLast();
      pageLines[pageIndex] ??= [];
      pageLines[pageIndex]!.add(line);
      notifyListeners();
    }
  }

  void clear(int pageIndex) {
    pageLines[pageIndex]?.clear();
    redoPageLines[pageIndex]?.clear();
    currentLine = null;
    selectedLineIndex = null;
    notifyListeners();
  }

  // ── Selection & Move ────────────────────────────────────────────────────────

  /// Hit test: verilen board koordinatında bir çizgi var mı?
  /// Sondan başa doğru arar (en üstteki çizgi önce seçilir).
  bool selectLineAt(Offset boardPoint, int pageIndex) {
    final lines = pageLines[pageIndex];
    if (lines == null || lines.isEmpty) return false;

    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (_hitTest(line, boardPoint)) {
        selectedLineIndex = i;
        notifyListeners();
        return true;
      }
    }
    selectedLineIndex = null;
    notifyListeners();
    return false;
  }

  void deselectLine() {
    if (selectedLineIndex != null) {
      selectedLineIndex = null;
      notifyListeners();
    }
  }

  /// Seçili çizginin tüm noktalarını delta kadar kaydır
  void moveSelectedLine(Offset delta, int pageIndex) {
    if (selectedLineIndex == null) return;
    final lines = pageLines[pageIndex];
    if (lines == null || selectedLineIndex! >= lines.length) return;

    final line = lines[selectedLineIndex!];
    for (int i = 0; i < line.points.length; i++) {
      line.points[i] = line.points[i] + delta;
    }
    notifyListeners();
  }

  /// Belirli bir noktayı güncelle (döndürme/boyutlandırma için)
  void updateSelectedLinePoint(int pointIndex, Offset newPoint, int pageIndex) {
    if (selectedLineIndex == null) return;
    final lines = pageLines[pageIndex];
    if (lines == null || selectedLineIndex! >= lines.length) return;

    final line = lines[selectedLineIndex!];
    if (pointIndex < line.points.length) {
      line.points[pointIndex] = newPoint;
      notifyListeners();
    }
  }

  void deleteSelectedLine(int pageIndex) {
    if (selectedLineIndex == null) return;
    final lines = pageLines[pageIndex];
    if (lines == null || selectedLineIndex! >= lines.length) return;

    lines.removeAt(selectedLineIndex!);
    selectedLineIndex = null;
    notifyListeners();
  }

  /// Seçili çizginin bounding box'ını döndür
  Rect? getSelectedBounds(int pageIndex) {
    if (selectedLineIndex == null) return null;
    final lines = pageLines[pageIndex];
    if (lines == null || selectedLineIndex! >= lines.length) return null;
    return _getBounds(lines[selectedLineIndex!]);
  }

  bool _hitTest(DrawnLine line, Offset point) {
    if (line.points.isEmpty) return false;

    final bounds = _getBounds(line);
    final padding = max(line.width, 20.0);
    final expandedBounds = bounds.inflate(padding);
    if (!expandedBounds.contains(point)) return false;

    // Şekiller için bounding box yeterli
    if (line.shape != DrawShape.line) return true;

    // Serbest çizim: herhangi bir noktaya yakınlık kontrolü
    final threshold = max(line.width / 2 + 10, 15.0);
    for (final p in line.points) {
      if ((p - point).distance <= threshold) return true;
    }
    return false;
  }

  Rect _getBounds(DrawnLine line) {
    if (line.points.isEmpty) return Rect.zero;

    // Center-based shapes: rectangle, circle, diamond, polygons
    final bool isCenterBased = line.shape != DrawShape.line &&
        line.shape != DrawShape.linearLine &&
        line.shape != DrawShape.arrow &&
        line.shape != DrawShape.dashedLine &&
        line.shape != DrawShape.emoji;

    if (isCenterBased && line.points.length >= 2) {
      final center = line.points.first;
      final radius = (line.points.last - center).distance;
      return Rect.fromCircle(center: center, radius: radius);
    }

    // Default: encapsulate all points (for lines and old-style bounding)
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in line.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
