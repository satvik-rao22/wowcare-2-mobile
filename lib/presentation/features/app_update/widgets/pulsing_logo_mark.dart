import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// The size and timing of one [PulsingLogoMark]. The presets are the three
/// sizes *WowCare System Messages* draws the mark at.
class PulsingMarkSpec {
  const PulsingMarkSpec({
    required this.extent,
    required this.ringExtent,
    required this.ringRadius,
    required this.tileExtent,
    required this.tileRadius,
    required this.markExtent,
    required this.cast,
    required this.ringColors,
    required this.ringPeriod,
    required this.floatPeriod,
    this.ringStroke = 2,
  });

  /// S1, the optional banner on a phone: 132, rings in the logo's order.
  static const PulsingMarkSpec optional = PulsingMarkSpec(
    extent: 132,
    ringExtent: 126,
    ringRadius: 44,
    tileExtent: 66,
    tileRadius: 24,
    markExtent: 34,
    cast: 10,
    ringColors: <Color>[
      BrandRamps.pink600,
      BrandRamps.teal400,
      BrandRamps.sun400,
    ],
    ringPeriod: Duration(milliseconds: 4200),
    floatPeriod: Duration(seconds: 6),
  );

  /// ST1, the optional banner on a tablet: 104, beside the copy.
  static const PulsingMarkSpec optionalWide = PulsingMarkSpec(
    extent: 104,
    ringExtent: 100,
    ringRadius: 36,
    tileExtent: 56,
    tileRadius: 20,
    markExtent: 30,
    cast: 10,
    ringColors: <Color>[
      BrandRamps.pink600,
      BrandRamps.teal400,
      BrandRamps.sun400,
    ],
    ringPeriod: Duration(milliseconds: 4200),
    floatPeriod: Duration(seconds: 6),
  );

  /// S2, the required overlay: 148, with urgent rings on a quicker beat.
  static const PulsingMarkSpec required = PulsingMarkSpec(
    extent: 148,
    ringExtent: 142,
    ringRadius: 50,
    tileExtent: 76,
    tileRadius: 28,
    markExtent: 40,
    cast: 12,
    ringColors: <Color>[
      AppPalette.statusError,
      AppPalette.brandSecondary,
      AppPalette.brand,
    ],
    ringPeriod: Duration(milliseconds: 3400),
    floatPeriod: Duration(seconds: 5),
  );

  /// The square the mark occupies in layout. The rings grow past it as
  /// they fade, exactly as they do in the design.
  final double extent;
  final double ringExtent;
  final double ringRadius;
  final double ringStroke;
  final double tileExtent;
  final double tileRadius;
  final double markExtent;

  /// How far the tile's pink shadow falls.
  final double cast;

  /// One ring per colour, a third of [ringPeriod] apart.
  final List<Color> ringColors;
  final Duration ringPeriod;

  /// The tile's own loop. Deliberately not a multiple of [ringPeriod], so
  /// the pair never lands on the same frame twice.
  final Duration floatPeriod;
}

/// The update banners' mark: rounded-square rings that grow and fade in
/// turn, around the logo on a pink tile that breathes on a slower loop.
/// Built to *WowCare Animations and Assets* A1.
///
/// Cheap by construction:
/// * the rings are three stroked rounded rects in a [CustomPainter] that
///   repaints straight off its controller, with no widget rebuild;
/// * the tile is painted once, the logo rasterised once, and each frame only
///   moves that layer, so the SVG is never re-drawn;
/// * both halves sit behind their own [RepaintBoundary], so the banner and
///   the screen around it never repaint for the animation;
/// * it stops when scrolled out of view, when its route or tab is hidden
///   ([TickerMode]), and while the app is in the background.
///
/// Under the platform's reduce-motion setting it shows the tile alone,
/// still, as the design asks.
class PulsingLogoMark extends StatefulWidget {
  const PulsingLogoMark({required this.spec, super.key});

  final PulsingMarkSpec spec;

  @override
  State<PulsingLogoMark> createState() => _PulsingLogoMarkState();
}

