import 'package:flutter/widgets.dart';

/// Measurements the M05 frames use that the core token set does not carry.
/// Module-local on purpose: core is another engineer's file.
abstract final class StudentsSizes {
  // --- 5a roster ------------------------------------------------------------

  /// The strip of filter chips and the two counting tiles under the search.
  static const EdgeInsets stripPad = EdgeInsets.fromLTRB(18, 10, 18, 2);

  /// Between classroom groups in the roster body.
  static const double groupGap = 15;

  /// The scrolling roster's own padding: the gutters, a little air under the
  /// counts, and enough at the foot to clear the FAB and the tab bar.
  static const EdgeInsets listPad = EdgeInsets.fromLTRB(18, 12, 18, 96);

  /// The gap between the rows of one classroom group.
  static const double rowGap = 9;

  /// An expanded row's detail block: `padding: 2px 13px 13px; gap: 11px`.
  static const EdgeInsets detailPad = EdgeInsets.fromLTRB(13, 2, 13, 13);
  static const double detailGap = 11;

  /// The "Tags" label's fixed width in the expanded row.
  static const double detailLabelWidth = 74;

  /// A tag chip or a weekday chip in the expanded row.
  static const EdgeInsets tagPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 5,
  );
  static const double tagGap = 5;
  static const EdgeInsets dayPad = EdgeInsets.symmetric(vertical: 6);

  /// The opacity of a weekday the student is not scheduled on.
  static const double dayOffOpacity = .45;

  /// The two keys at the foot of an expanded row.
  static const double detailKeyGap = 8;

  /// The Select key in the header.
  static const EdgeInsets selectKeyPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );

  static const double dockGap = 9;
  static const EdgeInsets dockSubKeyPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  /// The recessed staff-scope note (5a staff lens).
  static const EdgeInsets notePad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const double noteGap = 10;
  static const double noteGlyph = 17;

  // --- The actions sheet (5a) and the deactivate sheet (5h) -----------------

  static const double sheetAvatar = 48;
  static const double sheetHeaderGap = 12;
  static const double actionRowGap = 7;
  static const EdgeInsets actionRowPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double actionGlyphTile = 30;

  static const EdgeInsets costCardPad = EdgeInsets.all(14);
  static const double costRowGap = 10;
  static const EdgeInsets deactivateKeyPad = EdgeInsets.all(16);

  // --- 5b filter sheet ------------------------------------------------------

  static const double filterSectionGap = 14;
  static const double filterOptionGap = 8;
  static const double choiceGap = 7;
  static const EdgeInsets choicePad = EdgeInsets.symmetric(vertical: 11);
  static const EdgeInsets filterChipPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );

  /// Apply is wider than Clear all: `flex: 1` against `flex: 1.3`.
  static const int filterClearFlex = 10;
  static const int filterApplyFlex = 13;

  /// How tall the tag dropdown grows before it scrolls inside itself.
  static const double dropdownListHeight = 240;

  // --- 5c profile -----------------------------------------------------------

  static const double profileAvatar = 52;
  static const double profileAvatarRing = 2.5;
  static const double profileAvatarRingGap = 2.5;
  static const double profileHeaderGap = 11;
  static const EdgeInsets profileHeaderPad = EdgeInsets.fromLTRB(
    18,
    12,
    18,
    12,
  );

  static const EdgeInsets tabPillPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 9,
  );
  static const double tabPillGap = 7;
  static const EdgeInsets subTabsPad = EdgeInsets.fromLTRB(18, 11, 18, 0);

  static const double fieldLabelWidth = 112;
  static const double fieldRowGap = 10;
  static const double fieldsGap = 11;
  static const EdgeInsets smallKeyPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );

  static const EdgeInsets personCardPad = EdgeInsets.all(14);
  static const EdgeInsets personKeyPad = EdgeInsets.all(11);

  static const EdgeInsets dashedRowPad = EdgeInsets.all(14);
  static const double dashedRowGap = 8;
  static const double dashedGlyph = 16;

  static const EdgeInsets itemRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double miniAvatar = 36;
  static const double miniAvatarRingGap = 2;
  static const double kindTile = 36;

  static const EdgeInsets footerPad = EdgeInsets.fromLTRB(18, 11, 18, 22);
  static const double footerGap = 9;

  // --- 5d wizard ------------------------------------------------------------

  static const EdgeInsets stepsPad = EdgeInsets.fromLTRB(18, 0, 18, 4);
  static const double stepGap = 8;
  static const EdgeInsets stepPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double stepDot = 26;
  static const EdgeInsets formPad = EdgeInsets.fromLTRB(18, 12, 18, 14);
  static const double formGap = 11;
  static const double fieldGap = 6;

  static const double scheduleDayWidth = 44;
  static const double scheduleGap = 9;
  static const double scheduleRowGap = 10;
  static const EdgeInsets timeWellPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 10,
  );

  static const EdgeInsets wizardPrimaryPad = EdgeInsets.all(15);

  // --- 5e edit --------------------------------------------------------------

  static const double editFieldGap = 13;
  static const EdgeInsets tagChipPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );
  static const double tagRemoveGlyph = 10;

  /// The dashed "Add a tag" key, which is a pill like the tags beside it.
  static const double tagKeyRadius = 999;

  // --- 5f documents ---------------------------------------------------------

  static const double uploadChip = 40;
  static const double uploadCardGap = 12;
  static const double progressHeight = 10;
  static const EdgeInsets uploadNotePad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const EdgeInsets uploadSecondaryPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );

  // --- 5g edge states -------------------------------------------------------

  static const double edgeIcon = 78;
  static const double edgeIconRadius = 28;
  static const double edgeGap = 15;
  static const double edgeTextGap = 7;
  static const EdgeInsets edgePad = EdgeInsets.symmetric(
    horizontal: 30,
    vertical: 24,
  );
  static const EdgeInsets edgeKeyPad = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  );
  static const EdgeInsets bannerMargin = EdgeInsets.fromLTRB(18, 10, 18, 0);
  static const EdgeInsets bannerPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const double bannerDot = 9;
  static const double bannerGap = 10;
}
