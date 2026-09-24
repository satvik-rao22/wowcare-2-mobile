/// Paints CSS-style `inset` box-shadows, once per recipe rather than once per
/// frame.
///
/// `SkeuDecoration` and `SkeuInnerShadow` both draw their insets through
/// [paintSkeuInsets], so the geometry lives in one place and so does the
/// cost model below.
///
/// ## Why this file exists
///
/// A blurred inset is "everything outside an offset copy of the shape,
/// filled with a blurred paint, clipped to the shape". Drawn literally that
/// costs, for every well on screen, on every frame it repaints:
///
/// * a path boolean on the UI thread (`Path.combine`), and
/// * under Impeller a Gaussian blur pass on the GPU — an offscreen render
///   target per inset, because Impeller has no raster cache to hide it.
///
/// A form screen with twenty fields therefore ran twenty to forty blur passes
/// per frame, and the keyboard animation relayouts the whole body on every
/// one of its frames. That is the whole of the "keyboard is slow" report.
///
/// The fix keeps the drawing identical and changes only how often it is done:
///
/// 1. **Hard insets** (`blur == 0`: the lit bevel, the lit bottom edge) are
///    drawn directly, as the region between two rounded rects
///    ([Canvas.drawDRRect]), which is the same set of pixels `Path.combine`
///    produced without the path boolean. No blur, so nothing to cache.
/// 2. **Soft insets** (`blur > 0`: every well and trough) are rasterised once
///    into a small tile and drawn as a nine-slice. A well's shadow only
///    varies near its corners; along a straight edge the profile is the same
///    at every point, so a tile holding the four corners plus an 8px band of
///    straight edge stretches to any width and height exactly. When a well
///    is too small to slice on an axis (a 48px field is shorter than two
///    corner regions), the tile spans that axis at the well's exact size
///    instead, so nothing is ever scaled.
///
/// Tiles are keyed by the effective corner radii, the inset recipe and the
/// device pixel ratio, so every text field on a screen shares one tile and
/// every dropdown shares another. The cache is bounded ([SkeuInsetRaster.maxEntries],
/// [SkeuInsetRaster.maxBytes]) and evicts least-recently-used; on any raster
/// failure it falls back to the direct drawing, so the worst case is the old
/// behaviour, never a missing shadow.
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:wowcare/core/theme/app_elevation.dart';

/// Paints [insets] inside [rrect] on [canvas], clipped to [rrect].
///
/// [devicePixelRatio] is the ratio the canvas will be rasterised at; a tile
/// rendered at the wrong ratio would be resampled and read soft. Decorations
/// get it from their [ImageConfiguration], widgets from `MediaQuery`.
void paintSkeuInsets(
  Canvas canvas,
  RRect rrect,
  List<AppInset> insets, {
  required double devicePixelRatio,
}) {
  if (insets.isEmpty || rrect.isEmpty) return;
  for (final AppInset s in insets) {
    if (s.blur > 0) {
      SkeuInsetRaster.paint(canvas, rrect, insets, devicePixelRatio);
      return;
    }
  }
  paintSkeuInsetsDirect(canvas, rrect, insets);
}

/// The literal drawing, uncached: what a tile is rendered from, and what
/// [paintSkeuInsets] falls back to. Exposed so a test can compare the two.
///
/// [clip] false paints the shadow unclipped, filling the whole outside of
/// the shape too. A tile is rendered that way and clipped when it is drawn,
/// so the edge is anti-aliased exactly once, at its real position.
void paintSkeuInsetsDirect(
  Canvas canvas,
  RRect rrect,
  List<AppInset> insets, {
  bool clip = true,
}) {
  if (insets.isEmpty || rrect.isEmpty) return;
  final Rect rect = rrect.outerRect;
  // Big enough that its edges are never inside the clip, so the region
  // between it and the inner shape is "everything outside the inner shape".
  final RRect outer = RRect.fromRectAndRadius(
    rect.inflate(rect.longestSide + 40),
    Radius.zero,
  );

  canvas.save();
  if (clip) canvas.clipRRect(rrect);
  // CSS paint order: in list order, later insets over earlier ones.
  for (final AppInset s in insets) {
    if (s.blur == 0 && s.offset == Offset.zero && s.spread > 0) {
      // `inset 0 0 0 Npx <color>` — a hairline ring drawn inside the edge.
      canvas.drawRRect(
        rrect.deflate(s.spread / 2),
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.spread,
      );
      continue;
    }
    final Paint paint = Paint()..color = s.color;
    if (s.blur > 0) {
      // CSS blur-radius r is roughly 2 sigma.
      paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s.blur / 2);
    }
    // Everything outside the shifted/deflated shape, so the blur spills in.
    // The same pixels `Path.combine(difference)` gave, minus the path boolean.
    canvas.drawDRRect(outer, rrect.deflate(s.spread).shift(s.offset), paint);
  }
  canvas.restore();
}

/// The tile cache behind [paintSkeuInsets]. See the library doc.
class SkeuInsetRaster {
  SkeuInsetRaster._();

