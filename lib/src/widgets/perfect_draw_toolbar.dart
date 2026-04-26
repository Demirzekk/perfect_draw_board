import 'package:flutter/material.dart';
import '../../perfect_draw_board.dart' show DrawShape, DrawingState;
import 'toolbar_button_widget.dart';

class PerfectDrawToolbar extends StatefulWidget {
  final DrawingState drawingState;
  final int currentIndex;
  final bool initialIsPanMode;
  final bool initialIsEraser;
  final bool initialIsHighlighter;
  final bool initialIsLaserMode;
  final bool initialIsSpotlightMode;
  final bool initialIsSelectMode;
  final Color? initialSelectedColor;
  final DrawShape initialSelectedShape;
  final double initialStrokeWidth;

  final Function(
    bool isPanMode,
    bool isEraser,
    bool isHighlighter,
    bool isLaserMode,
    bool isSpotlightMode,
    Color color,
    DrawShape shape,
    double width, {
    bool isSelect,
    String? emoji,
  })
  onStateChanged;

  const PerfectDrawToolbar({
    super.key,
    required this.drawingState,
    required this.currentIndex,
    required this.onStateChanged,
    this.initialIsPanMode = true,
    this.initialIsEraser = false,
    this.initialIsHighlighter = false,
    this.initialIsLaserMode = false,
    this.initialIsSpotlightMode = false,
    this.initialIsSelectMode = false,
    this.initialSelectedColor,
    this.initialSelectedShape = DrawShape.line,
    this.initialStrokeWidth = 3.0,
  });

  @override
  State<PerfectDrawToolbar> createState() => PerfectDrawToolbarState();
}

class PerfectDrawToolbarState extends State<PerfectDrawToolbar> {
  bool _isToolbarOpen = false;
  double _toolbarX = 16.0;
  double _toolbarY = 100.0;

  bool _isLocked = false;
  bool get isLocked => _isLocked;
  bool _isMiniMode = false;
  late bool _isPanMode;
  late bool _isEraser;
  late bool _isHighlighter;
  late bool _isLaserMode;
  late bool _isSpotlightMode;
  bool _isSelectMode = false;
  late Color _selectedColor;
  late DrawShape _selectedShape;
  String? _selectedEmoji;
  late double _strokeWidth;

  @override
  void initState() {
    super.initState();
    _isPanMode = widget.initialIsPanMode;
    _isEraser = widget.initialIsEraser;
    _isHighlighter = widget.initialIsHighlighter;
    _isLaserMode = widget.initialIsLaserMode;
    _isSpotlightMode = widget.initialIsSpotlightMode;
    _isSelectMode = widget.initialIsSelectMode;
    _selectedColor = widget.initialSelectedColor ?? Colors.blue;
    _selectedShape = widget.initialSelectedShape;
    _strokeWidth = widget.initialStrokeWidth;

    // Başlangıçta kenara yasla
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToEdge());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _snapToEdge();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PerfectDrawToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldSetState = false;

    if (widget.initialIsPanMode != oldWidget.initialIsPanMode) {
      _isPanMode = widget.initialIsPanMode;
      shouldSetState = true;
    }
    if (widget.initialIsEraser != oldWidget.initialIsEraser) {
      _isEraser = widget.initialIsEraser;
      shouldSetState = true;
    }
    if (widget.initialIsHighlighter != oldWidget.initialIsHighlighter) {
      _isHighlighter = widget.initialIsHighlighter;
      shouldSetState = true;
    }
    if (widget.initialIsLaserMode != oldWidget.initialIsLaserMode) {
      _isLaserMode = widget.initialIsLaserMode;
      shouldSetState = true;
    }
    if (widget.initialIsSelectMode != oldWidget.initialIsSelectMode) {
      _isSelectMode = widget.initialIsSelectMode;
      shouldSetState = true;
    }

