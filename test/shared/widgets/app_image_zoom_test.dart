import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/app_image/app_image.dart';

/// Solid PNG of the given pixel size.
Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF3366FF),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Matrix4 _matrix(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value;

Future<void> _doubleTap(WidgetTester tester, Offset at) async {
  await tester.tapAt(at);
  await tester.pump(kDoubleTapMinTime);
  await tester.tapAt(at);
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(WidgetTester tester, Uint8List bytes) async {
  tester.view.physicalSize = const Size(400, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AppImage(source: bytes, interaction: AppImageInteraction.zoom),
    ),
  );
  // Decode happens off the fake clock.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

void main() {
  // 1600x800 in a 400x400 viewport: fitted 400x200 → cover 2x, original 4x.
  testWidgets('double-tap cycles fit → cover → original → fit', (tester) async {
    final bytes = (await tester.runAsync(() => _png(1600, 800)))!;
    await _pumpViewer(tester, bytes);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    const center = Offset(200, 200);

    expect(_matrix(tester).getMaxScaleOnAxis(), closeTo(1, 0.01));
    await _doubleTap(tester, center);
    expect(_matrix(tester).getMaxScaleOnAxis(), closeTo(2, 0.01));
    await _doubleTap(tester, center);
    expect(_matrix(tester).getMaxScaleOnAxis(), closeTo(4, 0.01));
    await _doubleTap(tester, center);
    expect(_matrix(tester).getMaxScaleOnAxis(), closeTo(1, 0.01));
  });

  testWidgets('pan is bounded by the image, not the letterbox', (tester) async {
    final bytes = (await tester.runAsync(() => _png(1600, 800)))!;
    await _pumpViewer(tester, bytes);

    // Fitted: nothing to pan, image stays centred.
    await tester.dragFrom(const Offset(200, 200), const Offset(150, 150));
    await tester.pumpAndSettle();
    expect(_matrix(tester).getTranslation().x, closeTo(0, 0.5));
    expect(_matrix(tester).getTranslation().y, closeTo(0, 0.5));

    // At cover (2x) the image is 800x400: x pans within [-400, 0], y is locked
    // (image exactly fills the height), so the black bars never show.
    await _doubleTap(tester, const Offset(200, 200));
    await tester.dragFrom(const Offset(200, 200), const Offset(1000, 300));
    await tester.pumpAndSettle();
    final t = _matrix(tester).getTranslation();
    expect(t.x, closeTo(0, 0.5));
    // rect.top = 100 → y = -100*2 = -200 keeps the image flush with the top.
    expect(t.y, closeTo(-200, 0.5));

    await tester.dragFrom(const Offset(200, 200), const Offset(-2000, -300));
    await tester.pumpAndSettle();
    expect(_matrix(tester).getTranslation().x, closeTo(-400, 0.5));
    expect(_matrix(tester).getTranslation().y, closeTo(-200, 0.5));
  });

  testWidgets('cannot pinch below fit', (tester) async {
    final bytes = (await tester.runAsync(() => _png(800, 800)))!;
    await _pumpViewer(tester, bytes);
    final a = await tester.startGesture(const Offset(100, 200));
    final b = await tester.startGesture(const Offset(300, 200));
    await a.moveTo(const Offset(180, 200));
    await b.moveTo(const Offset(220, 200));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(_matrix(tester).getMaxScaleOnAxis(), closeTo(1, 0.01));
  });

  testWidgets('error state uses errorBuilder with the failure', (tester) async {
    Object? seen = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: AppImage(
          source: null,
          interaction: AppImageInteraction.zoom,
          errorBuilder: (_, error, __) {
            seen = error;
            return const Text('failed');
          },
        ),
      ),
    );
    expect(find.text('failed'), findsOneWidget);
    expect(seen, isNull);
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
