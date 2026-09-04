import 'package:flutter/widgets.dart';

/// Measurements the M04 frames use that the core token set does not carry.
/// Module-local on purpose: core is another engineer's file. Every number is
/// read off a frame's own CSS.
abstract final class AttendanceSizes {
  // --- 4a the day strip -----------------------------------------------------

  /// The strip's own face: `padding: 5px 6px; radius 16`.
  static const EdgeInsets dayStripPad = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 5,
  );
  static const double dayStripGap = 6;

  /// The two arrows either side of the date: 34px at the chip radius.
  static const double dayArrow = 34;
  static const double dayArrowGlyph = 15;

  /// The calendar glyph beside the date, and the gap to it.
  static const double dayGlyph = 15;
  static const double dayGlyphGap = 7;

  /// A day that cannot be stepped to: tomorrow, on today's list.
  static const double disabledOpacity = .4;

  // --- 4a layout ------------------------------------------------------------

  /// Between the switch, the day strip, the chips and the list.
  static const EdgeInsets switchMargin = EdgeInsets.symmetric(horizontal: 18);
  static const EdgeInsets stripMargin = EdgeInsets.fromLTRB(18, 10, 18, 0);
  static const EdgeInsets chipStripPad = EdgeInsets.fromLTRB(0, 11, 0, 4);

  /// The scrolling body: the gutters, a little air, and enough at the foot to
  /// clear the FAB and the tab bar.
  static const EdgeInsets listPad = EdgeInsets.fromLTRB(18, 6, 18, 96);

  /// Between one classroom group and the next.
  static const double groupGap = 14;

  /// Between the rows of one group.
  static const double rowGap = 8;

  // --- 4a row ---------------------------------------------------------------

  /// A row's own padding: `9px 12px`.
  static const EdgeInsets rowPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );

  /// The 46px ringed avatar an attendance row leads with, one step up from
  /// the roster's 44.
  static const double avatar = 46;
  static const double avatarRing = 2.5;
  static const double avatarRingPad = 2.5;

  /// An open record: `padding: 2px 13px 13px; gap: 9px`.
  static const EdgeInsets detailPad = EdgeInsets.fromLTRB(13, 2, 13, 13);
  static const double detailGap = 9;

  /// The label column in an open record.
  static const double detailLabelWidth = 100;

  // --- 4a select mode -------------------------------------------------------

  /// The header's Select / Done key.
  static const EdgeInsets selectKeyPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );

  /// The docked bar under select mode: `padding: 11px 18px 12px`.
  static const EdgeInsets selectBarPad = EdgeInsets.fromLTRB(18, 11, 18, 12);
  static const double selectBarGap = 10;
  static const EdgeInsets selectClearPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  // --- 4a / 4c cards --------------------------------------------------------

  /// The recessed scope note at the foot of a list.
  static const EdgeInsets notePad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );
  static const double noteGap = 3;

  /// The staff gap alert on 4c, and its two keys.
  static const double alertCardGap = 9;
  static const double alertTile = 26;
  static const double alertTileGlyph = 14;
  static const double alertTileRadius = 9;
  static const double alertKeyGap = 8;

  // --- 4d the teacher's own card -------------------------------------------

  /// The navy card's own padding and gaps.
  static const EdgeInsets selfCardPad = EdgeInsets.all(16);
  static const double selfCardGap = 13;

  /// The 50px avatar on the navy card and the sheet header.
  static const double headerAvatar = 50;

  /// The geofence line inside the navy card.
  static const EdgeInsets selfNotePad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double selfNoteGap = 8;
  static const double selfNoteGlyph = 15;

  /// The lock card over a locked classroom.
  static const double lockTile = 34;
  static const double lockGlyph = 17;
  static const double lockRadius = 12;

  /// What a locked classroom list fades to.
  static const double lockedOpacity = .55;

  // --- 4e edge cards --------------------------------------------------------

  static const EdgeInsets edgeCardPad = EdgeInsets.all(20);
  static const double edgeCardGap = 12;
  static const EdgeInsets emptyCardPad = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 24,
  );
  static const double edgeKeyGap = 8;

  /// The green tick tile on the nobody-absent card.
  static const double edgeTile = 44;
  static const double edgeTileGlyph = 22;

  // --- 4f the range view ----------------------------------------------------

  /// The range strip: `padding: 5px 6px`, with two small keys on the right.
  static const EdgeInsets rangeStripPad = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 5,
  );
  static const double rangeStripGap = 7;
  static const EdgeInsets rangeKeyPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );

  /// A range row: `padding: 11px 12px; radius 18`, with a 38px avatar.
  static const EdgeInsets rangeRowPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const EdgeInsets rangeOpenPad = EdgeInsets.all(12);
  static const double rangeAvatar = 38;
  static const double rangeRowGap = 11;
  static const double rangeOpenGap = 11;
  static const double rangeChevron = 14;
  static const double rangeListGap = 9;
  static const EdgeInsets rangeListPad = EdgeInsets.fromLTRB(18, 12, 18, 96);

  /// The three dots at the foot of a page still loading.
  static const double loadingDot = 7;
  static const double loadingDotGap = 9;
  static const EdgeInsets loadingMorePad = EdgeInsets.fromLTRB(0, 14, 0, 18);

  /// How close to the end of the list a scroll gets before the next page is
  /// asked for.
  static const double pageTriggerInset = 320;

  // --- The two forms --------------------------------------------------------

  /// Between the tiles, the two fields and the footnote.
  static const double formGap = 13;

  /// A removable person tile: the avatar, the name, the cross.
  static const EdgeInsets personTilePad = EdgeInsets.fromLTRB(12, 9, 9, 9);
  static const double personTileGap = 10;
  static const double personTileAvatar = 38;
  static const double removeGlyph = 16;
  static const double removeKey = 30;

  /// How tall the Mark Absent reason box opens.
  static const int reasonLines = 3;

  /// The acknowledgement block on a sign-in with someone unexpected on it.
  static const EdgeInsets ackPad = EdgeInsets.all(14);
  static const double ackGap = 10;

  // --- Sheets ---------------------------------------------------------------

  /// The tinted note block in the record sheet.
  static const EdgeInsets sheetNotePad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 11,
  );
  static const double sheetNoteGap = 2;
  static const double sheetGridGap = 9;
  static const EdgeInsets sheetGridKeyPad = EdgeInsets.all(13);
  static const double sheetHeaderGap = 12;

  /// A dimmed key in the record sheet's grid: an action that is off right now.
  static const double keyOffOpacity = .4;

  /// The day sheet's four options.
  static const double optionGap = 8;
  static const EdgeInsets optionPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 14,
  );
  static const double optionGlyphGap = 12;
  static const double rangeFieldGap = 8;

  // --- Guardian lens --------------------------------------------------------

  static const double guardianGap = 13;
  static const double guardianKeyGap = 9;
  static const EdgeInsets guardianDayPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
}