class _PulsingLogoMarkState extends State<PulsingLogoMark>
    with TickerProviderStateMixin {
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: widget.spec.ringPeriod,
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: widget.spec.floatPeriod,
  );

  bool _reduceMotion = false;
  bool _inView = true;
  bool _viewCheckQueued = false;
  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ScrollPosition? scroll = Scrollable.maybeOf(context)?.position;
    if (!identical(scroll, _scroll)) {
      _scroll?.removeListener(_queueViewCheck);
      _scroll = scroll?..addListener(_queueViewCheck);
      _queueViewCheck();
    }
    _syncMotion();
  }

  /// Scroll positions can notify mid-layout, when geometry is not safe to
  /// read, so the check waits for the end of the frame.
  void _queueViewCheck() {
    if (_viewCheckQueued) return;
    _viewCheckQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _viewCheckQueued = false;
      if (!mounted) return;
      final bool inView = _isInView();
      if (inView == _inView) return;
      _inView = inView;
      _syncMotion();
    });
  }

  bool _isInView() {
    final RenderObject? box = context.findRenderObject();
    final ScrollPosition? scroll = _scroll;
    if (scroll == null || box is! RenderBox || !box.hasSize) return true;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      box,
    );
    if (viewport == null) return true;
    // The scroll offsets that put this box flush with the viewport's leading
    // edge and flush with its trailing edge. Some of it is on screen for
    // any offset between the two, widened by the box's own length.
    final double leading = viewport.getOffsetToReveal(box, 0).offset;
    final double trailing = viewport.getOffsetToReveal(box, 1).offset;
    final double length = scroll.axis == Axis.vertical
        ? box.size.height
        : box.size.width;
    return scroll.pixels > trailing - length &&
        scroll.pixels < leading + length;
  }

  void _syncMotion() {
    if (!_reduceMotion && _inView) {
      if (!_rings.isAnimating) _rings.repeat();
      if (!_float.isAnimating) _float.repeat();
    } else {
      _rings.stop();
      _float.stop();
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_queueViewCheck);
    _rings.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PulsingMarkSpec spec = widget.spec;
    final Widget tile = RepaintBoundary(child: _MarkTile(spec: spec));
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: spec.extent,
        child: _reduceMotion
            ? Center(child: tile)
            : Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RingsPainter(cycle: _rings, spec: spec),
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _float,
                      builder: (BuildContext context, Widget? child) =>
                          Transform(
                            alignment: Alignment.center,
                            transform: _floatAt(_float.value),
                            child: child,
                          ),
                      child: tile,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// `wcFloat`: up 5px and round 1.5deg at the half-way point, back by the
  /// end, ease-in-out each way.
  static Matrix4 _floatAt(double t) {
    final double lift = Curves.easeInOut.transform(
      t < .5 ? t * 2 : (1 - t) * 2,
    );
    return Matrix4.translationValues(0, -_floatRise * lift, 0)
      ..rotateZ(_floatTilt * lift);
  }

  static const double _floatRise = 5;
  static const double _floatTilt = 1.5 * math.pi / 180;
}

/// The pink tile and the logo on it. Static: all of its movement comes from
/// the transform above it.
class _MarkTile extends StatelessWidget {
  const _MarkTile({required this.spec});

  final PulsingMarkSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: spec.tileExtent,
      height: spec.tileExtent,
      alignment: Alignment.center,
      decoration: AppSurfaces.markTile(
        radius: spec.tileRadius,
        cast: spec.cast,
      ),
      child: AppArtwork(
        MediaRes.logoMark,
        width: spec.markExtent,
        height: spec.markExtent,
        rasterize: true,
      ),
    );
  }
}

/// `wcRing`, three times over: each ring scales from 55% to 150% across the
/// cycle and fades from 60% to nothing by 70% of it, both ease-out. Ring
/// `i` runs `i / n` of a cycle behind the first.
class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.cycle, required this.spec})
    : super(repaint: cycle);

  final Animation<double> cycle;
  final PulsingMarkSpec spec;

  final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  static const double _startScale = .55;
  static const double _endScale = 1.5;
  static const double _startOpacity = .6;
  static const double _fadeEnd = .7;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final int count = spec.ringColors.length;
    for (int i = 0; i < count; i++) {
      final double phase = (cycle.value - i / count) % 1.0;
      if (phase >= _fadeEnd) continue;
      final double opacity =
          _startOpacity * (1 - Curves.easeOut.transform(phase / _fadeEnd));
      final double scale = lerpDouble(
        _startScale,
        _endScale,
        Curves.easeOut.transform(phase),
      )!;
      // The design's border sits inside its box, so the stroke's centre
      // line is half a stroke in from the ring's edge.
      final double side = (spec.ringExtent - spec.ringStroke) * scale;
      final double radius = (spec.ringRadius - spec.ringStroke / 2) * scale;
      _stroke
        ..color = spec.ringColors[i].withValues(alpha: opacity)
        ..strokeWidth = spec.ringStroke * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: centre, width: side, height: side),
          Radius.circular(radius),
        ),
        _stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      !identical(oldDelegate.cycle, cycle) ||
      !identical(oldDelegate.spec, spec);
}
