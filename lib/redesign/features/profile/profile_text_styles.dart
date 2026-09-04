import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type sizes the M13 frames draw that are not on the core ladder. Sizes are
/// the frame's rem value times 16, like `AppTextStyles`. No colour here.
abstract final class ProfileTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  // --- Hero card ------------------------------------------------------------

  /// The initials in the 76px staff hero avatar: `1.35rem 700`.
  static const TextStyle heroInitials = TextStyle(
    fontFamily: _font,
    fontSize: 1.35 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in the 70px guardian hero avatar: `1.25rem 700`.
  static const TextStyle guardianHeroInitials = TextStyle(
    fontFamily: _font,
    fontSize: 1.25 * _px,
    fontWeight: FontWeight.w700,
  );

  /// "Director · Maple View" under the name: `.78rem 600`.
  static const TextStyle heroRole = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
  );

  /// "Loaded just now", "Saved on this phone · 9:02 AM": `.72rem 700`.
  static const TextStyle heroNote = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A role chip in the hero, and the "Admin only" lock chip: `.63rem 800`.
  static const TextStyle roleChip = TextStyle(
    fontFamily: _font,
    fontSize: .63 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The "Cannot be edited" tag beside a field label: `.6rem 800`.
  static const TextStyle tinyTag = TextStyle(
    fontFamily: _font,
    fontSize: .6 * _px,
    fontWeight: FontWeight.w800,
  );

  // --- Photo upload ---------------------------------------------------------

  /// "Uploading": `.76rem 700`.
  static const TextStyle uploadLabel = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The percentage beside it: `.76rem 800`.
  static const TextStyle uploadPercent = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The title inside a tinted alert block: `.78rem 700`.
  static const TextStyle alertTitle = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Its body: `.74rem 500`, line-height 1.45.
  static const TextStyle alertBody = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // --- Cards ----------------------------------------------------------------

  /// A card's own heading on these frames: `.9rem 600`.
  static const TextStyle cardHeading = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A field's value in a read-only well: `.85rem 600`, line-height 1.45.
  static const TextStyle valueText = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // --- Work schedule --------------------------------------------------------

  /// A weekday chip: `.63rem 800`.
  static const TextStyle dayChip = TextStyle(
    fontFamily: _font,
    fontSize: .63 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The shift hours in the schedule well: `.82rem 700`.
  static const TextStyle hoursValue = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The break beside them: `.7rem 700`.
  static const TextStyle breakValue = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The small pill key on a card header ("Edit"): `.66rem 800`.
  static const TextStyle pillKey = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w800,
  );

  // --- Actions card ---------------------------------------------------------

  /// An action row's label, and a child's name: `.83rem 600`.
  static const TextStyle actionRow = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The PIN itself, tracked wide: `.85rem 800`.
  static const TextStyle pinValue = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .14 * .85 * _px,
  );

  /// The Show / Hide chip after it: `.62rem 800`.
  static const TextStyle pinChip = TextStyle(
    fontFamily: _font,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w800,
  );

  // --- Guardian children ----------------------------------------------------

  /// "Bluebell · Signed In 9:12 AM": `.7rem 600`.
  static const TextStyle childSub = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The "Open" pill at the end of a child's row: `.68rem 700`.
  static const TextStyle openPill = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a child's 36px avatar: `.7rem 800`.
  static const TextStyle childInitials = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w800,
  );

  // --- Notification settings ------------------------------------------------

  /// A channel column heading: `.66rem 800`.
  static const TextStyle prefColumn = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A category band's label: `.66rem 800`, tracked wide, uppercase.
  static const TextStyle prefCategory = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .12 * .66 * _px,
  );

  /// A group's title: `.8rem 600`, line-height 1.3.
  static const TextStyle prefTitle = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// The description under it, which the shipped app returns and ignores:
  /// `.68rem 500`, line-height 1.35.
  static const TextStyle prefDescription = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  /// The dash in a channel a group does not offer: `.6rem 800`.
  static const TextStyle notOfferedMark = TextStyle(
    fontFamily: _font,
    fontSize: .6 * _px,
    fontWeight: FontWeight.w800,
  );

  // --- Failed state (13f) ---------------------------------------------------

  /// "Failed to load profile": `1.05rem 600`.
  static const TextStyle failedTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1.05 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its body: `.79rem 500`, line-height 1.5.
  static const TextStyle failedBody = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
}
