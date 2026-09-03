import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
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
  static Surface tile(
    Colourway c, {
    required Color fill,
    required Color line,
  }) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: AppRadii.innerR,
      border: Border.all(color: line),
    ),
    insets: AppElevation.tile(c),
  );

  /// A neutral counting tile: a card's face at a tile's radius (5a).
  static Surface tileNeutral(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: AppRadii.innerR,
      border: Border.all(color: c.keyBorder),
      boxShadow: AppElevation.iconKey(c),
    ),
    insets: AppElevation.bevel(c),
  );

  /// A recessed trough, so its fill reads as sitting inside it.
  ///
  /// [radius] is half the trough's height: a pill, written as a concrete
  /// number so the clip and the inset painter agree on the shape.
  static Surface trough(Colourway c, {double radius = AppRadii.pill}) {
    final r = BorderRadius.circular(radius);
    return Surface(
      borderRadius: r,
      decoration: BoxDecoration(color: c.track, borderRadius: r),
      insets: AppElevation.track(c),
    );
  }

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
    decoration: BoxDecoration(color: c.well, borderRadius: AppRadii.emptyIconR),
    insets: AppElevation.well(c),
  );

  // --- Keys (Components page `.key--*`, `.iconkey`, `.fab`, `.pinkey`) -------

  /// The pink primary key. [rim] is the rim's current height; see
  /// [AppElevation.keyPrimary]. The bevel shows only once the face has sunk.
  static Surface keyPrimary(Colourway c, {double rim = AppSizes.keyRim}) =>
      Surface(
        borderRadius: AppRadii.innerR,
        decoration: BoxDecoration(
          color: c.pink,
          borderRadius: AppRadii.innerR,
          boxShadow: AppElevation.keyPrimary(c, rim: rim),
        ),
        insets: rim <= AppSizes.keyRimDown
            ? AppElevation.bevelOnPink(c)
            : const <InsetShadow>[],
      );

  /// A secondary key: a card's face at a key's radius, with a key's hairline.
  static Surface keySecondary(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(
      color: c.key,
      borderRadius: AppRadii.innerR,
      border: Border.all(color: c.keyBorder),
      boxShadow: AppElevation.keySecondary(c),
    ),
    insets: AppElevation.bevel(c),
  );

  /// A destructive key. Red face, red rim, no glow.
  static Surface keyDestructive(Colourway c, {double rim = AppSizes.keyRim}) =>
      Surface(
        borderRadius: AppRadii.innerR,
        decoration: BoxDecoration(
          color: c.danger,
          borderRadius: AppRadii.innerR,
          boxShadow: AppElevation.keyDestructive(c, rim: rim),
        ),
      );

  /// A disabled key: well fill, no rim, so it reads flat and dead.
  static Surface keyDisabled(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(color: c.well, borderRadius: AppRadii.innerR),
    insets: AppElevation.keyDisabled(c),
  );

  /// A 38px header icon key, or the 34px back key at its tighter radius.
  static Surface iconKey(
    Colourway c, {
    BorderRadius radius = AppRadii.innerR,
  }) => Surface(
    borderRadius: radius,
    decoration: BoxDecoration(
      color: c.key,
      borderRadius: radius,
      border: Border.all(color: c.keyBorder),
      boxShadow: AppElevation.iconKey(c),
    ),
    insets: AppElevation.bevel(c),
  );

  /// The FAB. [rim] runs from [AppSizes.fabRim] down to zero under a press.
  static Surface fab(Colourway c, {double rim = AppSizes.fabRim}) => Surface(
    borderRadius: AppRadii.fabR,
    decoration: BoxDecoration(
      color: c.pink,
      borderRadius: AppRadii.fabR,
      boxShadow: AppElevation.fab(c, rim: rim),
    ),
    insets: AppElevation.bevelOnPink(c),
  );

  /// A FAB with no permission behind it: recessed, dead, still in place.
  static Surface fabDead(Colourway c) => Surface(
    borderRadius: AppRadii.fabR,
    decoration: BoxDecoration(color: c.well, borderRadius: AppRadii.fabR),
    insets: AppElevation.fabDead(c),
  );

  /// A kiosk pad key. [rim] runs from [AppSizes.keyRim] down to zero.
  static Surface padKey(Colourway c, {double rim = AppSizes.keyRim}) => Surface(
    borderRadius: AppRadii.padR,
    decoration: BoxDecoration(
      color: c.key,
      borderRadius: AppRadii.padR,
      border: Border.all(color: c.keyBorder),
      boxShadow: AppElevation.padKey(c, rim: rim),
    ),
    insets: AppElevation.bevel(c),
  );

  // --- Navigation chrome (Components page `.tabbar__item--on`) --------------

  /// The active tab's tinted tile.
  static Surface tabTileActive(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(color: c.pinkBg, borderRadius: AppRadii.innerR),
    insets: AppElevation.bevel(c),
  );

  /// An unread badge: pink, or red on the bell key.
  static Surface badge(Colourway c, {Color? fill, Color? ring}) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(
      color: fill ?? c.pink,
      borderRadius: AppRadii.pillR,
      border: ring == null
          ? null
          : Border.all(color: ring, width: AppSizes.iconKeyBadgeRing),
    ),
  );

  // --- List (Components page `.avatar`, `.pill`) -----------------------------

  /// An avatar bubble in a domain tint, lit from above. [size] is the
  /// bubble's diameter, so the inset painter draws a true circle.
  static Surface avatar(
    Colourway c, {
    required Color fill,
    required double size,
  }) {
    final r = BorderRadius.circular(size / 2);
    return Surface(
      borderRadius: r,
      decoration: BoxDecoration(color: fill, borderRadius: r),
      insets: AppElevation.avatarBevel(c),
    );
  }

  /// A status pill.
  static Surface pill({required Color fill, Color? line}) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: AppRadii.pillR,
      border: line == null ? null : Border.all(color: line),
    ),
  );

  // --- Switches (Components page `.toggle`, `.segmented`, `.chip`) ----------

  /// A control's recessed ground: the toggle track, the segmented control.
  static Surface track(Colourway c, {BorderRadius radius = AppRadii.pillR}) =>
      Surface(
        borderRadius: radius,
        decoration: BoxDecoration(color: c.track, borderRadius: radius),
        insets: AppElevation.track(c),
      );

  /// A toggle's track once it is on: solid green, no recess.
  static Surface trackOn(Colourway c) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(color: c.success, borderRadius: AppRadii.pillR),
  );

  /// The knob that slides in a toggle's track.
  static Surface knob(Colourway c) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(
      color: c.knob,
      shape: BoxShape.circle,
      boxShadow: AppElevation.knob(c),
    ),
  );

  /// The raised segment of a segmented control.
  static Surface segmentSelected(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: AppRadii.innerR,
      boxShadow: AppElevation.segmentSelected(c),
    ),
    insets: AppElevation.bevel(c),
  );

  /// A filter chip at rest.
  static Surface chip(Colourway c) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: AppRadii.pillR,
      border: Border.all(color: c.keyBorder),
    ),
    insets: AppElevation.bevel(c),
  );

  /// A selected filter chip: navy, with a navy shadow.
  static Surface chipSelected(Colourway c) => Surface(
    borderRadius: AppRadii.pillR,
    decoration: BoxDecoration(
      color: c.ink,
      borderRadius: AppRadii.pillR,
      border: Border.all(color: c.ink),
      boxShadow: AppElevation.chipSelected(c),
    ),
  );

  // --- Choices (1b radio cards) ---------------------------------------------

  /// A radio card. Selected, it fills with the student tint and takes the
  /// student hairline; at rest it is a softer card.
  static Surface radioCard(Colourway c, {required bool selected}) => Surface(
    borderRadius: AppRadii.cardR,
    decoration: BoxDecoration(
      color: selected ? c.studentBg : c.card,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: selected ? c.studentLine : c.cardBorder),
      boxShadow: AppElevation.radioCard(c),
    ),
  );

  // --- Feedback (1a offline banner and rejected sign-in, 5a scope note) -----

  /// The offline banner: a navy strip with a lit top edge.
  static Surface banner(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(color: c.impact, borderRadius: AppRadii.innerR),
    insets: AppElevation.bevelOnImpact(c),
  );

  /// A danger alert: the red tint with its hairline.
  static Surface alertDanger(Colourway c) => Surface(
    borderRadius: AppRadii.innerR,
    decoration: BoxDecoration(
      color: c.dangerBg,
      borderRadius: AppRadii.innerR,
      border: Border.all(color: c.dangerLine),
    ),
  );

  /// An info alert: a quiet note on the alt-well.
  static Surface alertInfo(Colourway c) => altWell(c);
}
