import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type sizes the M04 frames draw that are not on the core ladder. Sizes are
/// the frame's rem value times 16, like `AppTextStyles`. No colour here.
abstract final class AttendanceTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  /// The date in the day strip, and a range's dates: `.84rem 700`.
  static const TextStyle stripValue = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A small key beside a value: Change, Clear all: `.7rem 700`.
  static const TextStyle stripKey = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A label in an open record: `.72rem 600`.
  static const TextStyle detailLabel = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its value, right aligned: `.79rem 600`, line-height 1.4.
  static const TextStyle detailValue = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// A card's own title on 4c and 4d: `.9rem 700`.
  static const TextStyle noticeTitle = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Its body: `.78rem 600`, line-height 1.5.
  static const TextStyle noticeBody = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// The recessed scope note's title: `.76rem 700`.
  static const TextStyle noteTitle = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Its body, and any footnote: `.71rem 600`, line-height 1.45.
  static const TextStyle footnote = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// The headline on the navy self card and a guardian's child card:
  /// `1.05rem 600`.
  static const TextStyle heroLine = TextStyle(
    fontFamily: _font,
    fontSize: 1.05 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The line under it: `.76rem 600`.
  static const TextStyle heroSub = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The geofence line inside the navy card: `.73rem 600`, line-height 1.4.
  static const TextStyle heroNote = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// A key inside the navy card: `.76rem 700`.
  static const TextStyle heroKey = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// An edge card's title: `1.05rem 600`.
  static const TextStyle edgeTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1.05 * _px,
    fontWeight: FontWeight.w600,
  );

  /// An edge card's body: `.86rem 600`, line-height 1.5.
  static const TextStyle edgeBody = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// A day option's title in the day sheet: `.9rem 700`.
  static const TextStyle optionTitle = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Its sub-line: `.72rem 600`.
  static const TextStyle optionSub = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A range row's name: `.86rem 600`.
  static const TextStyle rangeName = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The classroom beside it: `.78rem 600`.
  static const TextStyle rangeScope = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A total's label in an open range row: `.76rem 600`.
  static const TextStyle totalLabel = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The total itself: `.84rem 700`.
  static const TextStyle totalValue = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a 46px or 50px avatar: `.85rem 700`.
  static const TextStyle bigInitials = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a 38px range or tile avatar: `.72rem 700`.
  static const TextStyle smallInitials = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A sheet note's eyebrow: `.72rem 800`, tracked.
  static const TextStyle sheetNoteEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .1 * .72 * _px,
  );

  /// A sheet note's body: `.78rem 600`, line-height 1.45.
  static const TextStyle sheetNoteBody = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// A person tile's name on the two forms: `.85rem 600`.
  static const TextStyle tileName = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A guardian day row's date: `.9rem 600`.
  static const TextStyle dayName = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its detail line: `.72rem 600`.
  static const TextStyle daySub = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );
}
