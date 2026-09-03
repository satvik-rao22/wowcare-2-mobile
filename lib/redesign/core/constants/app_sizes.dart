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

  // --- Rims -----------------------------------------------------------------
  //
  // A rimmed key's solid shadow, in the CSS `0 4px 0 <rim>` sense. At full
  // press it collapses to [keyRimDown] while the face travels [keySink].

  /// The primary, destructive and kiosk pad keys' rim at rest.
  static const double keyRim = 4;

  /// The primary and destructive keys' rim at full press.
  static const double keyRimDown = 1;

  /// The FAB's rim at rest. It sinks flush, so there is no down value.
  static const double fabRim = 3;

  // --- Cards, from 3A1 and 7a -----------------------------------------------

  /// A card's body padding.
  static const EdgeInsets cardPad = EdgeInsets.all(15);

  /// The gap between a card's title row and its body.
  static const double cardContentGap = 13;

  // --- Header bar glyphs and badges, from 3A1 and 5a ------------------------

  /// The dashboard header's gap, a touch wider than a title header's.
  static const double headerDashboardGap = 10;

  /// The glyph inside a 38px icon key.
  static const double iconKeyGlyph = 18;

  /// The glyph inside the 34px back key.
  static const double backKeyGlyph = 17;

  /// The bell key's unread bubble: 18px tall, hanging 3px past the corner,
  /// ringed 2px in the ground it sits on.
  static const double iconKeyBadge = 18;
  static const EdgeInsets iconKeyBadgePad = EdgeInsets.symmetric(horizontal: 4);
  static const double iconKeyBadgeRing = 2;
  static const double iconKeyBadgeOverhang = 3;

  // --- Tab bar, from 3A1 ----------------------------------------------------

  /// The glyph inside a tab tile.
  static const double tabGlyph = 19;

  /// How far the unread badge sits in from the tile's top-right corner.
  static const double tabBadgeInset = 4;

  // --- Keys with a glyph, from 1a and 7a ------------------------------------

  /// The glyph beside a key's label, and the gap between them.
  static const double keyGlyph = 17;
  static const double keyIconGap = 10;

  // --- List row, from 5a ----------------------------------------------------

  /// The chevron at the end of a tappable row.
  static const double rowChevron = 15;

  /// The gap between a row's name and its sub-line.
  static const double rowTextGap = 2;

  /// A small pill, the size a row's trailing flag uses.
  static const EdgeInsets pillSmallPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 5,
  );

  // --- Fields, from 1a, 5a and the Components page --------------------------

  /// The sign-in fields, which are a size up from the everyday field.
  static const EdgeInsets fieldPadLarge = EdgeInsets.all(16);

  /// The one tall key on a screen with nothing else on it: 1a's Sign in,
  /// 1d's Send reset link, 1f's Save and sign in.
  static const EdgeInsets keyPadLarge = EdgeInsets.all(18);

  /// A field's leading glyph and the gap to the text.
  static const double fieldIcon = 19;
  static const double fieldIconGap = 12;

  /// A field's trailing glyph: the eye on a password, the tick on valid input.
  static const double fieldTrailingIcon = 19;

  /// The search field: a shallower pad than a field, and a 16px glyph.
  static const EdgeInsets searchPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double searchGlyph = 16;

  /// The dropdown's caret and the gap either side of its text.
  static const double caret = 15;
  static const double dropdownGap = 9;

  // --- Radio cards and check rows, from 1b and 5a ---------------------------

  static const EdgeInsets radioCardPad = EdgeInsets.all(18);
  static const double radioCardGap = 13;

  /// The 22px ring radio: a 2px ring around a 10px dot.
  static const double radio = 22;
  static const double radioRing = 2;
  static const double radioDot = 10;

  /// The 22px checkbox: a 2px border around a 12px tick.
  static const double checkbox = 22;
  static const double checkboxBorder = 2;
  static const double checkGlyph = 12;

  // --- Loading ring, from 1a ------------------------------------------------

  /// The ring on a key, and the bigger one on a loading screen.
  static const double ringSmall = 16;
  static const double ringLarge = 24;
  static const double ringStroke = 2.5;

  /// The faint track under the ring's moving arc, as a fraction of its colour.
  static const double ringTrackAlpha = .4;

  // --- Toast, banner and alert, from 1a and the Components page -------------

  /// The status dot leading a toast or the offline banner.
  static const double toastDot = 7;
  static const double toastGap = 9;

  /// Where a toast lands: inside the gutters, just under the header.
  static const EdgeInsets toastMargin = EdgeInsets.symmetric(horizontal: 18);

  static const EdgeInsets bannerPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 11,
  );
  static const double bannerGap = 9;

  static const EdgeInsets alertPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );
  static const double alertGap = 10;

  /// The red "!" bubble on a danger alert.
  static const double alertBubble = 20;

  /// The info glyph on an info alert.
  static const double alertIcon = 17;

  // --- Chips, from 5a -------------------------------------------------------

  /// The gap between a chip's label and its count or remove glyph.
  static const double chipInnerGap = 6;

  /// The remove cross on a dismissible chip.
  static const double chipRemoveGlyph = 11;

  // --- Section eyebrow, from 5a ---------------------------------------------

  /// The gap between an eyebrow and the meta beside it.
  static const double eyebrowMetaGap = 8;

  /// The gap between a section's eyebrow and its first card.
  static const double sectionGap = 9;

  // --- Empty state ----------------------------------------------------------

  /// The glyph inside the 64px well tile.
  static const double emptyGlyph = 28;

  // --- Sheets ---------------------------------------------------------------

  /// The gap between a sheet's footer keys, and above the footer.
  static const double sheetFooterGap = 10;
  static const double sheetFooterTopPad = 2;

  // --- Counting tile --------------------------------------------------------

  /// The gap between a tile's number and its label.
  static const double tileTextGap = 1;

  // --- Odds and ends the widgets share -------------------------------------

  /// A one-pixel rule: dividers, the hairline under a header.
  static const double hairline = 1;

  /// How far an avatar's attendance dot hangs past the bubble's edge (5a).
  static const double attendanceDotOverhang = 1;

  /// A segmented control's segment sinks one pixel, not a key's three (4a).
  static const double segmentSink = 1;

  /// A section eyebrow sits 2px in from the cards below it (5a).
  static const double eyebrowInset = 2;

  /// The default body padding of a screen: gutters, top pad, FAB clearance.
  static const EdgeInsets bodyPad = EdgeInsets.fromLTRB(
    screenGutter,
    screenTopPad,
    screenGutter,
    screenBottomPad,
  );

  /// How much tray a full-height sheet leaves showing above itself.
  static const double sheetTopClearance = 24;
}
