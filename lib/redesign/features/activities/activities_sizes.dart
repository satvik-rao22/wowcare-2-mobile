import 'package:flutter/widgets.dart';

/// Measurements the M08 frames use that the core token set does not carry.
/// Module-local on purpose: core is another engineer's file. Every number is
/// read off a frame's own CSS.
abstract final class ActivitiesSizes {
  // --- 8a the day rail ------------------------------------------------------

  /// The rail's own face: `padding: 9px 10px; gap 8px; radius 16`.
  static const EdgeInsets railPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const double railGap = 8;
  static const double railRowGap = 7;

  /// The two arrows either side of the date: 30px at the chip radius.
  static const double railArrow = 30;
  static const double railArrowGlyph = 14;

  /// The Day / Range key: `padding: 8px 11px; radius 12`.
  static const EdgeInsets railModePad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 8,
  );

  /// The classroom well and the In now switch beside it: `padding: 9px 11px`.
  static const EdgeInsets railWellPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 9,
  );
  static const EdgeInsets railSwitchPad = EdgeInsets.fromLTRB(8, 7, 10, 7);
  static const double railSwitchGap = 7;

  /// The classroom's initial tile inside the well.
  static const double railTile = 18;
  static const double railTileRadius = 6;

  /// The small switch on the rail: 30 by 17, knob 13.
  static const double smallToggleWidth = 30;
  static const double smallToggleHeight = 17;
  static const double smallToggleKnob = 13;
  static const double smallToggleInset = 2;

  /// A dead arrow: today has no tomorrow.
  static const double disabledOpacity = .4;

  // --- 8a layout ------------------------------------------------------------

  static const EdgeInsets railMargin = EdgeInsets.symmetric(horizontal: 18);
  static const EdgeInsets bannerMargin = EdgeInsets.fromLTRB(18, 9, 18, 0);
  static const EdgeInsets chipStripPad = EdgeInsets.fromLTRB(0, 9, 0, 0);
  static const EdgeInsets feedPad = EdgeInsets.fromLTRB(18, 12, 18, 96);
  static const double feedGap = 11;

  // --- The pending banner ---------------------------------------------------

  /// `padding: 10px 12px; radius 16; gap 9`.
  static const EdgeInsets bannerPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const double bannerGap = 9;
  static const double bannerCount = 26;
  static const double bannerCountRadius = 9;
  static const double bannerChevron = 14;

  // --- The timeline rail ----------------------------------------------------

  /// The time column, right aligned, then the node column, then the card.
  static const double timeColumn = 46;
  static const double nodeColumn = 14;
  static const double rowGap = 11;

  /// The node itself, and the ring of page ground around it.
  static const double node = 12;
  static const double nodeRing = 3;
  static const double nodeLine = 2;

  // --- A feed card ----------------------------------------------------------

  /// `padding: 11px; radius 20; gap 9`.
  static const EdgeInsets cardPad = EdgeInsets.all(11);
  static const double cardGap = 9;

  /// The kind's icon tile at the head of a card.
  static const double kindTile = 34;
  static const double kindGlyph = 20;
  static const double kindTileRadius = 12;

  /// A spec chip: `padding: 5px 9px; radius 10`.
  static const EdgeInsets specPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 5,
  );
  static const double specRadius = 10;
  static const double specGap = 5;
  static const double specRunGap = 7;

  /// The recessed additional-notes block: `padding: 9px 11px; radius 14`.
  static const EdgeInsets notePad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 9,
  );
  static const double noteRadius = 14;
  static const double noteGap = 3;

  /// A tag pill on a card.
  static const EdgeInsets tagPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );
  static const double tagGap = 6;

  /// The square photo well a card carries.
  static const double thumb = 150;
  static const double thumbRadius = 18;
  static const double thumbGlyph = 30;

  /// The stack of student initials at the foot of a card.
  static const double kidAvatar = 25;
  static const double kidRing = 2;

  /// How far each avatar overlaps the one before it.
  static const double kidOverlap = 7;
  static const double kidGap = 7;

  // --- The load-more row ----------------------------------------------------

  static const EdgeInsets loadMorePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double loadMoreGap = 10;
  static const double loadMoreTile = 26;
  static const double loadMoreGlyph = 14;
  static const double loadMoreTileRadius = 9;

  // --- 8b the range view ----------------------------------------------------

  /// A day header on a range: `padding: 7px 10px; radius 12`, navy.
  static const EdgeInsets dayHeaderPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 7,
  );
  static const double dayHeaderGap = 8;
  static const EdgeInsets dayHeaderMargin = EdgeInsets.only(top: 16);

  /// The two date wells in range mode.
  static const double rangeFieldGap = 6;

  // --- 8u the four edges ----------------------------------------------------

  /// The classroom pill beside the title on the edge frames.
  static const EdgeInsets scopePillPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  /// The flat day bar the edge frames draw instead of the full rail.
  static const EdgeInsets flatBarPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );

  // --- 8s the staff gate ----------------------------------------------------

  /// The navy card: `padding: 14px; radius 20; gap 12`.
  static const EdgeInsets gateCardPad = EdgeInsets.all(14);
  static const double gateCardGap = 12;
  static const double gateAvatar = 42;
  static const double gateRowGap = 11;
  static const EdgeInsets gateKeyPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );
  static const double gateKeyGap = 9;

  /// The navy strip above it: `padding: 11px 13px; radius 16`.
  static const EdgeInsets gateNoticePad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double gateNoticeGap = 9;
  static const double gateNoticeGlyph = 15;

  /// What the feed behind the gate fades to.
  static const double gatedOpacity = .55;

  // --- 8t the guardian's feed ----------------------------------------------

  /// The day strip a guardian gets: no mode key, no classroom well.
  static const EdgeInsets guardianStripPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 10,
  );
  static const double guardianArrow = 28;
  static const double guardianArrowGlyph = 13;
  static const double guardianArrowRadius = 9;

  /// The acknowledge key on a guardian's card: `padding: 12px; radius 16`.
  static const EdgeInsets ackKeyPad = EdgeInsets.all(12);

  // --- 8c the filter sheet --------------------------------------------------

  static const double sheetGroupGap = 9;
  static const double sheetOptionGap = 7;

  /// A filter option: `padding: 9px 12px; radius 16`.
  static const EdgeInsets sheetOptionPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );

  // --- 8d one activity open -------------------------------------------------

  static const double detailGap = 12;

  /// The head card: `padding: 13px; radius 20; gap 11`.
  static const EdgeInsets detailHeadPad = EdgeInsets.all(13);
  static const double detailHeadGap = 11;
  static const double detailHeadTile = 44;
  static const double detailHeadGlyph = 26;

  /// A read-only field: `padding: 13px 14px; radius 16`.
  static const EdgeInsets detailFieldPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double detailFieldGap = 6;

  /// The attachment well on a detail.
  static const double detailThumb = 168;
  static const double detailThumbGlyph = 32;

  /// The amber acknowledgement block.
  static const EdgeInsets ackBlockPad = EdgeInsets.all(13);
  static const double ackBlockGap = 5;

  /// The two keys docked under an incident awaiting a signature.
  static const EdgeInsets moderationBarPad = EdgeInsets.fromLTRB(18, 12, 18, 12);
  static const double moderationGap = 10;

  // --- 8e the approvals queue ----------------------------------------------

  /// The navy summary card: `padding: 13px 14px; radius 20`.
  static const EdgeInsets queueHeadPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double queueHeadGap = 2;

  /// A queue row: `padding: 13px; radius 20; gap 11`.
  static const EdgeInsets queueRowPad = EdgeInsets.all(13);
  static const double queueRowGap = 11;
  static const double queueAvatar = 38;
  static const double queueGlyph = 22;
  static const EdgeInsets queueKeyPad = EdgeInsets.all(13);
  static const double queueKeyGap = 9;
  static const double queueListGap = 11;

  // --- 8f step 1 ------------------------------------------------------------

  /// The narrowing card above the roster: `padding: 9px 10px; gap 8`.
  static const EdgeInsets pickToolsPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const double pickToolsGap = 8;
  static const double pickToolsRowGap = 7;

  /// A roster row: `padding: 11px; radius 20; gap 11`.
  static const EdgeInsets pickRowPad = EdgeInsets.all(11);
  static const double pickRowGap = 11;
  static const double pickListGap = 9;
  static const double pickAvatar = 38;

  /// The check box on a roster row: 22px at radius 7.
  static const double pickBox = 22;
  static const double pickBoxRadius = 7;
  static const double pickBoxGlyph = 13;

  /// The In now block inside the narrowing card.
  static const EdgeInsets pickInNowPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 9,
  );
  static const double pickInNowGap = 9;

  /// The docked footer: the footnote and the one pink key.
  static const EdgeInsets pickFooterPad = EdgeInsets.fromLTRB(18, 12, 18, 12);
  static const double pickFooterGap = 9;

  // --- 8g step 2 ------------------------------------------------------------

  /// The picked-students summary: `padding: 11px 12px; radius 20`.
  static const EdgeInsets summaryPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double summaryGap = 9;
  static const double summaryAvatar = 30;
  static const double formSummaryAvatar = 28;

  /// A type tile: `padding: 13px 12px; radius 20; gap 10`.
  static const EdgeInsets typeTilePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 13,
  );
  static const double typeTileGap = 10;
  static const double typeTileIcon = 36;
  static const double typeTileGlyph = 22;
  static const double typeGridGap = 10;
  static const double typeGroupGap = 11;
  static const double typeGridAspect = 2.55;

  /// A tile a rule has switched off.
  static const double tileOffOpacity = .5;

  /// The navy tip that says why.
  static const EdgeInsets tipPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );

  // --- 8h to 8r, the forms --------------------------------------------------

  /// The picked-students strip under a form's header.
  static const EdgeInsets formSummaryPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 10,
  );

  static const double formGap = 11;
  static const double fieldRowGap = 9;
  static const double fieldStackGap = 6;

  /// The icon tile beside a form's title.
  static const double formKindTile = 34;
  static const double formKindGlyph = 21;

  /// A well-backed value field: `padding: 12px 13px; radius 16`.
  static const EdgeInsets valuePad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double valueGlyph = 13;
  static const double valueGap = 8;

  /// How tall a description box opens.
  static const double descriptionMinHeight = 76;
  static const int descriptionLines = 3;

  /// A toggle card: `padding: 11px 12px; radius 16; gap 11`.
  static const EdgeInsets toggleCardPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double toggleCardGap = 11;
  static const double toggleTextGap = 2;

  /// A person row on a form: `padding: 9px 10px; radius 16; gap 10`.
  static const EdgeInsets personPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const double personGap = 10;
  static const double personAvatar = 32;
  static const EdgeInsets personKeyPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );
  static const double personKeyRadius = 11;

  /// The bottle stepper: two 48px keys either side of the reading.
  static const double stepperKey = 48;
  static const double stepperGlyph = 18;
  static const double stepperGap = 9;

  /// A photo slot on a form: 78px square at the inner radius.
  static const double photoSlot = 78;
  static const double photoSlotGlyph = 22;
  static const double photoSlotGap = 10;
  static const double photoAddGlyph = 20;

  /// The video slot, which is wider than a photo's.
  static const double videoSlot = 168;

  /// The dashed rim on an empty photo tray.
  static const double dashWidth = 5;
  static const double dashGap = 4;
  static const double dashStroke = 1.4;

  /// The docked Cancel and Add row: `padding: 12px 18px 12px`.
  static const EdgeInsets formBarPad = EdgeInsets.fromLTRB(18, 12, 18, 12);
  static const double formBarGap = 10;
  static const EdgeInsets cancelKeyPad = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 15,
  );

  // --- 8v the image uploader ------------------------------------------------

  /// The dialog is centred rather than docked: `left/right 20; radius 28`.
  static const EdgeInsets uploaderMargin = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets uploaderPad = EdgeInsets.fromLTRB(18, 18, 18, 18);
  static const double uploaderGap = 14;
  static const double uploaderHeaderGap = 10;
  static const double uploaderClose = 30;
  static const double uploaderCloseGlyph = 14;
  static const double uploaderTabRule = 2;
  static const EdgeInsets uploaderTabPad = EdgeInsets.only(bottom: 6);

  /// The empty tray inside it.
  static const EdgeInsets uploaderEmptyPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 20,
  );
  static const double uploaderEmptyTile = 40;
  static const double uploaderEmptyGlyph = 20;
  static const double uploaderEmptyGap = 8;

  /// A thumbnail: 72px square, its state strip, and the drop cross.
  static const double uploaderThumb = 72;
  static const double uploaderThumbGlyph = 26;
  static const double uploaderThumbGap = 14;
  static const double uploaderThumbRadius = 12;
  static const EdgeInsets uploaderStatePad = EdgeInsets.symmetric(vertical: 3);
  static const double uploaderStateInset = 4;
  static const double uploaderStateRadius = 7;
  static const double uploaderDrop = 20;
  static const double uploaderDropGlyph = 10;
  static const double uploaderDropOverhang = 6;

  /// The overall progress bar.
  static const double uploaderBar = 8;
  static const double uploaderBarGap = 7;

  static const EdgeInsets uploaderFailPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double uploaderFailGap = 4;

  static const EdgeInsets uploaderChoosePad = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 13,
  );
  static const double uploaderChooseGap = 7;

  // --- Odds and ends --------------------------------------------------------

  /// The hairline rule that runs off a section eyebrow.
  static const double ruleGap = 9;

  /// How close to the foot of the feed a scroll gets before the next page is
  /// asked for.
  static const double pageTriggerInset = 320;
}
