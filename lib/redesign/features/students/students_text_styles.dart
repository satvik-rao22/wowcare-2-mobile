import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type sizes the M05 frames draw that are not on the core ladder. Sizes are
/// the frame's rem value times 16, like `AppTextStyles`. No colour here.
abstract final class StudentsTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  /// The attendance value and a choice pill: `.79rem 700`.
  static const TextStyle emphasis = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A value beside a label in an expanded row or a person card: `.79rem 600`.
  static const TextStyle detailValue = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A profile field's value: `.8rem 600`, right aligned.
  static const TextStyle fieldValue = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// A profile field's label: `.72rem 600`, line-height 1.4.
  static const TextStyle fieldKey = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// A tag or weekday chip in the expanded row: `.7rem 700`.
  static const TextStyle tag = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A profile tab pill: `.78rem 700`.
  static const TextStyle tabPill = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A person card's badge: `.66rem 700`.
  static const TextStyle badge = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A list item's title (a document, a day, a vaccine): `.86rem 600`.
  static const TextStyle itemTitle = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A list item's second line: `.71rem 600`.
  static const TextStyle itemSub = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// A wizard step's title: `.85rem 700`.
  static const TextStyle stepTitle = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The number in a wizard step's dot: `.72rem 800`.
  static const TextStyle stepNumber = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The "Optional" pill on a wizard step: `.64rem 700`.
  static const TextStyle optionalPill = TextStyle(
    fontFamily: _font,
    fontSize: .64 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The wizard's primary key: `.9rem 700`.
  static const TextStyle wizardKey = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A schedule row's day label: `.75rem 700`.
  static const TextStyle scheduleDay = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A time in a schedule well: `.78rem 600`.
  static const TextStyle scheduleTime = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The upload card's kind chip: `.66rem 800`.
  static const TextStyle uploadChip = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A document row's kind tile: `.62rem 800`.
  static const TextStyle kindTile = TextStyle(
    fontFamily: _font,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The upload card's title: `.92rem 600`.
  static const TextStyle uploadTitle = TextStyle(
    fontFamily: _font,
    fontSize: .92 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The big glyph in an edge state's tile: `1.5rem 800`.
  static const TextStyle edgeGlyph = TextStyle(
    fontFamily: _font,
    fontSize: 1.5 * _px,
    fontWeight: FontWeight.w800,
  );

  /// An edge state's body: `.83rem 500`, line-height 1.6.
  static const TextStyle edgeBody = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  /// A sheet header's sub-line: `.75rem 600`.
  static const TextStyle sheetSub = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
  );

  /// An action row's label in the actions sheet: `.86rem 700`.
  static const TextStyle actionLabel = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The two-letter glyph in an action row's tile: `.7rem 800`.
  static const TextStyle actionGlyph = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The value column in the deactivate sheet's cost card: `.82rem 700`.
  static const TextStyle costValue = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The deactivate key: `.93rem 700`.
  static const TextStyle deactivateKey = TextStyle(
    fontFamily: _font,
    fontSize: .93 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A quiet text action under a key: `.83rem 700`.
  static const TextStyle quietAction = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A footnote: `.7rem 600`, line-height 1.45.
  static const TextStyle footnote = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// Notes typed into a well: `.81rem 500`, line-height 1.5.
  static const TextStyle notes = TextStyle(
    fontFamily: _font,
    fontSize: .81 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// A filter chip in the sheet: `.76rem 700`.
  static const TextStyle filterChip = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A field's value in a dropdown well on the wizard: `.83rem 600`.
  static const TextStyle wellValue = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The header's sub-line on 5c: `.73rem 600`.
  static const TextStyle headerSub = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A bottom-sheet or edge-state secondary action: `.79rem 700`.
  static const TextStyle secondaryAction = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w700,
  );
}
