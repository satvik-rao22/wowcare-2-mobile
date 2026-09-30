import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';
import 'package:wowcare/core/theme/skeu_inset_paint.dart';

/// Guards the cost model of the flat material, not its look: the look is
/// pinned by the first group, which renders every well shape both ways and
/// requires the cached tile to match the literal drawing pixel for pixel.
///
/// The second group is the reason the cache exists. A well repainted on
/// every frame of a keyboard animation must not rasterise anything, and a
/// card, which has no blur, must not allocate a tile at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SkeuInsetRaster.clear);

  Future<ui.Image> render(
    Size size,
    double dpr,
    void Function(Canvas canvas) draw,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(dpr);
    draw(canvas);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      (size.width * dpr).round(),
      (size.height * dpr).round(),
    );
    picture.dispose();
    return image;
  }

  Future<({int max, double mean})> diff(ui.Image a, ui.Image b) async {
    final Uint8List pa = (await a.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final Uint8List pb = (await b.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    expect(pa.length, pb.length);
    int max = 0;
    int sum = 0;
    for (int i = 0; i < pa.length; i++) {
      final int d = (pa[i] - pb[i]).abs();
      if (d > max) max = d;
      sum += d;
    }
    return (max: max, mean: sum / pa.length);
  }

  group('the cached tile draws the same pixels as the literal painter', () {
    // Every well geometry the surfaces produce: sliced on both axes, on one,
    // on neither, a pill whose radii are clamped, and a circle. Plus one at a
    // fractional offset, which is where a resampled tile could drift.
    final Map<String, (Size, RRect Function(Rect), List<AppInset>, Offset)>
    cases = <String, (Size, RRect Function(Rect), List<AppInset>, Offset)>{
      'text field (sliced along x only)': (
        const Size(360, 48),
        (Rect r) => BorderRadius.circular(8).toRRect(r),
        AppElevation.wellShallow,
        Offset.zero,
      ),
      'dropdown well (sliced along x only)': (
        const Size(340, 56),
        (Rect r) => BorderRadius.circular(16).toRRect(r),
        AppElevation.well,
        Offset.zero,
      ),
      'large well (sliced on both axes)': (
        const Size(300, 180),
        (Rect r) => BorderRadius.circular(16).toRRect(r),
        AppElevation.well,
        Offset.zero,
      ),
      'empty-state icon (exact on both axes)': (
        const Size(64, 64),
        (Rect r) => BorderRadius.circular(22).toRRect(r),
        AppElevation.well,
        Offset.zero,
      ),
      'pill trough (radii clamped by the box)': (
        const Size(200, 32),
        (Rect r) => BorderRadius.circular(100).toRRect(r),
        AppElevation.trough,
        Offset.zero,
      ),
      'dead fab, circle': (
        const Size(56, 56),
        (Rect r) => RRect.fromRectAndRadius(r, Radius.circular(r.width / 2)),
        AppElevation.fabDead,
        Offset.zero,
      ),
      'text field at a fractional offset': (
        const Size(360, 48),
        (Rect r) => BorderRadius.circular(8).toRRect(r),
        AppElevation.wellShallow,
        const Offset(10.37, 7.61),
      ),
    };

    for (final MapEntry<
          String,
          (Size, RRect Function(Rect), List<AppInset>, Offset)
        >
        c
        in cases.entries) {
      final (
        Size size,
        RRect Function(Rect) shape,
        List<AppInset> insets,
        Offset at,
      ) = c.value;
      for (final double dpr in <double>[1, 2.75]) {
        test('${c.key} @${dpr}x', () async {
          final Size canvasSize = Size(size.width + 24, size.height + 24);
          final Rect rect = (at + const Offset(12, 12)) & size;
          final RRect rrect = shape(rect);
          final Paint fill = Paint()..color = AppPalette.surfaceField;

          final ui.Image direct = await render(canvasSize, dpr, (Canvas c) {
            c.drawRRect(rrect, fill);
            paintSkeuInsetsDirect(c, rrect, insets);
          });
          final ui.Image cached = await render(canvasSize, dpr, (Canvas c) {
            c.drawRRect(rrect, fill);
            paintSkeuInsets(c, rrect, insets, devicePixelRatio: dpr);
          });

          expect(
            SkeuInsetRaster.fallbacks,
            0,
            reason: 'the cached path fell back to direct drawing',
          );
          expect(SkeuInsetRaster.length, 1);

          final ({int max, double mean}) d = await diff(direct, cached);
          // A well's shadow is 14% navy; its strongest channel step is under
          // 40 levels. Eight levels is under a quarter of that, and only a
          // resampled fractional edge gets anywhere near it.
          expect(d.max, lessThanOrEqualTo(8), reason: 'max channel diff');
          expect(d.mean, lessThan(0.15), reason: 'mean channel diff');
        });
      }
    }
  });

  group('a well repainted every frame rasterises nothing', () {
    test('twenty fields of different widths share one tile', () async {
      const double dpr = 3;
      for (int i = 0; i < 20; i++) {
        final RRect rrect = BorderRadius.circular(
          8,
        ).toRRect(Offset.zero & Size(200 + i * 7.0, 48));
        await render(const Size(400, 60), dpr, (Canvas c) {
          paintSkeuInsets(
            c,
            rrect,
            AppElevation.wellShallow,
            devicePixelRatio: dpr,
          );
        });
      }
      expect(SkeuInsetRaster.length, 1);
      expect(SkeuInsetRaster.misses, 1);
      expect(SkeuInsetRaster.hits, 19);
    });

    test(
      'a different height cuts a second tile; a different width does not',
      () async {
        const double dpr = 2;
        final List<AppInset> well = AppElevation.well;
        for (final Size s in <Size>[
          const Size(300, 56),
          const Size(250, 56),
          const Size(300, 44),
        ]) {
          await render(const Size(320, 60), dpr, (Canvas c) {
            paintSkeuInsets(
              c,
              BorderRadius.circular(16).toRRect(Offset.zero & s),
              well,
              devicePixelRatio: dpr,
            );
          });
        }
        expect(SkeuInsetRaster.length, 2);
      },
    );

    test('a card has no blur, so it never allocates a tile', () async {
      for (final List<AppInset> hard in <List<AppInset>>[
        AppElevation.bevelTop,
        AppElevation.bevelGloss,
        AppElevation.bevelColoured,
        AppElevation.bevelSoft,
      ]) {
        await render(const Size(320, 120), 3, (Canvas c) {
          paintSkeuInsets(
            c,
            BorderRadius.circular(
              20,
            ).toRRect(const Rect.fromLTWH(0, 0, 300, 100)),
            hard,
            devicePixelRatio: 3,
          );
        });
      }
      expect(SkeuInsetRaster.length, 0);
      expect(SkeuInsetRaster.misses, 0);
      expect(SkeuInsetRaster.fallbacks, 0);
    });

    test('the cache is bounded by entries and by bytes', () async {
      // Sixty-eight distinct corner radii, so sixty-eight distinct tiles:
      // more than maxEntries.
      for (int i = 0; i < SkeuInsetRaster.maxEntries + 4; i++) {
        final double radius = 4 + i * 0.5;
        await render(const Size(320, 320), 1, (Canvas c) {
          paintSkeuInsets(
            c,
            BorderRadius.circular(
              radius,
            ).toRRect(const Rect.fromLTWH(0, 0, 300, 300)),
            AppElevation.well,
            devicePixelRatio: 1,
          );
        });
      }
      expect(SkeuInsetRaster.length, SkeuInsetRaster.maxEntries);

      // Eight large unsliced tiles at 3x: 1.4 MB each, past the byte cap.
      SkeuInsetRaster.clear();
      for (int i = 0; i < 8; i++) {
        final double side = 200.0 + i;
        await render(const Size(220, 220), 3, (Canvas c) {
          paintSkeuInsets(
            c,
            BorderRadius.circular(16).toRRect(Offset.zero & Size(side, side)),
            AppElevation.well,
            devicePixelRatio: 3,
          );
        });
      }
      expect(
        SkeuInsetRaster.bytes,
        lessThanOrEqualTo(SkeuInsetRaster.maxBytes),
      );
      expect(SkeuInsetRaster.length, lessThan(8));
      expect(SkeuInsetRaster.length, greaterThan(0));
    });

    test('SkeuInsetPainter compares its recipe by value', () {
      // AppElevation.well builds a new list per call; identity would always
      // repaint.
      const BorderRadius r = BorderRadius.all(Radius.circular(8));
      expect(
        SkeuInsetPainter(
          AppElevation.well,
          r,
          devicePixelRatio: 2,
        ).shouldRepaint(
          SkeuInsetPainter(AppElevation.well, r, devicePixelRatio: 2),
        ),
        isFalse,
      );
      expect(
        SkeuInsetPainter(
          AppElevation.well,
          r,
          devicePixelRatio: 2,
        ).shouldRepaint(
          SkeuInsetPainter(AppElevation.wellShallow, r, devicePixelRatio: 2),
        ),
        isTrue,
      );
    });

    testWidgets('a decorated well and a field well both reach the cache', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 3),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: <Widget>[
                Container(
                  width: 300,
                  height: 56,
                  decoration: AppSurfaces.well(),
                ),
                SkeuFieldWell(
                  radius: 8,
                  child: Container(
                    width: 300,
                    height: 48,
                    color: AppPalette.surfaceField,
                  ),
                ),
                Container(
                  width: 300,
                  height: 100,
                  decoration: AppSurfaces.card(),
                ),
              ],
            ),
          ),
        ),
      );
      // One tile for the dropdown well, one for the text-field well, none
      // for the card.
      expect(SkeuInsetRaster.length, 2);
      expect(SkeuInsetRaster.fallbacks, 0);

      // A relayout (the keyboard opening, say) repaints without a new tile.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 3),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: <Widget>[
                Container(
                  width: 280,
                  height: 56,
                  decoration: AppSurfaces.well(),
                ),
                SkeuFieldWell(
                  radius: 8,
                  child: Container(
                    width: 280,
                    height: 48,
                    color: AppPalette.surfaceField,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(SkeuInsetRaster.length, 2);
      expect(SkeuInsetRaster.misses, 2);
    });
  });

  group('a glyph is a raster, not a layered picture', () {
    testWidgets('AppIcon opts into the raster strategy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _SvgBundle(),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: AppIcon('assets/icons/any.svg', size: 24),
          ),
        ),
      );
      final SvgPicture svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.renderingStrategy, RenderingStrategy.raster);
      expect(svg.colorFilter, isNotNull);
    });

    testWidgets('AppArtwork keeps the picture strategy: no filter, no layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _SvgBundle(),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: AppArtwork('assets/icons/any.svg', width: 24),
          ),
        ),
      );
      final SvgPicture svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.renderingStrategy, RenderingStrategy.picture);
      expect(svg.colorFilter, isNull);
    });
  });
}

/// Serves one tiny SVG for any key, so the icon widgets can be built without
/// the real asset bundle.
class _SvgBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
              '<rect width="24" height="24" fill="#000"/></svg>'
          .codeUnits,
    ),
  );
}
