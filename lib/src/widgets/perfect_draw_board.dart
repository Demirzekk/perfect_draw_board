import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  });

  @override
  State<PerfectDrawBoard> createState() => _PerfectDrawBoardState();
}

class _PerfectDrawBoardState extends State<PerfectDrawBoard>
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

  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _drawingState = widget.drawingState ?? DrawingState();
    _ticker = createTicker((_) => _drawingState.tick())..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerView();
      }
    });
  }

  void _centerView() {
    final size = MediaQuery.of(context).size;
    final imageSize = widget.initialImageSize ?? const Size(800, 1200);

    // Initial scale that fits width-wise with some padding
    final double initialScale = (size.width / imageSize.width) * 0.85;
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

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
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
      ),
      widget.pageIndex,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isPanMode || _activePointers != 1) return;
    if (_drawingState.currentLine == null) return;

    _drawingState.updateLine(
      _screenToBoard(event.localPosition),
      _selectedShape,
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
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
    return Stack(
      children: [
        if (widget.background != null)
          Positioned.fill(
            child: widget.background!,
          ),
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
                  if (widget.child != null)
                    Positioned.fill(
                      child: widget.child!,
                    ),
                  Positioned.fill(
                    child: RepaintBoundary(
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
                if (!isSelect) _drawingState.deselectLine();
              });
            },
          ),
      ],
    );
  }
}