  /// Logical pixels of straight edge kept in a tile on a sliced axis. It is
  /// stretched to fill the well, which is exact because along a straight
  /// edge the shadow does not vary.
  static const double _core = 8;

  /// Sampling for the stretched tile: bilinear, so a tile drawn at a
  /// fractional device offset softens by under a pixel instead of snapping.
  static final Paint _sampling = Paint()..filterQuality = FilterQuality.low;

  /// Most tiles kept. A typical screen needs fewer than ten.
  static const int maxEntries = 64;

  /// Most memory kept, in bytes of RGBA. A field's tile at 3x is about 100 KB;
  /// an unsliced 64px empty-state well about 150 KB.
  static const int maxBytes = 6 << 20;

  static final LinkedHashMap<_TileKey, _Tile> _tiles =
      LinkedHashMap<_TileKey, _Tile>();
  static int _bytes = 0;

  /// Tiles currently held.
  static int get length => _tiles.length;

  /// RGBA bytes currently held.
  static int get bytes => _bytes;

  /// Draws served from an existing tile, for tests and diagnostics.
  @visibleForTesting
  static int hits = 0;

  /// Draws that had to rasterise a new tile.
  @visibleForTesting
  static int misses = 0;

  /// Draws that fell back to [paintSkeuInsetsDirect].
  @visibleForTesting
  static int fallbacks = 0;

  /// Drops every tile and zeroes the counters. Safe at any time: a tile a
  /// frame is still drawing is kept alive by that frame's display list.
  static void clear() {
    for (final _Tile t in _tiles.values) {
      t.image.dispose();
    }
    _tiles.clear();
    _bytes = 0;
    hits = 0;
    misses = 0;
    fallbacks = 0;
  }

  /// Paints [insets] inside [rrect] from a cached tile, rasterising one if
  /// needed. Falls back to the direct drawing if the tile cannot be made.
  static void paint(
    Canvas canvas,
    RRect rrect,
    List<AppInset> insets,
    double devicePixelRatio,
  ) {
    if (!(devicePixelRatio > 0) || !devicePixelRatio.isFinite) {
      fallbacks++;
      paintSkeuInsetsDirect(canvas, rrect, insets);
      return;
    }
    // Radii larger than the box (a pill) are clamped by the rasteriser; the
    // tile has to be cut for the radii actually drawn.
    final RRect shape = rrect.scaleRadii();
    final _Geometry g = _Geometry(shape, insets, devicePixelRatio);
    final _Tile? tile = _tileFor(g, insets);
    if (tile == null) {
      fallbacks++;
      paintSkeuInsetsDirect(canvas, rrect, insets);
      return;
    }
    // The tile is unclipped; this clip is the one anti-aliased edge, exactly
    // as the direct path draws it.
    canvas.save();
    canvas.clipRRect(rrect);
    _drawTile(canvas, tile.image, g, shape.outerRect);
    canvas.restore();
  }

  /// Draws the tile's cells (one, three or nine) with explicit source and
  /// destination rects, so a corner cell lands at its logical size whatever
  /// the canvas scale. `Canvas.drawImageNine` cannot do this: it draws the
  /// corners at one image pixel per canvas unit, which under the device
  /// pixel ratio makes them ratio-times too large and squashes the band.
  static void _drawTile(Canvas canvas, ui.Image image, _Geometry g, Rect dst) {
    final List<double> sx = g.sliceX
        ? <double>[0, g.center.left, g.center.right, g.pxW.toDouble()]
        : <double>[0, g.pxW.toDouble()];
    final List<double> dx = g.sliceX
        ? <double>[dst.left, dst.left + g.capL, dst.right - g.capR, dst.right]
        : <double>[dst.left, dst.right];
    final List<double> sy = g.sliceY
        ? <double>[0, g.center.top, g.center.bottom, g.pxH.toDouble()]
        : <double>[0, g.pxH.toDouble()];
    final List<double> dy = g.sliceY
        ? <double>[dst.top, dst.top + g.capT, dst.bottom - g.capB, dst.bottom]
        : <double>[dst.top, dst.bottom];
    for (int i = 0; i < sx.length - 1; i++) {
      for (int j = 0; j < sy.length - 1; j++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(sx[i], sy[j], sx[i + 1], sy[j + 1]),
          Rect.fromLTRB(dx[i], dy[j], dx[i + 1], dy[j + 1]),
          _sampling,
        );
      }
    }
  }

  static _Tile? _tileFor(_Geometry g, List<AppInset> insets) {
    final _TileKey key = g.key(insets);
    final _Tile? hit = _tiles.remove(key);
    if (hit != null) {
      // Re-insert so the map's order stays least-recently-used first.
      _tiles[key] = hit;
      hits++;
      return hit;
    }
    final ui.Image? image = _rasterise(g, insets);
    if (image == null) return null;
    misses++;
    final _Tile tile = _Tile(image, g.pxW * g.pxH * 4);
    // Store a key that owns its recipe, so a caller mutating the list it
    // passed cannot corrupt the cache.
    _tiles[key.owned()] = tile;
    _bytes += tile.bytes;
    _evict();
    return tile;
  }

  static ui.Image? _rasterise(_Geometry g, List<AppInset> insets) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas c = Canvas(recorder);
    // Map the tile's logical size onto its pixel size exactly, which is the
    // device pixel ratio up to the rounding of the pixel extents.
    c.scale(g.pxW / g.tileW, g.pxH / g.tileH);
    final RRect shape = RRect.fromRectAndCorners(
      Offset.zero & Size(g.tileW, g.tileH),
      topLeft: g.tl,
      topRight: g.tr,
      bottomLeft: g.bl,
      bottomRight: g.br,
    );
    // Unclipped: the clip is applied where the tile is drawn (see [paint]).
    paintSkeuInsetsDirect(c, shape, insets, clip: false);
    final ui.Picture picture = recorder.endRecording();
    try {
      return picture.toImageSync(g.pxW, g.pxH);
    } catch (_) {
      // No GPU or a bad size: draw it the old way this frame and try again
      // on the next.
      return null;
    } finally {
      picture.dispose();
    }
  }

  static void _evict() {
    while (_tiles.length > 1 &&
        (_tiles.length > maxEntries || _bytes > maxBytes)) {
      final _TileKey oldest = _tiles.keys.first;
      final _Tile t = _tiles.remove(oldest)!;
      _bytes -= t.bytes;
      t.image.dispose();
    }
  }
}

