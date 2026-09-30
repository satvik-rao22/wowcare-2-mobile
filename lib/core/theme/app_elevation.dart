/// Depth, in the flat skeuomorphic material.
///
/// Rule 3 of the ChildcareWow design language: **no gradients**. Every fill is
/// a single flat colour, and an object reads as an object because of four
/// things instead:
///
/// | | What it is | Where it comes from |
/// |---|---|---|
/// | **Bevel** | a 1px lit line on the *top* edge | [bevelTop], [bevelGloss] |
/// | **Ambient** | a soft warm shadow *below* | [card], [iconKey], [impact] |
/// | **Well** | an inset shadow, for anything recessed | [well], [wellShallow] |
/// | **Rim** | a solid, un-blurred under-edge you press away | [rimAction] and friends |
///
/// Light always comes from directly above. That is the whole grammar: a lit
/// top edge and a shadow below means raised; a dark top edge and a lit bottom
/// edge means cut in.
///
/// Every value is transcribed from the `03 Components` specimens in
/// *WowCare Design Components*, which is the reference developers read. The
/// colours come from [AppPalette]; only the geometry and the alphas live here.
///
/// Flutter has no inset [BoxShadow], so the inset half of each recipe is a
/// `List<AppInset>` painted by [SkeuInnerShadow] rather than a `List<BoxShadow>`.
/// [AppSurfaces] pairs the two for you — prefer its builders to reaching in
/// here directly.
library;

import 'package:flutter/widgets.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// One CSS-style `inset` shadow.
///
/// The counterpart to [BoxShadow], which Flutter only paints outward. Rendered
/// by `SkeuInnerShadow` in `lib/core/theme/skeu_inner_shadow.dart`.
@immutable
class AppInset {
  const AppInset({
    required this.color,
    this.offset = Offset.zero,
    this.blur = 0,
    this.spread = 0,
  });

  /// The shadow colour, alpha included.
  final Color color;

  /// How far the shadow is pushed from the edge. Positive `dy` throws the
  /// shadow downward from the top edge, which is what a well looks like.
  final Offset offset;

  /// CSS `blur-radius`. Zero draws a hard line.
  final double blur;

  /// CSS `spread-radius`. With a zero blur and offset this is an inside
  /// stroke, i.e. `inset 0 0 0 Npx <color>`.
  final double spread;

  @override
  bool operator ==(Object other) =>
      other is AppInset &&
      other.color == color &&
      other.offset == offset &&
      other.blur == blur &&
      other.spread == spread;

  @override
  int get hashCode => Object.hash(color, offset, blur, spread);
}

/// The shadow and bevel recipes of the flat skeuomorphic material.
class AppElevation {
  AppElevation._();

  // ── Shadow tints ─────────────────────────────────────────────────────────

  /// The warm ambient tint at a given alpha.
  static Color _warm(double a) => AppPalette.shadowAmbient.withValues(alpha: a);

  /// The navy inset tint at a given alpha.
  static Color _ink(double a) => AppPalette.shadowInset.withValues(alpha: a);

  /// The white bevel at a given alpha (on a light face).
  static Color _lit(double a) => AppPalette.bevelLit.withValues(alpha: a);

  /// The warm-white bevel at a given alpha (on a dark face).
  static Color _gloss(double a) => AppPalette.bevelGloss.withValues(alpha: a);

  // ── Rim geometry ─────────────────────────────────────────────────────────

  /// How deep a key's rim sits at rest, in logical pixels.
  static const double rimDepth = 4;

  /// How deep it sits while pressed. The 3px difference is exactly
  /// [AppMotion.pressTravel], so the face lands on the rim rather than past
  /// it.
  static const double rimDepthPressed = 1;

  /// The FAB's rim, which is shallower than a key's: it is a small square
  /// button and a 4px rim reads as a slab.
  static const double rimDepthFab = 3;

  /// A solid, un-blurred under-edge — the side of the key you can see until
  /// you push it away. Not a border and not a blur: `0 Npx 0 <colour>`.
  static List<BoxShadow> rim(Color colour, {double depth = rimDepth}) =>
      <BoxShadow>[BoxShadow(color: colour, offset: Offset(0, depth))];

  // ── Raised: bevel above, ambient below ───────────────────────────────────

  /// The lit top edge of a light face. `inset 0 1px 0 rgba(255,255,255,.95)`.
  static List<AppInset> get bevelTop => <AppInset>[
    AppInset(color: _lit(.95), offset: const Offset(0, 1)),
  ];

  /// The lit top edge of a dark face — an impact card, a toast, a navy chip.
  /// `inset 0 1px 0 rgba(255,250,240,.22)`.
  static List<AppInset> get bevelGloss => <AppInset>[
    AppInset(color: _gloss(.22), offset: const Offset(0, 1)),
  ];

  /// The lit top edge of a small saturated face: a FAB, an active nav tile.
  /// `inset 0 1px 0 rgba(255,250,240,.3)`.
  static List<AppInset> get bevelColoured => <AppInset>[
    AppInset(color: _gloss(.3), offset: const Offset(0, 1)),
  ];

  /// The brighter bevel on a tinted avatar.
  /// `inset 0 1px 0 rgba(255,250,240,.7)`.
  static List<AppInset> get bevelSoft => <AppInset>[
    AppInset(color: _gloss(.7), offset: const Offset(0, 1)),
  ];

