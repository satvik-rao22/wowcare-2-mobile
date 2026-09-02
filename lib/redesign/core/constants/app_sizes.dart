import 'package:flutter/widgets.dart';

/// Every measurement in the app.
///
/// Layout runs on a 4px grid and nothing anywhere may be tapped at less than
/// 44px. Component metrics are retyped from the design's Components page and
/// spot-checked against the module frames, so a widget never writes a number
/// of its own.
abstract final class AppSizes {
  // --- The grid -------------------------------------------------------------

  static const double gridUnit = 4;

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  /// Nothing tappable is ever smaller than this, however small it looks.
  static const double minTouchTarget = 44;

  // --- Screen ---------------------------------------------------------------

  /// The gutter down both sides of every screen.
  static const double screenGutter = 18;

  /// The gap between stacked cards in a screen body.
  static const double cardGap = 11;

  /// Where a screen body starts, under the header bar.
  static const double screenTopPad = 13;

  /// Clearance at the bottom of a scrolling body so the last card clears both
  /// the FAB and the tab bar.
  static const double screenBottomPad = 96;

  // --- Header bar -----------------------------------------------------------

  static const EdgeInsets headerBarPad = EdgeInsets.fromLTRB(18, 12, 18, 10);
  static const double headerGap = 9;

  /// An action key in the header bar.
  static const double iconKey = 38;

  /// The back key, one step smaller than an action key.
  static const double backKey = 34;

  /// Lucide outline, at the weight the design draws them.
  static const double iconStroke = 2.1;
  static const double iconStrokeHeavy = 2.3;

  // --- Tab bar --------------------------------------------------------------

  static const double tabBarHeight = 88;
  static const EdgeInsets tabBarPad = EdgeInsets.fromLTRB(18, 10, 18, 22);
  static const double tabItemWidth = 66;
  static const double tabGlyphTile = 38;
  static const double tabItemGap = 4;

  static const double badgeMinWidth = 15;
  static const double badgeHeight = 15;
  static const EdgeInsets badgePad = EdgeInsets.symmetric(horizontal: 4);

  // --- Keys -----------------------------------------------------------------

  static const EdgeInsets keyPrimaryPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const EdgeInsets keySecondaryPad = EdgeInsets.all(12);
  static const double keyGap = 9;

  /// How far a rimmed key sinks. Its 4px rim collapses to 1px, so the face
  /// travels 3px. In logical pixels, the same distance at every key size.
  static const double keySink = 3;

  /// How far a non-key surface sinks: a row, a card, a chip.
  static const double surfaceSink = 2;

  /// The barely-there shrink on a pressed surface. Keys do not shrink.
  static const double surfacePressScale = .995;

  // --- FAB ------------------------------------------------------------------

  static const double fab = 58;
  static const double fabGlyph = 26;
  static const double fabRight = 20;
  static const double fabBottom = 104;

  // --- List row -------------------------------------------------------------

  static const EdgeInsets rowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );
  static const double rowGap = 11;

  /// A row's leading avatar. Round: it stands for a someone.
  static const double avatar = 44;

  /// Today's attendance, read at a glance off the avatar.
  static const double attendanceDot = 13;

  /// The dot's ring, painted in the colour of the card it sits on.
  static const double attendanceDotRing = 2.5;

  static const EdgeInsets pillPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );

  // --- Fields ---------------------------------------------------------------

  static const EdgeInsets fieldPad = EdgeInsets.all(13);
  static const EdgeInsets dropdownPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double fieldGap = 7;

  // --- Switches -------------------------------------------------------------

  static const double toggleWidth = 46;
  static const double toggleHeight = 27;
  static const double toggleKnob = 21;
  static const double toggleInset = 3;

  static const EdgeInsets segmentedPad = EdgeInsets.all(4);
  static const EdgeInsets segmentPad = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 9,
  );
  static const double segmentGap = 4;

  static const EdgeInsets chipPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const double chipGap = 8;

  // --- Sheets ---------------------------------------------------------------

  static const EdgeInsets sheetPad = EdgeInsets.fromLTRB(18, 14, 18, 24);
  static const double sheetGap = 12;
  static const double grabberWidth = 44;
  static const double grabberHeight = 5;

  // --- Tiles, troughs, toasts ----------------------------------------------

  static const EdgeInsets tilePad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double tileGap = 9;

  static const double troughHeight = 9;

  static const EdgeInsets toastPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );

  // --- Empty state ----------------------------------------------------------

  static const double emptyIcon = 64;
  static const double emptyGap = 11;

  // --- Kiosk ----------------------------------------------------------------

  static const EdgeInsets padKeyPad = EdgeInsets.symmetric(vertical: 15);

  /// The kiosk pad's keys sink further than any other key in the app.
  static const double padKeySink = 4;
}
