import 'package:flutter/material.dart';
import '../../perfect_draw_board.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PerfectDrawToolbar extends StatelessWidget {
  final bool isPanMode;
  final VoidCallback onTogglePanMode;
  final DrawShape selectedShape;
  final ValueChanged<DrawShape> onShapeChanged;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final double strokeWidth;
  final ValueChanged<double> onStrokeWidthChanged;
  final bool isHighlighter;
  final ValueChanged<bool> onHighlighterChanged;
  final bool isEraser;
  final ValueChanged<bool> onEraserChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool isLaser;
  final ValueChanged<bool> onLaserChanged;

  const PerfectDrawToolbar({
    super.key,
    required this.isPanMode,
    required this.onTogglePanMode,
    required this.selectedShape,
    required this.onShapeChanged,
    required this.selectedColor,
    required this.onColorChanged,
    required this.strokeWidth,
    required this.onStrokeWidthChanged,
    required this.isHighlighter,
    required this.onHighlighterChanged,
    required this.isEraser,
    required this.onEraserChanged,
    required this.onUndo,
    required this.onClear,
    required this.isLaser,
    required this.onLaserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(
              context,
              icon: isPanMode ? Icons.pan_tool : Icons.edit,
              tooltip: isPanMode ? 'Pan Modu' : 'Çizim Modu',
              isSelected: !isPanMode,
              onPressed: onTogglePanMode,
            ),
            const VerticalDivider(width: 16),
            if (!isPanMode) ...[
              _buildIconButton(
                context,
                icon: Icons.brush,
                tooltip: 'Kalem',
                isSelected: !isEraser &&
                    !isHighlighter &&
                    !isLaser &&
                    selectedShape == DrawShape.line,
                onPressed: () {
                  onEraserChanged(false);
                  onHighlighterChanged(false);
                  onLaserChanged(false);
                  onShapeChanged(DrawShape.line);
                },
              ),
              _buildIconButton(
                context,
                icon: Icons.border_color,
                tooltip: 'Vurgulayıcı',
                isSelected: isHighlighter && !isEraser,
                onPressed: () {
                  onEraserChanged(false);
                  onHighlighterChanged(true);
                  onLaserChanged(false);
                  onShapeChanged(DrawShape.line);
                },
              ),
              _buildIconButton(
                context,
                icon: Icons.auto_fix_high,
                tooltip: 'Lazer',
                isSelected: isLaser,
                onPressed: () {
                  onEraserChanged(false);
                  onHighlighterChanged(false);
                  onLaserChanged(true);
                  onShapeChanged(DrawShape.line);
                },
              ),
              _buildIconButton(
                context,
                icon: Icons.rectangle_outlined,
                tooltip: 'Dikdörtgen',
                isSelected: !isEraser && selectedShape == DrawShape.rectangle,
                onPressed: () {
                  onEraserChanged(false);
                  onShapeChanged(DrawShape.rectangle);
                },
              ),
              _buildIconButton(
                context,
                icon: Icons.circle_outlined,
                tooltip: 'Daire',
                isSelected: !isEraser && selectedShape == DrawShape.circle,
                onPressed: () {
                  onEraserChanged(false);
                  onShapeChanged(DrawShape.circle);
                },
              ),
              _buildIconButton(
                context,
                icon: Icons.arrow_right_alt,
                tooltip: 'Ok',
                isSelected: !isEraser && selectedShape == DrawShape.arrow,
                onPressed: () {
                  onEraserChanged(false);
                  onShapeChanged(DrawShape.arrow);
                },
              ),
              _buildIconButton(
                context,
                icon: Icons.cleaning_services,
                tooltip: 'Silgi',
                isSelected: isEraser,
                onPressed: () => onEraserChanged(true),
              ),
              const VerticalDivider(width: 16),
              // Color Picker trigger
              InkWell(
                onTap: () => _showColorPicker(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Thickness trigger
              IconButton(
                icon: const Icon(Icons.line_weight),
                onPressed: () => _showThicknessPicker(context),
              ),
              const VerticalDivider(width: 16),
              _buildIconButton(
                context,
                icon: Icons.undo,
                tooltip: 'Geri Al',
                isSelected: false,
                onPressed: onUndo,
              ),
              _buildIconButton(
                context,
                icon: Icons.delete_outline,
                tooltip: 'Hepsini Sil',
                isSelected: false,
                onPressed: () => _confirmClear(context),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      tooltip: tooltip,
      onPressed: onPressed,
      style: isSelected
          ? IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1))
          : null,
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renk Seç'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selectedColor,
            onColorChanged: (c) {
              onColorChanged(c);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  void _showThicknessPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kalınlık'),
          content: Slider(
            value: strokeWidth,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            label: strokeWidth.round().toString(),
            onChanged: (val) {
              setState(() => onStrokeWidthChanged(val));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat'),
            )
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tümünü Sil'),
        content: const Text(
            'Bu sayfadaki tüm çizimler silinecek. Onaylıyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              onClear();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