  /// A card at rest: `0 7px 16px -14px rgba(63,45,20,.6)`.
  static List<BoxShadow> get card => <BoxShadow>[
    BoxShadow(
      color: _warm(.6),
      offset: const Offset(0, 7),
      blurRadius: 16,
      spreadRadius: -14,
    ),
  ];

  /// A card being pressed: the same shadow pulled in close, so the surface
  /// reads as having moved toward the ground rather than away from it.
  /// `0 2px 6px -6px rgba(63,45,20,.6)`.
  static List<BoxShadow> get cardPressed => <BoxShadow>[
    BoxShadow(
      color: _warm(.6),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -6,
    ),
  ];

  /// A larger panel that has to separate from a busy ground:
  /// `0 10px 24px -22px rgba(63,45,20,.5)`.
  static List<BoxShadow> get panel => <BoxShadow>[
    BoxShadow(
      color: _warm(.5),
      offset: const Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -22,
    ),
  ];

  /// A 34–38px icon key: `0 6px 12px -10px rgba(63,45,20,.6)`.
  static List<BoxShadow> get iconKey => <BoxShadow>[
    BoxShadow(
      color: _warm(.6),
      offset: const Offset(0, 6),
      blurRadius: 12,
      spreadRadius: -10,
    ),
  ];

  /// The navy impact card: `0 14px 26px -18px rgba(63,45,20,.6)`.
  static List<BoxShadow> get impact => <BoxShadow>[
    BoxShadow(
      color: _warm(.6),
      offset: const Offset(0, 14),
      blurRadius: 26,
      spreadRadius: -18,
    ),
  ];

  /// A toast: the impact shadow, thrown a little further.
  static List<BoxShadow> get toast => <BoxShadow>[
    BoxShadow(
      color: _warm(.6),
      offset: const Offset(0, 16),
      blurRadius: 30,
      spreadRadius: -18,
    ),
  ];

  /// A bottom sheet, whose shadow is thrown *upward* onto the screen it
  /// covers: `0 -14px 30px -18px rgba(63,45,20,.6)`.
  static List<BoxShadow> get sheet => <BoxShadow>[
    BoxShadow(
      color: _warm(.6),
      offset: const Offset(0, -14),
      blurRadius: 30,
      spreadRadius: -18,
    ),
  ];

  /// A bottom nav bar or a docked footer: the same, at half the throw.
  static List<BoxShadow> get bar => <BoxShadow>[
    BoxShadow(
      color: _warm(.5),
      offset: const Offset(0, -8),
      blurRadius: 20,
      spreadRadius: -16,
    ),
  ];

  /// The selected segment of a segmented control:
  /// `0 4px 10px -8px rgba(63,45,20,.5)`.
  static List<BoxShadow> get segmentSelected => <BoxShadow>[
    BoxShadow(
      color: _warm(.5),
      offset: const Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -8,
    ),
  ];

  /// A toggle knob: `0 2px 4px -1px rgba(63,45,20,.45)`.
  static List<BoxShadow> get knob => <BoxShadow>[
    BoxShadow(
      color: _warm(.45),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  /// The coloured halo under a key, which is tinted with the key's own fill
  /// rather than with the ambient brown: `0 12px 22px -14px <fill @ .8>`.
  static List<BoxShadow> keyGlow(Color fill) => <BoxShadow>[
    BoxShadow(
      color: fill.withValues(alpha: .8),
      offset: const Offset(0, 12),
      blurRadius: 22,
      spreadRadius: -14,
    ),
  ];

  /// The tight shadow under a selected navy chip:
  /// `0 6px 14px -12px rgba(10,28,93,.9)`.
  static List<BoxShadow> get chipSelected => <BoxShadow>[
    BoxShadow(
      color: _ink(.9),
      offset: const Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -12,
    ),
  ];

  // ── Recessed: cut into the surface ───────────────────────────────────────

  /// The full well — dropdowns, empty-state icons, disabled FABs:
  /// `inset 0 3px 6px rgba(10,28,93,.14), inset 0 -1px 0 rgba(255,255,255,.8)`.
  static List<AppInset> get well => <AppInset>[
    AppInset(color: _ink(.14), offset: const Offset(0, 3), blur: 6),
    AppInset(color: _lit(.8), offset: const Offset(0, -1)),
  ];

  /// A shallower well, for a field or a search box you type into:
  /// `inset 0 2px 5px rgba(10,28,93,.14)`.
  static List<AppInset> get wellShallow => <AppInset>[
    AppInset(color: _ink(.14), offset: const Offset(0, 2), blur: 5),
  ];

  /// The shallowest — a toggle track, a progress trough, a segmented rest:
  /// `inset 0 2px 4px rgba(10,28,93,.14)`.
  static List<AppInset> get trough => <AppInset>[
    AppInset(color: _ink(.14), offset: const Offset(0, 2), blur: 4),
  ];

  /// A disabled key: recessed just enough to read as dead, with no lit
  /// bottom edge. `inset 0 3px 6px rgba(10,28,93,.13)`.
  static List<AppInset> get keyDisabled => <AppInset>[
    AppInset(color: _ink(.13), offset: const Offset(0, 3), blur: 6),
  ];

  /// A dead FAB: still in place, plainly unpressable.
  /// `inset 0 3px 7px rgba(10,28,93,.14), inset 0 -1px 0 rgba(255,255,255,.8)`.
  static List<AppInset> get fabDead => <AppInset>[
    AppInset(color: _ink(.14), offset: const Offset(0, 3), blur: 7),
    AppInset(color: _lit(.8), offset: const Offset(0, -1)),
  ];
}
