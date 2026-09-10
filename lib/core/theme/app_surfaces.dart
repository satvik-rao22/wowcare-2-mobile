/// The flat skeuomorphic material, as ready-made decorations.
///
/// One builder per specimen in `03 Components` of *WowCare Design Components*.
/// A widget swaps its `decoration:` for one of these and gets the fill, the
/// bevel, the well, the rim and the ambient shadow together — no extra
/// wrapper, no change to the widget tree, no shift in layout.
///
/// ```dart
/// Container(
///   decoration: AppSurfaces.card(),   // was: BoxDecoration(color: …, boxShadow: …)
///   child: …,                          // unchanged
/// )
/// ```
///
/// The grammar, in one line each:
///
/// * **card** — raised off the tray. Lit top edge, hairline, warm shadow below.
/// * **sub** — an inner tinted region. One step down, not yet a well.
/// * **well / field / trough** — cut *into* the surface. Anything you type
///   into, any track something slides along.
/// * **key** — a face sitting on a solid rim you press away.
/// * **impact** — navy, warm-white ink. At most one per screen.
///
/// Rule 3: nothing here is ever a gradient.
library;

import 'package:flutter/widgets.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';

/// The rimmed keys, by role. Exactly one [primary] per screen, and it is the
/// recommended action.
enum KeyVariant {
  /// Pink, warm-white label, pink rim. THE recommended action.
  primary,

  /// Card-faced, navy label, hairline border. A quiet peer action.
  secondary,

  /// Teal, warm-white label. A minor action that is not the recommended one.
  tertiary,

  /// Danger red, warm-white label. Delete, remove, revoke.
  destructive,

  /// Card-faced with a solid neutral rim: kiosk digits, number pads.
  neutral,

  /// Recessed and rimless, so it reads flat and dead rather than hidden.
  disabled,
}

/// The tones a pill, a tint chip or a domain-coded avatar can take.
///
/// [student] and [staff] are **domain** colours, not decoration: on an
/// attendance or classroom screen the teal/sun split is how a child's row
/// reads apart from an adult's. Do not use them for anything else.
enum AppTone {
  /// Green: signed in, on track, paid.
  success,

  /// Sun: due soon, needs attention, nothing has failed.
  warning,

  /// Danger: absent, over ratio, overdue.
  danger,

  /// Teal: informational, and **anything about a child**.
  student,

  /// Sun, darker ink: **anything about a member of staff**.
  staff,

  /// Pink: the recommended action, the active slot.
  action,

  /// The quiet default — no status at all.
  neutral,
}

/// The fill and ink a tone resolves to. Both halves come from the same place
/// so a pill can never end up with unreadable text.
extension AppToneColours on AppTone {
  /// The tinted fill behind the label.
  Color get fill => switch (this) {
    AppTone.success => AppPalette.statusSuccessSoft,
    AppTone.warning => AppPalette.statusWarningSoft,
    AppTone.danger => AppPalette.statusErrorSoft,
    AppTone.student => BrandRamps.tealTint,
    AppTone.staff => BrandRamps.sunTint,
    AppTone.action => BrandRamps.pinkTint,
    AppTone.neutral => AppPalette.surfaceMuted,
  };

  /// The label colour that sits on [fill].
  Color get ink => switch (this) {
    AppTone.success => BrandRamps.green700,
    AppTone.warning => BrandRamps.sunText,
    AppTone.danger => AppPalette.statusErrorStrong,
    AppTone.student => BrandRamps.teal700,
    AppTone.staff => BrandRamps.sunText,
    AppTone.action => AppPalette.brandDark,
    AppTone.neutral => AppPalette.textSecondary,
  };

  /// The saturated tone itself, for a dot, a bar fill or a rule.
  Color get solid => switch (this) {
    AppTone.success => AppPalette.statusSuccess,
    AppTone.warning => AppPalette.statusWarning,
    AppTone.danger => AppPalette.statusError,
    AppTone.student => BrandRamps.teal700,
    AppTone.staff => AppPalette.actionHighlight,
    AppTone.action => AppPalette.brand,
    AppTone.neutral => AppPalette.textMuted,
  };
}

