# Perfect Draw Board

A comprehensive, reusable, and standalone drawing board package for Flutter. It provides a complete solution for interactive drawing, zooming, panning, and a floating toolbar, all bundled into a single easy-to-use widget.

## Features ✨

*   **🚀 Ready-to-use:** Drop in the `PerfectDrawBoard` widget anywhere in your app and you instantly get a full-fledged drawing area.
*   **🛠️ Floating Draggable Toolbar:** Includes a beautiful, movable, full-featured toolbar:
    *   **Pen & Highlighter:** Smooth drawing with various styles.
    *   **Laser Pointer:** Auto-fading lines for presentations or highlighting.
    *   **Shapes:** Easy-to-draw rectangles, circles, triangles, arrows, and more.
    *   **Emojis:** Stamp emojis anywhere on the board!
    *   **Eraser:** Precise clearing of drawings.
    *   **Color & Thickness:** Fully customizable strokes via popups.
    *   **Undo/Clear:** Quick actions for drawing management.
    *   **Spotlight Mode:** Focus the user's attention on a specific area.
*   **🔍 Advanced Navigation:** Built-in Zoom and Pan using `InteractiveViewer`.
*   **🎯 Smart Layering:** Separate `background` (fixed) and `child` (zoomable) parameters.
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
  // Optional: Fixed background that stays still while zooming
  background: Image.asset('assets/paper_texture.jpg', fit: BoxFit.cover),
  
  // Optional: Zoomable content (like a question image, PDF page, or text)
  child: Center(
    child: Text("Soru Çözüm Alanı! Yakınlaştır ve Çiz."),
  ),

  initialImageSize: const Size(800, 1200), // Used for perfect initial zoom fit
  showToolbar: true, // Shows the floating Draggable Toolbar
)
```

## Customization 🎨

### PerfectDrawBoard Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `background` | `Widget?` | `null` | Static background fixed behind the zoomable canvas. |
| `child` | `Widget?` | `null` | Zoomable/pannable content (like an image or text). |
| `drawingState`| `DrawingState?` | `null` | Optional external state management for history. |
| `pageIndex` | `int` | `0` | Index for multi-page environments. |
| `showToolbar` | `bool` | `true` | Toggle the built-in floating toolbar visibility. |
| `boardSize` | `double` | `4000.0` | Total virtual canvas size. |
| `initialImageSize` | `Size?` | `null` | Background size for initial fit-to-screen. |
| `drawingModuleType` | `DrawingModuleType` | `.drawBoard` | Select between `drawBoard` or `perfectFreehand`. |
| `isSpotlightMode` | `bool` | `false` | Enable/disable spotlight effect. |
| `spotlightPosition` | `Offset` | `Offset.zero` | Current focal point for spotlight mode. |

## Credits 💎

Built with ❤️ for advanced application flows.
Uses `perfect_freehand` for smooth ink strokes and `flutter_colorpicker` for tool selection.