class _Tile {
  _Tile(this.image, this.bytes);

  final ui.Image image;
  final int bytes;
}

/// How a well is cut into a tile: which axes stretch, how big the corner
/// regions are, and where the stretched band sits in the image.
class _Geometry {
  _Geometry(RRect shape, List<AppInset> insets, double dpr)
    : tl = shape.tlRadius,
      tr = shape.trRadius,
      bl = shape.blRadius,
      br = shape.brRadius,
      _dpr = dpr {
    // How far in from the edge a shadow can still be non-zero: its spread,
    // its offset, and three sigma of its blur (sigma is blur / 2).
    double reach = 0;
    for (final AppInset s in insets) {
      reach = math.max(
        reach,
        s.spread.abs() +
            math.max(s.offset.dx.abs(), s.offset.dy.abs()) +
            1.5 * s.blur,
      );
    }
    final double margin = reach.ceilToDouble() + 1;
    capL = math.max(tl.x, bl.x) + margin;
    capR = math.max(tr.x, br.x) + margin;
    capT = math.max(tl.y, tr.y) + margin;
    capB = math.max(bl.y, br.y) + margin;

    sliceX = shape.width >= capL + capR + SkeuInsetRaster._core;
    sliceY = shape.height >= capT + capB + SkeuInsetRaster._core;
    tileW = sliceX ? capL + SkeuInsetRaster._core + capR : shape.width;
    tileH = sliceY ? capT + SkeuInsetRaster._core + capB : shape.height;
    pxW = math.max(1, (tileW * dpr).round());
    pxH = math.max(1, (tileH * dpr).round());

    // The band that stretches, in image pixels. On an unsliced axis it spans
    // the whole image, which makes that axis a single cell.
    final double sx = pxW / tileW;
    final double sy = pxH / tileH;
    center = Rect.fromLTRB(
      sliceX ? capL * sx : 0,
      sliceY ? capT * sy : 0,
      sliceX ? (capL + SkeuInsetRaster._core) * sx : pxW.toDouble(),
      sliceY ? (capT + SkeuInsetRaster._core) * sy : pxH.toDouble(),
    );
  }

  final Radius tl;
  final Radius tr;
  final Radius bl;
  final Radius br;
  final double _dpr;

  late final double capL;
  late final double capR;
  late final double capT;
  late final double capB;
  late final bool sliceX;
  late final bool sliceY;
  late final double tileW;
  late final double tileH;
  late final int pxW;
  late final int pxH;
  late final Rect center;

  _TileKey key(List<AppInset> insets) => _TileKey(
    radii: <double>[tl.x, tl.y, tr.x, tr.y, bl.x, bl.y, br.x, br.y],
    insets: insets,
    dpr: _dpr,
    // A sliced axis is fully described by the radii and the recipe; an
    // unsliced one has to carry the exact extent it was cut at.
    exactW: sliceX ? null : pxW,
    exactH: sliceY ? null : pxH,
  );
}

@immutable
class _TileKey {
  const _TileKey({
    required this.radii,
    required this.insets,
    required this.dpr,
    required this.exactW,
    required this.exactH,
  });

  final List<double> radii;
  final List<AppInset> insets;
  final double dpr;
  final int? exactW;
  final int? exactH;

  _TileKey owned() => _TileKey(
    radii: List<double>.unmodifiable(radii),
    insets: List<AppInset>.unmodifiable(insets),
    dpr: dpr,
    exactW: exactW,
    exactH: exactH,
  );

  @override
  bool operator ==(Object other) =>
      other is _TileKey &&
      other.dpr == dpr &&
      other.exactW == exactW &&
      other.exactH == exactH &&
      listEquals(other.radii, radii) &&
      listEquals(other.insets, insets);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(radii),
    Object.hashAll(insets),
    dpr,
    exactW,
    exactH,
  );
}
