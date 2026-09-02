import 'package:flutter/widgets.dart';

/// The type ladder, in Poppins.
///
/// Sizes are written as their design `rem` value times [_px] so the number in
/// a `.dc.html` frame is the number in this file: `.93rem` in the design is
/// `.93 * _px` here.
///
/// **These styles carry no colour.** Colour is a [Colourway] decision, and
/// baking a swatch in here is what would stop the D1 colourway from dropping
/// in later. Widgets set it explicitly, which is also what the "colour carries
/// meaning" rule wants: a subline is [subLine] in `ink3`, and saying so out
/// loud at the call site is the point.
///
/// The design's body weight is 600. That is deliberate, not a typo: Poppins at
/// 400 reads too light against these surfaces.
abstract final class AppTextStyles {
  /// The design frames render at a 16px root, so one rem is 16 logical pixels.
  static const double _px = 16;

  static const String fontFamily = 'Poppins';

  /// The big attention figure on a dashboard deck. Sits on its own line.
  static const TextStyle headlineCount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 2.1 * _px,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  /// A module home's title: Attendance, Students, Classrooms, a greeting.
  /// Screen role decides this, never navigation depth — a back arrow is depth.
  static const TextStyle moduleTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 1.28 * _px,
    fontWeight: FontWeight.w600,
    letterSpacing: -.01 * 1.28 * _px,
  );

  /// A one-record screen, a form, a wizard, and every sheet header.
  static const TextStyle detailTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 1.12 * _px,
    fontWeight: FontWeight.w600,
    letterSpacing: -.01 * 1.12 * _px,
  );

  /// The figure on a counting tile.
  static const TextStyle tileNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 1.15 * _px,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  /// A card's own heading. Not a title: "Payment amount", "No classrooms yet".
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: .96 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The person, classroom or record a list row names.
  static const TextStyle rowName = TextStyle(
    fontFamily: fontFamily,
    fontSize: .93 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A primary key's label.
  static const TextStyle keyLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: .87 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A secondary or destructive key's label, a shade smaller than [keyLabel].
  static const TextStyle keyLabelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// What you type into a field, and a segmented control's segments.
  static const TextStyle fieldText = TextStyle(
    fontFamily: fontFamily,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Running text, and a toast.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Initials in an avatar.
  static const TextStyle avatarInitials = TextStyle(
    fontFamily: fontFamily,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A filter chip.
  static const TextStyle chipLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A subline under a title.
  static const TextStyle subLine = TextStyle(
    fontFamily: fontFamily,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A status pill: In Ratio, Signed In, Absent, Not Marked.
  static const TextStyle pillLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The second line of a list row.
  static const TextStyle rowSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A field's label. Its required asterisk is the same size in pink.
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A field's error line.
  static const TextStyle fieldError = TextStyle(
    fontFamily: fontFamily,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A field's helper line.
  static const TextStyle fieldHelp = TextStyle(
    fontFamily: fontFamily,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A section eyebrow. Uppercase, tracked wide.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .13 * .68 * _px,
  );

  /// A counting tile's caption, under its [tileNumber].
  static const TextStyle tileLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A bottom-nav label. Goes to w700 on the active slot.
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The count in an unread badge.
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: .55 * _px,
    fontWeight: FontWeight.w800,
  );
}
