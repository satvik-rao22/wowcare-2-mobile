import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/painters/inset_shadow_painter.dart';
import 'package:wowcare/redesign/core/theme/app_elevation.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// A complete material: a fill, a hairline, a radius, what it casts below and
/// what is lit inside it.
///
/// Flutter's [BoxDecoration] has no notion of an inset shadow, so a surface
/// that is only a [BoxDecoration] can express a card but not a well. This pairs
/// the two halves, and `SurfaceBox` renders them in the order CSS paints them:
/// fill, then insets, then content.
@immutable
class Surface {
  const Surface({
    required this.decoration,
    required this.borderRadius,
    this.insets = const <InsetShadow>[],
  });

  final BoxDecoration decoration;
  final BorderRadius borderRadius;
  final List<InsetShadow> insets;

  Surface copyWith({BoxDecoration? decoration, List<InsetShadow>? insets}) =>
      Surface(
        decoration: decoration ?? this.decoration,
        borderRadius: borderRadius,
        insets: insets ?? this.insets,
      );
}

/// Every surface in the app, built from the recipes on the design's
/// Components page. A screen composes these; it never writes a
/// [BoxDecoration] of its own.
abstract final class AppSurfaces {
  /// Anything raised off the tray.
  static Surface card(Colourway c) => Surface(
    borderRadius: AppRadii.cardR,
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: c.cardBorder),
      boxShadow: AppElevation.card(c),
    ),
    insets: AppElevation.bevel(c),
  );

  /// A card that sits visibly higher than its neighbours.
  static Surface cardRaised(Colourway c) => Surface(
    borderRadius: AppRadii.cardR,
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: c.cardBorder),
      boxShadow: AppElevation.cardRaised(c),
    ),
    insets: AppElevation.bevel(c),
  );

  /// The one fact on a screen that outranks the rest. Navy, warm-white ink.
  static Surface impact(Colourway c) => Surface(
    borderRadius: AppRadii.cardR,
    decoration: BoxDecoration(
      color: c.impact,
      borderRadius: AppRadii.cardR,
      boxShadow: AppElevation.impact(c),
    ),
    insets: AppElevation.bevelOnImpact(c),
  );

  /// Anything you type into, or a knob slides in.
  static Surface well(Colourway c, {double radius = AppRadii.inner}) {
    final r = BorderRadius.circular(radius);
    return Surface(
      borderRadius: r,
      decoration: BoxDecoration(color: c.well, borderRadius: r),
      insets: AppElevation.well(c),
    );
  }

  /// A text field or a search box. Shallower than a [well].
  static Surface field(Colourway c, {bool hasError = false}) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(
      color: c.well,
      borderRadius: AppRadii.innerR,
      border: hasError ? Border.all(color: c.danger, width: 1.5) : null,
    ),
    insets: AppElevation.field(c),
  );

  /// An inner row, a tab pill, a quiet ground inside a card.
  static Surface subtle(Colourway c, {double radius = AppRadii.inner}) {
    final r = BorderRadius.circular(radius);
    return Surface(
      borderRadius: r,
      decoration: BoxDecoration(color: c.sub, borderRadius: r),
    );
  }

  /// An icon tile, a neutral chip, a quiet row.
  static Surface altWell(Colourway c, {double radius = AppRadii.inner}) {
    final r = BorderRadius.circular(radius);
    return Surface(
      borderRadius: r,
      decoration: BoxDecoration(color: c.altWell, borderRadius: r),
    );
  }

  /// A bottom sheet: rounded on top, its ground a shade below a card.
  static Surface sheet(Colourway c) => Surface(
    borderRadius: AppRadii.sheetR,
    decoration: BoxDecoration(
      color: c.sub,
      borderRadius: AppRadii.sheetR,
      boxShadow: AppElevation.sheet(c),
    ),
  );

  /// The header bar. A hairline below, no shadow: it sits on the tray.
  static Surface headerBar(Colourway c) => Surface(
    borderRadius: BorderRadius.zero,
    decoration: BoxDecoration(
      color: c.bar,
      border: Border(bottom: BorderSide(color: c.barLine)),
    ),
  );

  /// The tab bar. A hairline above, and it casts upward over the content.
  static Surface tabBar(Colourway c) => Surface(
    borderRadius: BorderRadius.zero,
    decoration: BoxDecoration(
      color: c.bar,
      border: Border(top: BorderSide(color: c.barLine)),
      boxShadow: AppElevation.bar(c),
    ),
  );

  /// A counting tile in a domain colour. Neutral tiles use [card].
  static Surface tile(Colourway c, {required Color fill, required Color line}) =>
      Surface(
        borderRadius: AppRadii.innerR,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadii.innerR,
          border: Border.all(color: line),
        ),
        insets: AppElevation.tile(c),
      );

  /// A recessed trough, so its fill reads as sitting inside it.
  static Surface trough(Colourway c) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(color: c.track, borderRadius: AppRadii.pillR),
    insets: AppElevation.track(c),
  );

  /// A toast. Navy, never a coloured slab.
  static Surface toast(Colourway c) => Surface(
    borderRadius: AppRadii.padR,
    decoration: BoxDecoration(
      color: c.impact,
      borderRadius: AppRadii.padR,
      boxShadow: AppElevation.toast(c),
    ),
    insets: AppElevation.bevelOnImpact(c),
  );

  /// An empty state's icon. A well, not a card: there is nothing to press.
  static Surface emptyIcon(Colourway c) => Surface(
    borderRadius: AppRadii.emptyIconR,
    decoration: BoxDecoration(
      color: c.well,
      borderRadius: AppRadii.emptyIconR,
    ),
    insets: AppElevation.well(c),
  );
}
