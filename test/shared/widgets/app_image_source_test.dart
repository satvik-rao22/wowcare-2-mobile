import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/app_image/app_image_source.dart';

void main() {
  group('AppImageSource.from', () {
    test('network raster, ignoring "asset"/".svg" inside the query', () {
      final s = AppImageSource.from(
        'https://cdn.x.com/media-assets/a.png?name=b.svg&X-Amz-Signature=1',
      );
      expect(s, isA<NetworkAppImageSource>());
      expect(s!.format, AppImageFormat.raster);
    });

    test('network svg and lottie by path extension', () {
      expect(AppImageSource.from('https://x.com/i.SVG?v=2')!.format,
          AppImageFormat.svg);
      expect(AppImageSource.from('https://x.com/a.json')!.format,
          AppImageFormat.lottie);
    });

    test('assets', () {
      expect(AppImageSource.from('assets/icons/sleep.svg'),
          isA<AssetAppImageSource>().having((s) => s.format, 'format', AppImageFormat.svg));
      expect(AppImageSource.from('assets/lottie/x.json')!.format,
          AppImageFormat.lottie);
      expect(AppImageSource.from('assets/images/a.webp')!.format,
          AppImageFormat.raster);
    });

    test('files', () {
      expect(AppImageSource.from('/var/mobile/tmp/IMG_1.HEIC'),
          isA<FileAppImageSource>());
      expect(AppImageSource.from('file:///tmp/a.png'),
          isA<FileAppImageSource>().having((s) => s.path, 'path', '/tmp/a.png'));
    });

    test('memory sniffing', () {
      Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));
      expect(AppImageSource.from(b('  <svg></svg>'))!.format, AppImageFormat.svg);
      expect(AppImageSource.from(b('{"v":"5"}'))!.format, AppImageFormat.lottie);
      expect(AppImageSource.from(Uint8List.fromList([0x89, 0x50]))!.format,
          AppImageFormat.raster);
    });

    test('null, blank, unknown → null', () {
      expect(AppImageSource.from(null), isNull);
      expect(AppImageSource.from('   '), isNull);
      expect(AppImageSource.from('not-a-path.png'), isNull);
      expect(AppImageSource.from(42), isNull);
    });
  });

  test('stableCacheKey strips only signature params', () {
    expect(
      NetworkAppImageSource.stableCacheKey(
        'https://b.s3.amazonaws.com/k.jpg?X-Amz-Date=1&X-Amz-Signature=abc&w=200',
      ),
      'https://b.s3.amazonaws.com/k.jpg?w=200',
    );
    expect(
      NetworkAppImageSource.stableCacheKey('https://x.com/a.jpg?Expires=1&Signature=s'),
      'https://x.com/a.jpg',
    );
    expect(NetworkAppImageSource.stableCacheKey('https://x.com/a.jpg'),
        'https://x.com/a.jpg');
  });
}
