import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type the M06 frames draw that is not on the core ladder.
///
/// Sizes are the frame's own rem value times 16, exactly as `AppTextStyles`
/// writes them, and letter spacing is the em value times the size, so the
/// number in a frame is the number here. No colour: colour is a `Colourway`
/// decision the call site makes out loud.
abstract final class StaffTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  // --- 6a ---------------------------------------------------------------------

  /// The Select key in the header bar.
  static const TextStyle headerKey = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
  );

  /// An expanded row's left-hand label, and its right-hand value.
  static const TextStyle factLabel = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle factValue = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// The two keys at the foot of an expanded row.
  static const TextStyle rowActionKey = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The docked bulk key in select mode.
  static const TextStyle bulkKey = TextStyle(
    fontFamily: _font,
    fontSize: .87 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle quietKey = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 6a sheet · 6f -----------------------------------------------------------

  /// The two-letter glyph in an action row's tile.
  static const TextStyle actionGlyph = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle actionLabel = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle actionNote = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The initials in a sheet's 48px bubble.
  static const TextStyle sheetInitials = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle sheetSub = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle sheetKey = TextStyle(
    fontFamily: _font,
    fontSize: .93 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A "What changes today" row: what it is, then what becomes of it.
  static const TextStyle changeLabel = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle changeValue = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The sun-tinted warning above 6f's key.
  static const TextStyle warning = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // --- 6b ---------------------------------------------------------------------

  /// A pick-one key in the filter sheet: Active, Upcoming, A to Z.
  static const TextStyle choiceKey = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle sheetNote = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // --- 6c ---------------------------------------------------------------------

  /// The initials in the 52px header bubble.
  static const TextStyle headInitials = TextStyle(
    fontFamily: _font,
    fontSize: .88 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headSub = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w600,
  );

  /// One tab in the profile's strip.
  static const TextStyle tabLabel = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A card's own heading on the profile, and the small key beside it.
  static const TextStyle cardHeading = TextStyle(
    fontFamily: _font,
    fontSize: .95 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle smallKey = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The quiet note under a card: what a staff member may change themselves.
  static const TextStyle noteTitle = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle noteBody = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// The week card's day column, and the shift beside it.
  static const TextStyle weekDay = TextStyle(
    fontFamily: _font,
    fontSize: .58 * _px,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle weekDate = TextStyle(
    fontFamily: _font,
    fontSize: 1 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle weekShift = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle weekDetail = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle weekPill = TextStyle(
    fontFamily: _font,
    fontSize: .67 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A day on the attendance tab, and a document row.
  static const TextStyle rowTitle = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle rowDetail = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle rowStatus = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle rowHours = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The initials in the 36px bubble on an attendance day.
  static const TextStyle dayInitials = TextStyle(
    fontFamily: _font,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The PDF / IMG tile on a document row.
  static const TextStyle documentKind = TextStyle(
    fontFamily: _font,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The dashed panel over the Dates tab.
  static const TextStyle structureEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .1 * .72 * _px,
  );
  static const TextStyle structureBody = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// The dashed "Add a document" key, and the footnote under it.
  static const TextStyle dashedKey = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle footnote = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// A date on the Dates tab.
  static const TextStyle dateLabel = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle dateValue = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The two keys docked under the profile.
  static const TextStyle dockedKey = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 6d ---------------------------------------------------------------------

  /// A step row: its number, its title, and the line under it.
  static const TextStyle stepNumber = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle stepTitle = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle stepNote = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle stepFlag = TextStyle(
    fontFamily: _font,
    fontSize: .64 * _px,
    fontWeight: FontWeight.w700,
  );

  /// One of the two pills a pick-one field draws.
  static const TextStyle pill = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A day in the shift editor, and the three wells beside it.
  static const TextStyle shiftDay = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle shiftTime = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The wizard's one key, and the skip under it.
  static const TextStyle wizardKey = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle wizardSkip = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle wizardBackKey = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 6e ---------------------------------------------------------------------

  /// The banner across the top, in whichever tone the state is.
  static const TextStyle banner = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// The navy card that carries the viewer's own record.
  static const TextStyle ownTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle ownSub = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle ownNote = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );
  static const TextStyle ownKey = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A colleague's row: a shade larger than a roster row's name.
  static const TextStyle teamName = TextStyle(
    fontFamily: _font,
    fontSize: .92 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle teamSub = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The big blank states: the glyph tile's mark, the title and the body.
  static const TextStyle stateMark = TextStyle(
    fontFamily: _font,
    fontSize: 1.5 * _px,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle stateTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1.12 * _px,
    fontWeight: FontWeight.w600,
    letterSpacing: -.01 * 1.12 * _px,
  );
  static const TextStyle stateBody = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );
  static const TextStyle stateKey = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );
}
