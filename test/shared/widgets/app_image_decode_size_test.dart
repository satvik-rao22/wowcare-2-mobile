import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/app_image/app_image.dart';

/// 1x1 transparent PNG — decoding is irrelevant, only the provider is checked.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<ImageProvider> _providerFor(
  WidgetTester tester, {
  double? width,
  double? height,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(devicePixelRatio: 3),
      child: Center(
        child: AppImage(source: _png, width: width, height: height),
      ),
    ),
  );
  return tester.widget<Image>(find.byType(Image)).image;
}

void main() {
  testWidgets('height only → decode by height, not width', (tester) async {
    final p = await _providerFor(tester, height: 40);
    expect(p, isA<ResizeImage>());
    expect((p as ResizeImage).height, 120);
    expect(p.width, isNull);
  });

  testWidgets('width only → decode by width', (tester) async {
    final p = await _providerFor(tester, width: 40) as ResizeImage;
    expect(p.width, 120);
    expect(p.height, isNull);
  });

  testWidgets('both → width hint from the larger side', (tester) async {
    final p = await _providerFor(tester, width: 30, height: 50) as ResizeImage;
    expect(p.width, 150);
    expect(p.height, isNull);
  });

  testWidgets('unbounded → full resolution', (tester) async {
    final p = await _providerFor(tester);
    expect(p, isNot(isA<ResizeImage>()));
  });
}