/// Decoration builders for every surface in the material.
class AppSurfaces {
  AppSurfaces._();

  /// The hairline round a card: translucent navy, not a grey line.
  static Border get _hairline => Border.all(color: AppPalette.borderHairline);

  static Border get _edge => Border.all(color: AppPalette.border);

  /// A bar's single lit edge, on the side facing the content it covers.
  static Border get _topHairline =>
      Border(top: BorderSide(color: AppPalette.borderHairline));

  // ── Raised ───────────────────────────────────────────────────────────────

  /// Anything raised off the tray: a card, a list row, a section panel.
  ///
  /// `radius 20 · #FBFCFF · hairline · lit top bevel · warm ambient shadow`
  static SkeuDecoration card({
    double radius = AppRadius.xl,
    Color? color,
    bool bordered = true,
  }) => SkeuDecoration(
    color: color ?? AppPalette.surfaceCard,
    borderRadius: BorderRadius.circular(radius),
    border: bordered ? _hairline : null,
    boxShadow: AppElevation.card,
    insets: AppElevation.bevelTop,
  );

  /// A wider panel that has to separate from a busy ground — the same face,
  /// a longer shadow.
  static SkeuDecoration panel({double radius = AppRadius.r22}) =>
      card(radius: radius).copyWith(boxShadow: AppElevation.panel);

  /// The one fact on the screen that outranks the rest. Navy, warm-white ink,
  /// a gloss bevel. **At most one per screen.**
  ///
  /// `radius 20 · #0A1C5D · inset gloss · warm ambient shadow`
  static SkeuDecoration impact({double radius = AppRadius.xl}) =>
      SkeuDecoration(
        color: AppPalette.surfaceInverse,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppElevation.impact,
        insets: AppElevation.bevelGloss,
      );

  /// A navy toast. Never a coloured slab: the tone is carried by a dot.
  static SkeuDecoration toast() => SkeuDecoration(
    color: AppPalette.surfaceInverse,
    borderRadius: AppRadius.allR18,
    boxShadow: AppElevation.toast,
    insets: AppElevation.bevelGloss,
  );

  /// An inner tinted region: a nested row, a chip strip, a grouped block.
  /// One step down from [card], and flat — it is not raised, so it has no
  /// bevel and casts no shadow.
  static SkeuDecoration sub({
    double radius = AppRadius.r18,
    bool bordered = false,
  }) => SkeuDecoration(
    color: AppPalette.surfaceSunken,
    borderRadius: BorderRadius.circular(radius),
    border: bordered ? _hairline : null,
  );

  /// The tray itself: a scaffold, a drawer, a nav bar, a tab strip.
  static SkeuDecoration tray({double radius = 0}) => SkeuDecoration(
    color: AppPalette.surfacePage,
    borderRadius: BorderRadius.circular(radius),
  );

  /// A docked bottom bar: the tray, a hairline along its top edge, and its
  /// ambient shadow thrown upward onto the content it covers.
  ///
  /// Pass [topRadius] for a bar whose top corners are rounded. The hairline
  /// then runs the whole way round, because Flutter can only follow a corner
  /// radius with a uniform border — at 1px and 7% alpha the three edges you
  /// gain sit on the screen's own edges and do not read.
  static SkeuDecoration bar({double topRadius = 0}) => SkeuDecoration(
    color: AppPalette.surfacePage,
    borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
    border: topRadius > 0 ? _hairline : _topHairline,
    boxShadow: AppElevation.bar,
  );

  /// A bottom sheet: the sub ground, 28 at the top and 42 at the bottom so it
  /// meets the device's own corners, shadow thrown upward.
  static SkeuDecoration sheet() => SkeuDecoration(
    color: AppPalette.surfaceSunken,
    borderRadius: AppRadius.sheet,
    boxShadow: AppElevation.sheet,
  );

  // ── Recessed ─────────────────────────────────────────────────────────────

