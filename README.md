# Perfect Draw Board

A comprehensive and reusable drawing board package for Flutter. It provides a complete solution for interactive drawing, zooming, panning, and content centering, all bundled into a single easy-to-use widget.

## Features ✨

*   **🚀 Ready-to-use:** Drop in the `PerfectDrawBoard` widget and you're good to go.
*   **🛠️ Built-in Toolbar:** Includes a full-featured toolbar:
    *   **Pen & Highlighter:** Smooth drawing with various styles.
    *   **Laser Pointer:** Auto-fading lines for presentations or highlighting.
    *   **Shapes:** Easy-to-draw rectangles, circles, and arrows.
    *   **Eraser:** Precise clearing of drawings.
    *   **Color & Thickness:** Fully customizable strokes.
    *   **Undo/Clear:** Quick actions for drawing management.
*   **🔍 Advanced Navigation:** Built-in Zoom and Pan using `InteractiveViewer`.
*   **🎯 Smart Centering:** Automatically centers and scales your background content (e.g., images) to fit the screen.
*   **📄 Multi-page State:** Effortlessly manage drawing states across different pages/documents.
*   **⚡ Performance Optimized:** Uses `RepaintBoundary` and optimized `CustomPainter` for smooth 60fps+ drawing experience.

## Installation 📦

Add the local package to your project's `pubspec.yaml`:

```yaml
dependencies:
  perfect_draw_board:
    path: packages/perfect_draw_board
```

## Quick Start 🚀

```dart
import 'package:perfect_draw_board/perfect_draw_board.dart';

// In your build method:
PerfectDrawBoard(
  background: Image.network('https://path-to-your-image.jpg'),
  initialImageSize: const Size(800, 1200), // Used for perfect centering
  showToolbar: true,
)
```

## Customization 🎨

### PerfectDrawBoard Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `background` | `Widget?` | `null` | The image or content to draw over. |
| `drawingState`| `DrawingState?` | `null` | Optional external state management. |
| `pageIndex` | `int` | `0` | Index for multi-page environments. |
| `showToolbar` | `bool` | `true` | Toggle the built-in toolbar visibility. |
| `boardSize` | `double` | `4000.0` | Total virtual canvas size. |
| `initialImageSize` | `Size?` | `null` | Background size for initial fit-to-screen. |

## Credits 💎

Built with ❤️ for advanced agentic coding.
Uses `perfect_freehand` for smooth ink strokes and `flutter_colorpicker` for tool selection.
