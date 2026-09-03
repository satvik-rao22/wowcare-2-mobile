import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// One band of a segmented trough.
@immutable
class TroughSegment {
  const TroughSegment({required this.fraction, required this.color});

  /// Share of the trough, 0 to 1. Segments should sum to 1 or less.
  final double fraction;
  final Color color;
}

/// A recessed 9px bar with a fill inside it. Components page `.trough`.
///
/// [Trough] draws one fill to [fraction] in [fill] (teal for students, the
/// design's default). [Trough.segments] stacks bands left to right for the
/// attendance breakdown on 3A1.
class Trough extends StatelessWidget {
  const Trough({
    required double fraction,
    this.fill,
    this.height = AppSizes.troughHeight,
    super.key,
  }) : _fraction = fraction,
       segments = null;

  const Trough.segments({
    required List<TroughSegment> this.segments,
    this.height = AppSizes.troughHeight,
    super.key,
  }) : _fraction = 0,
       fill = null;

  final double _fraction;

  /// Defaults to the student teal.
  final Color? fill;

  final List<TroughSegment>? segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final radius = height / 2;

    return SurfaceBox(
      surface: AppSurfaces.trough(c, radius: radius),
      height: height,
      clipContent: true,
      child: segments != null ? _bands(context) : _bar(radius, c.student),
    );
  }

  Widget _bar(double radius, Color defaultFill) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: _fraction.clamp(0, 1),
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill ?? defaultFill,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
  );

  Widget _bands(BuildContext context) {
    // Flex factors are integers, so each share is scaled up before rounding.
    const scale = 1000;
    final used = segments!.fold<double>(0, (sum, s) => sum + s.fraction);
    final rest = (1 - used).clamp(0, 1).toDouble();

    // Stretch, not the default centre: a `ColoredBox` with no child takes the
    // smallest size its constraints allow, and a Row hands its children a
    // loose cross-axis constraint, so a centred band would be nought high.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final s in segments!)
          if (s.fraction > 0)
            Expanded(
              flex: (s.fraction * scale).round(),
              child: ColoredBox(color: s.color),
            ),
        if (rest > 0)
          Expanded(flex: (rest * scale).round(), child: const SizedBox()),
      ],
    );
  }
}