  /// A dropdown, a read-only value, an empty-state icon: the full well.
  ///
  /// `radius 16 · #E5EAF7 · inset shadow from the top · lit bottom edge`
  static SkeuDecoration well({double radius = AppRadius.lg, Color? color}) =>
      SkeuDecoration(
        color: color ?? AppPalette.surfaceField,
        borderRadius: BorderRadius.circular(radius),
        insets: AppElevation.well,
      );

  /// A text field or a search box — the shallower well, so the caret and the
  /// text do not sit in a hole.
  ///
  /// Pass [error] to add the 1.5px danger edge the design specifies.
  static SkeuDecoration field({
    double radius = AppRadius.lg,
    bool error = false,
  }) => SkeuDecoration(
    color: AppPalette.surfaceField,
    borderRadius: BorderRadius.circular(radius),
    border: error
        ? Border.all(color: AppPalette.statusError, width: 1.5)
        : null,
    insets: AppElevation.wellShallow,
  );

  /// A progress trough, a toggle track, a ring track. Recessed, so the fill
  /// reads as being *inside* it.
  static SkeuDecoration trough({double radius = AppRadius.pill}) =>
      SkeuDecoration(
        color: AppPalette.surfaceField,
        borderRadius: BorderRadius.circular(radius),
        insets: AppElevation.trough,
      );

  /// The rest state of a segmented control: a well the selected peer sits in.
  static SkeuDecoration segmented() => SkeuDecoration(
    color: AppPalette.surfaceField,
    borderRadius: AppRadius.allLg,
    insets: AppElevation.trough,
  );

  /// The selected peer of a segmented control: a small card lifted out of it.
  static SkeuDecoration segmentSelected() => SkeuDecoration(
    color: AppPalette.surfaceCard,
    borderRadius: AppRadius.allLg,
    boxShadow: AppElevation.segmentSelected,
    insets: AppElevation.bevelTop,
  );

  // ── Keys ─────────────────────────────────────────────────────────────────

  /// A key: a face on a solid rim you press away.
  ///
  /// Pair with `SkeuPressable.key`, which sinks the 3px the rim collapses by,
  /// and with [keyPressed] for the sunk state.
  static SkeuDecoration key(
    KeyVariant variant, {
    double radius = AppRadius.lg,
  }) => switch (variant) {
    KeyVariant.primary => SkeuDecoration(
      color: AppPalette.brand,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: <BoxShadow>[
        ...AppElevation.rim(AppPalette.rimAction),
        ...AppElevation.keyGlow(AppPalette.brand),
      ],
    ),
    KeyVariant.secondary => SkeuDecoration(
      color: AppPalette.surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      border: _edge,
      boxShadow: AppElevation.card,
      insets: AppElevation.bevelTop,
    ),
    KeyVariant.tertiary => SkeuDecoration(
      color: AppPalette.actionSecondary,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: <BoxShadow>[
        ...AppElevation.rim(AppPalette.rimSecondary),
        ...AppElevation.keyGlow(AppPalette.actionSecondary),
      ],
    ),
    KeyVariant.destructive => SkeuDecoration(
      color: AppPalette.statusError,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppElevation.rim(AppPalette.rimDestructive),
    ),
    KeyVariant.neutral => SkeuDecoration(
      color: AppPalette.surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      border: _edge,
      boxShadow: AppElevation.rim(AppPalette.rimNeutral),
      insets: AppElevation.bevelTop,
    ),
    KeyVariant.disabled => SkeuDecoration(
      color: AppPalette.surfaceField,
      borderRadius: BorderRadius.circular(radius),
      insets: AppElevation.keyDisabled,
    ),
  };

