# Perfect Draw Board

`perfect_draw_board`, Flutter projelerinizde gelişmiş, yüksek performanslı ve zengin özellikli grafik/çizim tahtaları oluşturmanızı sağlayan yerel bir pakettir. İçerisindeki `perfect_freehand` entegrasyonuyla pürüzsüz ve gerçeğe yakın (basınca duyarlı hissi veren) serbest el çizimleri (freehand drawing) yapmanıza olanak tanır.

Bu paket, uygulamasında çizim, beyaz tahta (whiteboard), not alma veya PDF/resim üzerine işaretlemeler yapma özelliği barındırmak isteyen projeler için oldukça uygundur ve tek başına ayrı bir paket olarak kolayca başka projelere entegre edilebilir.

## Özellikler

- 🚀 **Yüksek Performans:** Yalnızca çizim state'ini yenileyen (`Listenable.merge` ile) ve `InteractiveViewer` (TransformationController) pan/zoom hareketleriyle doğrudan senkronize çalışarak gereksiz `build` tetiklemeyen 60fps+ çizim yapısı.
- ✏️ **Pürüzsüz Çizim:** `perfect_freehand` modülü sayesinde düzgün ve kaliteli serbest el yazısı hissiyatı.
- 🎨 **Zengin Şekil ve Araç Seti:**
  - Klasik Kalem (`line`), Düz Çizgi (`linearLine`), Ok (`arrow`), Kesik Çizgi (`dashedLine`)
  - Geometrik Şekiller: Dikdörtgen, Daire, Üçgen, Beşgen, Altıgen vb.
  - Emoji çizimi desteği.
  - Silgi (`isEraser`) ve Fosforlu Kalem (`isHighlighter`).
  - Dinamik olarak kaybolan Lazer İşaretçi efekti (`isLaser`).
- 📚 **Çoklu Sayfa Yönetimi (Pagination):** Birden fazla sayfalı PDF veya sunumlarda her sayfanın çizimini (`pageLines`) index'e göre hafızada ayrı ayrı tutar.
- 🔄 **Undo (Geri Al) & Redo (İleri Al):** Sayfa bazında bağımsız geri/ileri al işlemleri.
- 🔦 **Spotlight Modu:** `SpotlightPainter` ile ekrandaki belirli bir noktaya karanlık mod içerisinde odaklanabilme.

## Kurulum

Eğer projeyi lokal bir paket olarak başka bir projeye dâhil edecekseniz, hedef projenizin `pubspec.yaml` dosyasına path (dosya yolu) belirterek ekleyebilirsiniz:

```yaml
dependencies:
  flutter:
    sdk: flutter
  perfect_freehand: ^2.5.2+1
  perfect_draw_board:
    path: ../path_to/exam_video_recoder/packages/perfect_draw_board
```

## Temel Kullanım Yönergesi

### 1. State (Durum) Tanımlaması

Çizim işlemlerini yönetmek için bir adet `DrawingState` oluşturun ve yöneteceğiniz sayfa sayısını başlatın. Çizimlerin (zoom & pan ile) düzgün haritalanabilmesi için bir adet de `TransformationController` nesnesi gerekir.

```dart
import 'package:perfect_draw_board/perfect_draw_board.dart';
import 'package:flutter/material.dart';

class MyDrawBoard extends StatefulWidget {
  @override
  _MyDrawBoardState createState() => _MyDrawBoardState();
}

class _MyDrawBoardState extends State<MyDrawBoard> {
  final DrawingState drawingState = DrawingState();
  final TransformationController transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Örnek: 1 adet çizim sayfası (veya tablosu) başlatılıyor.
    drawingState.initPages(1);
  }
```

### 2. Gesture (Hareket) Yakalama Fonksiyonları

Ekrana dokunulduğunda (`onPanStart`), sürükleme yapıldığında (`onPanUpdate`) ve dokunma bırakıldığında (`onPanEnd`), ekran koordinatını InteractiveViewer'ın ölçeğine (board koordinatına) adapte etmeniz şarttır:

