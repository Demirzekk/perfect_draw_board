import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import '../../perfect_draw_board.dart';

class PerfectDrawBoard extends StatefulWidget {
  final Widget? background;
  final Widget? child;
  final DrawingState? drawingState;
  final int pageIndex;
  final bool showToolbar;
  final double boardSize;
  final Size? initialImageSize;
  final DrawingModuleType drawingModuleType;
  final bool isSpotlightMode;
  final Offset spotlightPosition;
  final Function(bool isPanMode, bool isSelectMode)? onModeChanged;

  const PerfectDrawBoard({
    super.key,
    this.background,
    this.child,
    this.drawingState,
    this.pageIndex = 0,
    this.showToolbar = true,
    this.boardSize = 4000.0,
    this.initialImageSize,
    this.drawingModuleType = DrawingModuleType.drawBoard,
    this.isSpotlightMode = false,
    this.spotlightPosition = Offset.zero,
    this.onModeChanged,
  });

  @override
  State<PerfectDrawBoard> createState() => PerfectDrawBoardState();
}

class PerfectDrawBoardState extends State<PerfectDrawBoard>
    with SingleTickerProviderStateMixin {
  late final DrawingState _drawingState;
  late final TransformationController _transformationController;
  late final Ticker _ticker;

  bool _isPanMode = true;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  DrawShape _selectedShape = DrawShape.line;
  bool _isHighlighter = false;
  bool _isEraser = false;
  bool _isLaser = false;
  bool _isSelectMode = false;
  String? _selectedEmoji;

  Offset? _lastSelectDragPoint;
  bool _isRotatingSelect = false;

  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _drawingState = widget.drawingState ?? DrawingState();
    _ticker = createTicker((_) => _drawingState.tick())..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        centerView();
      }
    });
  }

  void centerView() {
    final size = MediaQuery.of(context).size;
    final imageSize = widget.initialImageSize ?? const Size(800, 1200);

    // Initial scale that fits both width and height with some padding
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    final double initialScale = math.min(scaleX, scaleY) * 0.95;

    final double centerX = widget.boardSize / 2;
    final double centerY = widget.boardSize / 2;

    final double tx = -(centerX * initialScale - size.width / 2);
    final double ty = -(centerY * initialScale - size.height / 2);

    setState(() {
      _transformationController.value =
          Matrix4.diagonal3Values(initialScale, initialScale, 1.0)
            ..setTranslationRaw(tx, ty, 0.0);
    });
  }

  @override
  void didUpdateWidget(covariant PerfectDrawBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) centerView();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (widget.drawingState == null) {
      _drawingState.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }

  Offset _screenToBoard(Offset screenPoint) {
    return MatrixUtils.transformPoint(
      Matrix4.inverted(_transformationController.value),
      screenPoint,
    );
  }

  void setPanMode() {
    setState(() {
      _isPanMode = true;
      _isEraser = false;
      _isHighlighter = false;
      _isSelectMode = false;
      _isLaser = false;
      widget.onModeChanged?.call(_isPanMode, _isSelectMode);
    });
  }

  void setSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (_isSelectMode) {
        _isPanMode = false;
        _isEraser = false;
        _isHighlighter = false;
        _isLaser = false;
      } else {
        _isPanMode = true;
      }
      widget.onModeChanged?.call(_isPanMode, _isSelectMode);
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;

    // ── Select Mode ──
    if (_isSelectMode) {
      final boardPt = _screenToBoard(event.localPosition);
      final bounds = _drawingState.getSelectedBounds(widget.pageIndex);

      if (bounds != null) {
        final inflated = bounds.inflate(8);

        // --- Delete Check ---
        final deletePos = inflated.topRight + const Offset(5, -5);
        if ((boardPt - deletePos).distance <= 20) {
          _drawingState.deleteSelectedLine(widget.pageIndex);
          return;
        }

        // --- Rotation Handle Check ---
        final topCenter = Offset(inflated.center.dx, inflated.top);
        final handlePos = topCenter + const Offset(0, -30);
        if ((boardPt - handlePos).distance <= 15) {
          _isRotatingSelect = true;
          return;
        }
      }

      _drawingState.selectLineAt(boardPt, widget.pageIndex);
      _lastSelectDragPoint = boardPt;
      return;
    }

    if (_isPanMode) return;

    final boardPt = _screenToBoard(event.localPosition);

    _drawingState.startLine(
      DrawnLine(
        points: [boardPt],
        color: _isEraser
            ? Colors.transparent
            : (_isHighlighter
                ? _selectedColor.withValues(alpha: 0.4)
                : _selectedColor),
        width: _strokeWidth,
        shape: _selectedShape,
        isEraser: _isEraser,
        isHighlighter: _isHighlighter,
        isLaser: _isLaser,
        emoji: _selectedEmoji,
      ),
      widget.pageIndex,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    // ── Select Mode: Sürükleme ──
    if (_isSelectMode && _drawingState.selectedLineIndex != null) {
      final boardPt = _screenToBoard(event.localPosition);

      if (_isRotatingSelect) {
        _drawingState.updateSelectedLinePoint(1, boardPt, widget.pageIndex);
        return;
      }

      if (_lastSelectDragPoint != null) {
        final delta = boardPt - _lastSelectDragPoint!;
        _drawingState.moveSelectedLine(delta, widget.pageIndex);
      }
      _lastSelectDragPoint = boardPt;
      return;
    }

    if (_isPanMode || _activePointers != 1) return;
    if (_drawingState.currentLine == null) return;

    _drawingState.updateLine(
      _screenToBoard(event.localPosition),
      _selectedShape,
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    _isRotatingSelect = false;
    _activePointers = (_activePointers - 1).clamp(0, 10);

    if (_isSelectMode) {
      _lastSelectDragPoint = null;
      return;
    }

    if (!_isPanMode && _activePointers == 0) {
      _drawingState.endLine(widget.pageIndex);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    _drawingState.cancelLine();
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = widget.initialImageSize ?? const Size(800, 1200);
    final imageOrigin = Offset(
      (widget.boardSize - imageSize.width) / 2,
      (widget.boardSize - imageSize.height) / 2,
    );

    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: _isPanMode,
            scaleEnabled: true,
            constrained: false,
            minScale: 0.05,
            maxScale: 10.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            clipBehavior: Clip.none,
            child: SizedBox(
              width: widget.boardSize,
              height: widget.boardSize,
              child: Stack(
                children: [
                  if (widget.background != null)
                    Positioned.fill(child: widget.background!),
                  if (widget.child != null)
                    Positioned(
                      left: imageOrigin.dx,
                      top: imageOrigin.dy,
                      width: imageSize.width,
                      height: imageSize.height,
                      child: widget.child!,
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: widget.drawingModuleType == DrawingModuleType.drawBoard
                          ? WorldSpacePainter(
                              drawingState: _drawingState,
                              transform: _transformationController,
                              currentIndex: widget.pageIndex,
                              applyTransform: false,
                            )
                          : PerfectFreehandPainter(
                              drawingState: _drawingState,
                              transform: _transformationController,
                              currentIndex: widget.pageIndex,
                              applyTransform: false,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isSpotlightMode)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: SpotlightPainter(
                  position: widget.spotlightPosition,
                ),
              ),
            ),
          ),
        if (widget.showToolbar)
          PerfectDrawToolbar(
            drawingState: _drawingState,
            currentIndex: widget.pageIndex,
            initialIsPanMode: _isPanMode,
            initialIsEraser: _isEraser,
            initialIsHighlighter: _isHighlighter,
            initialIsLaserMode: _isLaser,
            initialIsSpotlightMode: widget.isSpotlightMode,
            initialIsSelectMode: _isSelectMode,
            initialSelectedColor: _selectedColor,
            initialSelectedShape: _selectedShape,
            initialStrokeWidth: _strokeWidth,
            onStateChanged: (
              isPan,
              isEra,
              isHigh,
              isLaser,
              isSpot,
              color,
              shape,
              width, {
              bool isSelect = false,
              String? emoji,
            }) {
              setState(() {
                _isPanMode = isPan;
                _isEraser = isEra;
                _isHighlighter = isHigh;
                _isLaser = isLaser;
                _selectedColor = color;
                _selectedShape = shape;
                _strokeWidth = width;
                _selectedEmoji = emoji;
                _isSelectMode = isSelect;
                if (!isSelect) _drawingState.deselectLine();
                widget.onModeChanged?.call(_isPanMode, _isSelectMode);
              });
            },
          ),
      ],
    );
  }
}