  /// The same key with its rim collapsed to 1px — what you paint while the
  /// face is translated down by [AppMotion.pressTravel].
  ///
  /// Only the rimmed variants change. A secondary key has no rim to collapse,
  /// so it just sinks the 2px of `SkeuPressable.surface`, and a disabled key
  /// does not respond at all.
  static SkeuDecoration keyPressed(
    KeyVariant variant, {
    double radius = AppRadius.lg,
  }) {
    final SkeuDecoration rest = key(variant, radius: radius);
    return switch (variant) {
      KeyVariant.secondary || KeyVariant.disabled => rest,
      _ => rest.copyWith(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: rest.boxShadow.first.color,
            offset: const Offset(0, AppElevation.rimDepthPressed),
          ),
        ],
      ),
    };
  }

  /// The label colour a [KeyVariant]'s face takes.
  static Color keyInk(KeyVariant variant) => switch (variant) {
    KeyVariant.primary ||
    KeyVariant.tertiary ||
    KeyVariant.destructive => AppPalette.onBrand,
    KeyVariant.secondary || KeyVariant.neutral => AppPalette.textPrimary,
    KeyVariant.disabled => AppPalette.textMuted,
  };

  /// A 34–38px square icon key: a back arrow, a filter, an overflow menu.
  ///
  /// `38x38 · radius 16 · #FBFCFF · hairline · lit bevel · sinks 2px`
  static SkeuDecoration iconKey({double radius = AppRadius.lg}) =>
      SkeuDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: _edge,
        boxShadow: AppElevation.iconKey,
        insets: AppElevation.bevelTop,
      );

  /// The floating action button: a square pink key with a shallow rim.
  ///
  /// Pass `enabled: false` for the no-permission state — recessed and
  /// plainly dead, but **still in place**. It is never hidden.
  static SkeuDecoration fab({bool enabled = true}) => enabled
      ? SkeuDecoration(
          color: AppPalette.brand,
          borderRadius: AppRadius.allR14,
          boxShadow: AppElevation.rim(
            AppPalette.rimAction,
            depth: AppElevation.rimDepthFab,
          ),
          insets: AppElevation.bevelColoured,
        )
      : SkeuDecoration(
          color: AppPalette.surfaceField,
          borderRadius: AppRadius.allR14,
          insets: AppElevation.fabDead,
        );

  // ── Small things ─────────────────────────────────────────────────────────

  /// A status pill. Flat tint, no shadow: it is a label, not an object.
  /// Take its text colour from the same tone, via [AppToneColours.ink].
  static SkeuDecoration pill(AppTone tone) =>
      SkeuDecoration(color: tone.fill, borderRadius: AppRadius.allPill);

  /// A filter chip at rest: card-faced, hairline, lit bevel.
  static SkeuDecoration chip() => SkeuDecoration(
    color: AppPalette.surfaceCard,
    borderRadius: AppRadius.allPill,
    border: _edge,
    insets: AppElevation.bevelTop,
  );

  /// A filter chip once it is on: navy, warm-white label.
  static SkeuDecoration chipSelected() => SkeuDecoration(
    color: AppPalette.surfaceInverse,
    borderRadius: AppRadius.allPill,
    boxShadow: AppElevation.chipSelected,
  );

  /// A domain-coded avatar: teal for a child, sun for a member of staff.
  static SkeuDecoration avatar(AppTone tone) => SkeuDecoration(
    color: tone.fill,
    shape: BoxShape.circle,
    insets: AppElevation.bevelSoft,
  );

  /// The raised knob of a toggle or a slider.
  static SkeuDecoration knob() => SkeuDecoration(
    color: AppPalette.surfaceCard,
    shape: BoxShape.circle,
    boxShadow: AppElevation.knob,
  );

  /// The active slot in the bottom bar or the drawer: a solid pink squircle.
  ///
  /// The design components page shows a `#FBDEE9` tint here; this app uses
  /// the solid fill instead, which is a deliberate override recorded in
  /// `docs/redesign-flat-skeu-plan.md`.
  static SkeuDecoration navActive({double radius = AppRadius.lg}) =>
      SkeuDecoration(
        color: AppPalette.brand,
        borderRadius: BorderRadius.circular(radius),
        insets: AppElevation.bevelColoured,
      );

  /// The 64x64 well behind an empty state's icon. A well, not a card:
  /// there is nothing here to press.
  static SkeuDecoration emptyIcon() => SkeuDecoration(
    color: AppPalette.surfaceField,
    borderRadius: AppRadius.allR22,
    insets: AppElevation.well,
  );
}