```dart
  void _onPanStart(DragStartDetails details) {
    // Koordinatı dönüştür
    final Matrix4 inverse = Matrix4.tryInvert(transformController.value) ?? Matrix4.identity();
    final Offset boardPoint = MatrixUtils.transformPoint(inverse, details.localPosition);

    // Başlangıç çizgisini yarat
    final newLine = DrawnLine(
      points: [boardPoint],
      color: Colors.red, // Kalem Rengi
      width: 4.0,        // Kalem Kalınlığı
      shape: DrawShape.line, // Şekil ya da Kalem Tipi
    );

    // 0. sayfa üzerinden çizgiyi başlat
    drawingState.startLine(newLine, 0); 
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Matrix4 inverse = Matrix4.tryInvert(transformController.value) ?? Matrix4.identity();
    final Offset boardPoint = MatrixUtils.transformPoint(inverse, details.localPosition);

    drawingState.updateLine(boardPoint, DrawShape.line);
  }

  void _onPanEnd(DragEndDetails details) {
    // 0. sayfa için çizimi sonlandırıp hafızaya/listeye ekle
    drawingState.endLine(0);
  }
```

### 3. Çizimi Görüntüleme (CustomPaint)

Flutter'ın `InteractiveViewer` widget'ı ile çizim katmanını (`CustomPaint`) entegre ediyoruz. `PerfectFreehandPainter` otomatik olarak `DrawingState` üzerinde yapılan değişiklikleri dinleyecektir.

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveViewer(
        transformationController: transformController,
        // Zoom ve Pan limitlerinizi belirleyebilirsiniz
        minScale: 1.0,
        maxScale: 5.0,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              // perfect_freehand desteği ile pürüzsüz boyamayı çalıştır
              painter: PerfectFreehandPainter(
                drawingState: drawingState,
                transform: transformController,
                currentIndex: 0, // Yönetilen sayfanın indexi
              ),
              // VEYA klasik painter için WorldSpacePainter kullanın:
              // painter: WorldSpacePainter(...)
            ),
          ),
        ),
      ),
    );
  }
}
```

## Araçlar ve Gelişmiş Modlar (DrawShape)

Farklı araç tiplerini kullanmak için `DrawnLine` nesnesini oluştururken parametreleri değiştirmeniz yeterlidir:

### Geometrik Şekiller
```dart
final arrowLine = DrawnLine(
  points: [boardPoint],
  color: Colors.blue,
  width: 3.0,
  shape: DrawShape.arrow, // Ok, dikdörtgen, üçgen vb.
);
```

### Fosforlu Kalem (Highlighter)
Fosforlu kalem özelliği kullanıllırken çizimin arkasındaki nesnelerin görünmesi sağlanır.
```dart
final highlighter = DrawnLine(
  points: [boardPoint],
  color: Colors.yellow.withOpacity(0.5),
  width: 20.0,
  isHighlighter: true,
);
```

### Silgi (Eraser)
Silgi modu blend layer mantığında çalışıp o bölgedeki çizgileri renksizleştirerek siler.
```dart
final eraser = DrawnLine(
  points: [boardPoint],
  color: Colors.transparent,
  width: 30.0,
  isEraser: true, 
);
```

### Lazer (Laser Pointer) ve Tick() Güncellemesi
Ekranda sadece birkaç saniye kalıp kaybolan Lazer özelliği için çizginize `isLaser: true` vermelisiniz. Lazerlerin ekrandan tamamen kaybolduğunu yönetebilmek için bir saat (Ticker) üzerinden sürekli `drawingState.tick()` çağırmanız gerekir.

```dart
// State içinde lazer güncellemelerini test eden örnek bir ticker:
Timer.periodic(Duration(milliseconds: 100), (timer) {
  drawingState.tick();
});
```

### Geri Al, İleri Al ve Temizle

Sayfa indeksine göre (Örneğin `0` numaralı sayfa için) işlemleri çok rahat gerçekleştirebilirsiniz:

```dart
// Son yapılan işlemi geri al (Undo)
drawingState.undo(0);

// Geri alınan işlemi tekrar yerine koy (Redo)
drawingState.redo(0);

// Sayfanın tüm çizimlerini temizle (Clear)
drawingState.clear(0);
```

---

_Bu README dosyası `perfect_draw_board` paketinin diğer local projelere nasıl taşınacağını ve standart özelliklerin entegrasyonu esnasında nasıl davranılacağını belirlemek amacıyla oluşturulmuştur._