    if (shouldSetState && mounted) {
      setState(() {});
    }
  }

  void _snapToEdge() {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    setState(() {
      // X-Axis clamp
      if (_toolbarX < size.width / 2) {
        _toolbarX = 8.0 + padding.left;
      } else {
        const toolbarWidth = 50.0;
        _toolbarX = size.width - toolbarWidth - 8.0 - padding.right;
      }

      // Y-Axis clamp to prevent it from going off-screen
      final minY = padding.top + 8.0;
      // Estimate max toolbar height. Unopened is 50. Opened max constraint is size.height * 0.85
      final estimatedHeight = _isToolbarOpen ? (size.height * 0.85) : 50.0;
      final maxY = size.height - padding.bottom - estimatedHeight - 8.0;

      if (_toolbarY < minY) {
        _toolbarY = minY;
      } else if (_toolbarY > maxY) {
        _toolbarY = maxY;
      }
    });
  }

  void _notifyParent() {
    widget.onStateChanged(
      _isPanMode,
      _isEraser,
      _isHighlighter,
      _isLaserMode,
      _isSpotlightMode,
      _selectedColor,
      _selectedShape,
      _strokeWidth,
      isSelect: _isSelectMode,
      emoji: _selectedEmoji,
    );
    closeToolbar();
  }

  bool get _showSecondaryTools =>
      !_isPanMode && !_isSpotlightMode && !_isLaserMode;

  @override
  Widget build(BuildContext context) {
    const toolbarWidth = 50.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: _toolbarX,
      top: _toolbarY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _toolbarX += details.delta.dx;
            _toolbarY += details.delta.dy;
          });
        },
        onPanEnd: (_) => _snapToEdge(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.hardEdge,
          width: toolbarWidth,
          height: _isToolbarOpen ? null : 50.0,
          constraints: _isToolbarOpen
              ? BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                )
              : null,
          decoration: BoxDecoration(
            color: _isToolbarOpen
                ? const Color(0xFF1C222E)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isToolbarOpen
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ana buton
              GestureDetector(
                onTap: () => setState(() => _isToolbarOpen = !_isToolbarOpen),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    border: Border.all(color: Theme.of(context).primaryColor),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isToolbarOpen
                        ? Icons.close
                        : (_isPanMode ? Icons.palette_rounded : Icons.edit),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),

              // Toolbar içeriği
              if (_isToolbarOpen)
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _buildToolbarContent(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Parent can call this to close the toolbar if user starts drawing
  void closeToolbar() {
    if (!_isLocked && _isToolbarOpen) {
      setState(() => _isToolbarOpen = false);
      _snapToEdge();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TOOLBAR CONTENT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildToolbarContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ..._buildPrimaryTools(),
          if (_showSecondaryTools && !_isMiniMode) ...[
            const SizedBox(height: 4),
            _buildColorPopup(),
            const SizedBox(height: 4),
            _buildThicknessPopup(),
          ],
          _buildDivider(),
          _buildShapeSelectButton(),
          const SizedBox(height: 4),
          _buildEmojiSelectButton(),
          ..._buildUtilityTools(),
          if (!_isMiniMode) ...[const SizedBox(height: 8)],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SHARED TOOL BUILDERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<Widget> _buildPrimaryTools() => [
    ToolbarButtonWidget(
      icon: Icons.edit,
      isActive:
          !_isPanMode &&
          !_isEraser &&
          !_isHighlighter &&
          _selectedShape == DrawShape.line &&
          !_isSelectMode,
      onTap: () => setState(() {
        _isPanMode = false;
        _isEraser = false;
        _isHighlighter = false;
        _isSelectMode = false;
        _selectedShape = DrawShape.line;
        _strokeWidth = 3.0;
        _notifyParent();
      }),
    ),
    ToolbarButtonWidget(
      icon: Icons.open_with_rounded,
      isActive: _isSelectMode,
      onTap: () => setState(() {
        _isSelectMode = !_isSelectMode;
        if (_isSelectMode) {
          _isPanMode = false;
          _isEraser = false;
          _isHighlighter = false;
          _isLaserMode = false;
          _isSpotlightMode = false;
        } else {
          _isPanMode = true;
        }
        _notifyParent();
      }),
    ),
    ToolbarButtonWidget(
      icon: Icons.pan_tool,
      isActive: _isPanMode,
      onTap: () => setState(() {
        _isPanMode = true;
        _isEraser = false;
        _isHighlighter = false;
        _isSelectMode = false;
        _isLaserMode = false;
        _isSpotlightMode = false;
        _notifyParent();
      }),
    ),
    ToolbarButtonWidget(
      icon: Icons.delete_sweep_rounded,
      isActive: !_isPanMode && _isEraser,
      onTap: () => setState(() {
        _isPanMode = false;
        _isEraser = true;
        _isHighlighter = false;
        _isSelectMode = false;
        _selectedShape = DrawShape.line;
        _strokeWidth = 20.0;
        _notifyParent();
      }),
    ),
    if (!_isMiniMode)
      ToolbarButtonWidget(
        icon: Icons.highlight,
        isActive: _isHighlighter,
        onTap: () => setState(() {
          _isHighlighter = !_isHighlighter;
          if (_isHighlighter) {
            _isPanMode = false;
            _isEraser = false;
            _isLaserMode = false;
            _isSelectMode = false;
            _selectedShape = DrawShape.line;
            _strokeWidth = 15.0;
          }
          _notifyParent();
        }),
      ),
  ];

  List<Widget> _buildUtilityTools() => [
    ToolbarButtonWidget(
      icon: Icons.undo,
      isActive: false,
      onTap: () => widget.drawingState.undo(widget.currentIndex),
    ),
    if (!_isMiniMode) ...[
      ToolbarButtonWidget(
        icon: Icons.redo,
        isActive: false,
        onTap: () => widget.drawingState.redo(widget.currentIndex),
      ),
      ToolbarButtonWidget(
        icon: Icons.clear,
        isActive: false,
        onTap: () => widget.drawingState.clear(widget.currentIndex),
      ),
      ToolbarButtonWidget(
        icon: Icons.auto_awesome_motion,
        isActive: _isLaserMode,
        onTap: () => setState(() {
          _isLaserMode = !_isLaserMode;
          _isPanMode = false;
          _isEraser = false;
          _isSpotlightMode = false;
          _isSelectMode = false;
          _notifyParent();
        }),
      ),
      ToolbarButtonWidget(
        icon: Icons.highlight_alt,
        isActive: _isSpotlightMode,
        onTap: () => setState(() {
          _isSpotlightMode = !_isSpotlightMode;
          _isPanMode = false;
          _isEraser = false;
          _isLaserMode = false;
          _isSelectMode = false;
          _notifyParent();
        }),
      ),
    ],
    _buildDivider(),
    ToolbarButtonWidget(
      icon: _isLocked ? Icons.lock : Icons.lock_open,
      isActive: _isLocked,
      onTap: () => setState(() => _isLocked = !_isLocked),
    ),
    ToolbarButtonWidget(
      icon: _isMiniMode ? Icons.fullscreen_exit : Icons.fullscreen,
      isActive: _isMiniMode,
      onTap: () => setState(() => _isMiniMode = !_isMiniMode),
    ),
  ];

  Widget _buildColorPopup() {
    final colors = [
      {'color': Colors.blue, 'name': 'Mavi'},
      {'color': Colors.red, 'name': 'Kırmızı'},
      {'color': Colors.green, 'name': 'Yeşil'},
      {'color': Colors.black, 'name': 'Siyah'},
      {'color': Colors.yellow, 'name': 'Sarı'},
      {'color': Colors.white, 'name': 'Beyaz'},
    ];

    return PopupMenuButton<Color>(
      offset: const Offset(55, 0),
      color: const Color(0xFF1C222E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      tooltip: 'Renk Seç',
      onSelected: (color) => setState(() {
        _selectedColor = color;
        _isEraser = false;
        _notifyParent();
      }),
      itemBuilder: (context) => colors.map((item) {
        final color = item['color'] as Color;
        final isSelected = _selectedColor == color;
        return PopupMenuItem<Color>(
          value: color,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item['name'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThicknessPopup() {
    return PopupMenuButton<double>(
      offset: const Offset(55, 0),
      color: const Color(0xFF1C222E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      tooltip: 'Kalınlık Ayarla',
      // We don't use onSelected because we use StatefulBuilder inside to slide in real-time
      itemBuilder: (context) => [
        PopupMenuItem<double>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setPopupState) {
              return SizedBox(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kalınlık',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Text(
                            _strokeWidth.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: Theme.of(context).primaryColor.withValues(
                            alpha: 0.2,
                          ),
                          trackHeight: 4.0,
                        ),
                        child: Slider(
                          value: _strokeWidth,
                          min: 1.0,
                          max: 50.0,
                          onChanged: (val) {
                            setPopupState(() {
                              _strokeWidth = val;
                            });
                            // Update the main state to reflect immediately
                            setState(() {});
                            _notifyParent();
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Visual indicator of exact thickness
                      Container(
                        width: _strokeWidth.clamp(2.0, 50.0),
                        height: _strokeWidth.clamp(2.0, 50.0),
                        decoration: BoxDecoration(
                          color: _isEraser ? Colors.white24 : _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.line_weight, color: Colors.white70, size: 18),
      ),
    );
  }

  Widget _buildShapeSelectButton() {
    const shapes = [
      DrawShape.linearLine,
      DrawShape.dashedLine,
      DrawShape.arrow,
      DrawShape.rectangle,
      DrawShape.circle,
      DrawShape.triangle,
      DrawShape.pentagon,
      DrawShape.hexagon,
      DrawShape.diamond,
    ];

    return PopupMenuButton<DrawShape>(
      offset: const Offset(55, 0),
      color: const Color(0xFF1C222E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      tooltip: 'Şekil Seç',
      onSelected: (shape) => setState(() {
        _selectedShape = shape;
        _isPanMode = false;
        _isEraser = false;
        _isHighlighter = false;
        _isSelectMode = false;
        _selectedEmoji = null;
        _notifyParent();
      }),
      itemBuilder: (context) => shapes.map((shape) {
        return PopupMenuItem<DrawShape>(
          value: shape,
          child: Row(
            children: [
              Icon(_getShapeIcon(shape), color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                _getShapeName(shape),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (_selectedShape != DrawShape.line && _selectedEmoji == null)
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getShapeIcon(
            _selectedShape == DrawShape.line
                ? DrawShape.rectangle
                : _selectedShape,
          ),
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEmojiSelectButton() {
    const emojis = [
      '😀',
      '😂',
      '😍',
      '🥳',
      '😎',
      '👍',
      '👏',
      '🔥',
      '🌟',
      '💡',
      '✅',
      '❌',
      '❓',
      '❗',
      '📍',
      '⭐',
      '💙',
      '🎓',
      '📚',
      '🚀',
    ];

    return PopupMenuButton<String>(
      offset: const Offset(55, 0),
      color: const Color(0xFF1C222E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      tooltip: 'Emoji Seç',
      onSelected: (emoji) => setState(() {
        _selectedEmoji = emoji;
        _selectedShape = DrawShape.emoji;
        _isPanMode = false;
        _isEraser = false;
        _isHighlighter = false;
        _isSelectMode = false;
        _notifyParent();
      }),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 180,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emojis.map((emoji) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context, emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _selectedEmoji != null
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            _selectedEmoji ?? '😀',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  String _getShapeName(DrawShape s) => switch (s) {
    DrawShape.line => 'Serbest Çizim',
    DrawShape.linearLine => 'Doğrusal Çizgi',
    DrawShape.dashedLine => 'Kesikli Çizgi',
    DrawShape.arrow => 'Ok',
    DrawShape.diamond => 'Baklava',
    DrawShape.rectangle => 'Dikdörtgen',
    DrawShape.circle => 'Çember',
    DrawShape.triangle => 'Üçgen',
    DrawShape.pentagon => 'Beşgen',
    DrawShape.hexagon => 'Altıgen',
    DrawShape.heptagon => 'Yedigen',
    DrawShape.octagon => 'Sekizgen',
    _ => '',
  };

  IconData _getShapeIcon(DrawShape s) {
    switch (s) {
      case DrawShape.line:
        return Icons.edit;
      case DrawShape.linearLine:
        return Icons.horizontal_rule;
      case DrawShape.dashedLine:
        return Icons.border_style;
      case DrawShape.arrow:
        return Icons.arrow_right_alt;
      case DrawShape.diamond:
        return Icons.interests;
      case DrawShape.rectangle:
        return Icons.check_box_outline_blank;
      case DrawShape.circle:
        return Icons.radio_button_unchecked;
      case DrawShape.triangle:
        return Icons.change_history;
      case DrawShape.pentagon:
        return Icons.pentagon_outlined;
      case DrawShape.hexagon:
        return Icons.hexagon_outlined;
      default:
        return Icons.interests_outlined;
    }
  }

  Widget _buildDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8.0),
    child: Divider(color: Colors.white24, indent: 12, endIndent: 12),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SMALL WIDGETS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
}
