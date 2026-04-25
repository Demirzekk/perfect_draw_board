import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../perfect_draw_board.dart';

class PerfectDrawBoard extends StatefulWidget {
  final Widget? background;
  final DrawingState? drawingState;
  final int pageIndex;
  final bool showToolbar;
  final double boardSize;
  final Size? initialImageSize;

  const PerfectDrawBoard({
    super.key,
    this.background,
    this.drawingState,
    this.pageIndex = 0,
    this.showToolbar = true,
    this.boardSize = 4000.0,
    this.initialImageSize,
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
            minScale: 0.1,
            maxScale: 10.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            clipBehavior: Clip.none,
            child: SizedBox(
              width: widget.boardSize,
              height: widget.boardSize,
              child: Stack(
                children: [
                  if (widget.background != null)
                    Positioned(
                      left: imageOrigin.dx,
                      top: imageOrigin.dy,
                      width: imageSize.width,
                      height: imageSize.height,
                      child: widget.background!,
                    ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: WorldSpacePainter(
                          drawingState: _drawingState,
                          transform: _transformationController,
                          currentIndex: widget.pageIndex,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showToolbar)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Center(
              child: PerfectDrawToolbar(
                isPanMode: _isPanMode,
                onTogglePanMode: () => setState(() => _isPanMode = !_isPanMode),
                selectedShape: _selectedShape,
                onShapeChanged: (val) => setState(() => _selectedShape = val),
                selectedColor: _selectedColor,
                onColorChanged: (val) => setState(() => _selectedColor = val),
                strokeWidth: _strokeWidth,
                onStrokeWidthChanged: (val) =>
                    setState(() => _strokeWidth = val),
                isHighlighter: _isHighlighter,
                onHighlighterChanged: (val) =>
                    setState(() => _isHighlighter = val),
                isEraser: _isEraser,
                onEraserChanged: (val) => setState(() => _isEraser = val),
                isLaser: _isLaser,
                onLaserChanged: (val) => setState(() => _isLaser = val),
                onUndo: () => _drawingState.undo(widget.pageIndex),
                onClear: () => _drawingState.clear(widget.pageIndex),
              ),
            ),
          ),
      ],
    );
  }
}
