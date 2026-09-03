import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/painters/inset_shadow_painter.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// The shadow recipes, one per material in the design.
///
/// There are no gradients anywhere. Depth comes from three things and only
/// three: a lit bevel along the top edge, a warm-brown shadow falling below,
/// and a navy inset for anything recessed. Light comes from directly above, so
/// the bevel is always on the top edge and the shadow always falls down.
///
/// CSS `0 7px 16px -14px <colour>` becomes
/// `BoxShadow(offset: Offset(0, 7), blurRadius: 16, spreadRadius: -14)`.
abstract final class AppElevation {
  // --- Raised surfaces ------------------------------------------------------

  /// A card lifted off the tray. The everyday raised surface.
  static List<BoxShadow> card(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientLift,
      offset: const Offset(0, 7),
      blurRadius: 16,
      spreadRadius: -14,
    ),
  ];

  /// A card that needs to sit visibly higher: a sheet's header card, a hero.
  static List<BoxShadow> cardRaised(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientDeep,
      offset: const Offset(0, 14),
      blurRadius: 26,
      spreadRadius: -16,
    ),
    BoxShadow(
      color: c.ambientSoft,
      offset: const Offset(0, 3),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// The navy impact card: the one fact on a screen that outranks the rest.
  static List<BoxShadow> impact(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientLift,
      offset: const Offset(0, 14),
      blurRadius: 26,
      spreadRadius: -18,
    ),
  ];

  /// An avatar bubble.
  static List<BoxShadow> avatar(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.avatarShadow,
      offset: const Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -8,
    ),
  ];

  /// A toast. Navy, never a coloured slab.
  static List<BoxShadow> toast(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientLift,
      offset: const Offset(0, 16),
      blurRadius: 30,
      spreadRadius: -18,
    ),
  ];

  // --- Chrome ---------------------------------------------------------------

  /// The tab bar, lifting off the content it covers. Casts upward.
  static List<BoxShadow> bar(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambient,
      offset: const Offset(0, -8),
      blurRadius: 18,
      spreadRadius: -14,
    ),
  ];

  /// A bottom sheet, over a dimmed screen. Casts upward, harder than [bar].
  static List<BoxShadow> sheet(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientLift,
      offset: const Offset(0, -14),
      blurRadius: 30,
      spreadRadius: -18,
    ),
  ];

  // --- Keys -----------------------------------------------------------------

  /// The pink primary key: a solid rim plus its own pink glow.
  ///
  /// [rim] is the rim's height right now. At rest it is [AppSizes.keyRim];
  /// `Pressable` drives it down to [AppSizes.keyRimDown] as the face sinks, so
  /// the rim's bottom edge stays put while the face lands on it. The glow
  /// fades with the rim: a key at full press casts nothing.
  static List<BoxShadow> keyPrimary(
    Colourway c, {
    double rim = AppSizes.keyRim,
  }) => <BoxShadow>[
    BoxShadow(color: c.pinkRim, offset: Offset(0, rim)),
    if (rim > AppSizes.keyRimDown)
      BoxShadow(
        color: c.pinkKeyShadow,
        offset: const Offset(0, 12),
        blurRadius: 22,
        spreadRadius: -14,
      ),
  ];

  /// The primary key at full press: the rim has collapsed from 4px to 1px.
  static List<BoxShadow> keyPrimaryDown(Colourway c) =>
      keyPrimary(c, rim: AppSizes.keyRimDown);

  /// A secondary key. Same face as a card, so it reads as raised, not filled.
  static List<BoxShadow> keySecondary(Colourway c) => card(c);

  /// A destructive key: a red rim, and no glow. Danger does not invite a tap.
  static List<BoxShadow> keyDestructive(
    Colourway c, {
    double rim = AppSizes.keyRim,
  }) => <BoxShadow>[BoxShadow(color: c.dangerFg, offset: Offset(0, rim))];

  static List<BoxShadow> keyDestructiveDown(Colourway c) =>
      keyDestructive(c, rim: AppSizes.keyRimDown);

  /// A 38px icon key in the header bar.
  static List<BoxShadow> iconKey(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientLift,
      offset: const Offset(0, 6),
      blurRadius: 12,
      spreadRadius: -10,
    ),
  ];

  /// The FAB. A 3px rim rather than the key's 4px, so it sinks flush: at
  /// full press [rim] is zero.
  static List<BoxShadow> fab(Colourway c, {double rim = AppSizes.fabRim}) =>
      <BoxShadow>[
        if (rim > 0) BoxShadow(color: c.pinkRim, offset: Offset(0, rim)),
      ];

  /// A kiosk pad key: the deepest rim in the app, on the app's solid key rim.
  /// Sinks flush like the FAB, so at full press [rim] is zero.
  static List<BoxShadow> padKey(Colourway c, {double rim = AppSizes.keyRim}) =>
      <BoxShadow>[
        if (rim > 0) BoxShadow(color: c.keyRim, offset: Offset(0, rim)),
      ];

  /// A radio card (1b). Softer than a card: it is a choice, not content.
  static List<BoxShadow> radioCard(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambient,
      offset: const Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -12,
    ),
  ];

  /// A selected filter chip. Navy, so its shadow is navy too.
  static List<BoxShadow> chipSelected(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ink.withValues(alpha: .9),
      offset: const Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -12,
    ),
  ];

  /// The raised segment of a segmented control.
  static List<BoxShadow> segmentSelected(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambientDeep,
      offset: const Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -8,
    ),
  ];

  /// The knob on a toggle.
  static List<BoxShadow> knob(Colourway c) => <BoxShadow>[
    BoxShadow(
      color: c.ambient,
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  // --- Insets ---------------------------------------------------------------

  /// The lit top bevel. Goes on every raised face.
  static List<InsetShadow> bevel(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.bevel, offset: const Offset(0, 1)),
  ];

  /// The bevel on a navy face, which is warm rather than pure white.
  static List<InsetShadow> bevelOnImpact(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.impactBevel, offset: const Offset(0, 1)),
  ];

  /// The bevel on a pink face.
  static List<InsetShadow> bevelOnPink(Colourway c) => <InsetShadow>[
    InsetShadow(
      color: c.onPink.withValues(alpha: .3),
      offset: const Offset(0, 1),
    ),
  ];

  /// A well: anything you type into, or a knob slides in.
  static List<InsetShadow> well(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.inset, offset: const Offset(0, 3), blur: 6),
    InsetShadow(color: c.wellBevel, offset: const Offset(0, -1)),
  ];

  /// A text field. Shallower than a [well], with no lit bottom edge.
  static List<InsetShadow> field(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.inset, offset: const Offset(0, 2), blur: 5),
  ];

  /// A track, trough or segmented-control ground.
  static List<InsetShadow> track(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.inset, offset: const Offset(0, 2), blur: 4),
  ];

  /// A disabled key. No rim at all, so it reads flat and dead.
  static List<InsetShadow> keyDisabled(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.insetShallow, offset: const Offset(0, 3), blur: 6),
  ];

  /// A key at full press, having sunk onto its own rim.
  static List<InsetShadow> keyDown(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.insetKeyDown, offset: const Offset(0, 2), blur: 5),
  ];

  /// A FAB with no permission behind it: recessed, dead, still in place.
  static List<InsetShadow> fabDead(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.inset, offset: const Offset(0, 3), blur: 7),
    InsetShadow(color: c.wellBevel, offset: const Offset(0, -1)),
  ];

  /// A counting tile, whose bevel is warm because its ground is a tint.
  static List<InsetShadow> tile(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.onImpactSoft, offset: const Offset(0, 1)),
  ];

  /// An avatar bubble's inner light.
  static List<InsetShadow> avatarBevel(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.onImpactSub, offset: const Offset(0, 1)),
  ];

  /// A pressed icon key, sunk into its own socket (3A1 header keys).
  static List<InsetShadow> iconKeyDown(Colourway c) => <InsetShadow>[
    InsetShadow(color: c.inset, offset: const Offset(0, 3), blur: 6),
    InsetShadow(color: c.wellBevel, offset: const Offset(0, -1)),
  ];
}
