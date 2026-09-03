import 'package:flutter/widgets.dart';

/// Measurements the M03 frames use that the core token layer does not carry.
///
/// Module-local by design: core tokens belong to another engineer. Every value
/// is retyped from the frame DOM (`3A1.txt` and friends), with `rem` values
/// multiplied out at the frames' 16px root.
abstract final class DashboardSizes {
  static const double _px = 16;

  // --- Attention deck (3A1) -------------------------------------------------

  /// The stack's footprint, and one card's height inside it.
  static const double deckHeight = 172;
  static const double deckCardHeight = 146;

  /// Where the second, third and hidden cards sit behind the front one.
  static const double deckOffset1 = 11;
  static const double deckOffset2 = 21;
  static const double deckOffsetHidden = 27;
  static const double deckScale1 = .965;
  static const double deckScale2 = .93;
  static const double deckScaleHidden = .91;

  /// How many cards are drawn behind the front one.
  static const int deckVisibleBehind = 2;

  static const double deckTopGap = 10;
  static const double deckDotsTopGap = 6;
  static const double deckDotHeight = 6;
  static const double deckDotWidth = 6;
  static const double deckDotActiveWidth = 18;
  static const double deckDotGap = 6;
  static const double deckToBodyGap = 16;

  static const double attentionIconTile = 38;
  static const double attentionGlyph = 19;
  static const double attentionTitleGap = 3;
  static const double attentionHeadlineGap = 8;
  static const EdgeInsets attentionActionPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );
  static const EdgeInsets attentionWellPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const EdgeInsets attentionTilePad = EdgeInsets.all(10);
  static const double attentionWellGap = 8;
  static const double attentionRowGap = 5;
  static const double attentionEyebrowSize = .68 * _px;
  static const double attentionEyebrowSpacing = .1 * .68 * _px;
  static const double attentionTitleSize = .95 * _px;
  static const double attentionHeadlineLabelSize = .76 * _px;
  static const double attentionActionSize = .74 * _px;
  static const double attentionMoneySize = 1.9 * _px;
  static const double attentionTileValueSize = 1 * _px;

  // --- My day (3A1, 3S1) ----------------------------------------------------

  static const EdgeInsets dayTilePad = EdgeInsets.all(11);
  static const double dayTileGap = 9;
  static const double dayTileTextGap = 2;
  static const double dayTileLabelSize = .6 * _px;
  static const double dayTileLabelSpacing = .08 * .6 * _px;
  static const double dayTileTimeSize = .98 * _px;
  static const double dayTileRangeSize = .76 * _px;

  static const EdgeInsets pinStripPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const double pinStripGap = 10;
  static const double pinStripGlyph = 15;
  static const double pinSize = .96 * _px;
  static const double pinSpacing = .14 * .96 * _px;

  static const double dayKeyGap = 8;
  static const EdgeInsets dayKeyPad = EdgeInsets.all(12);
  static const double dayKeyLabelSize = .83 * _px;
  static const double dayKeyGlyph = 14;
  static const double dayKeyGlyphGap = 6;

  static const EdgeInsets messageRowPad = EdgeInsets.all(11);
  static const double messageRowGap = 10;
  static const double messageAvatar = 32;
  static const double messageAvatarTextSize = .68 * _px;
  static const double messageNameSize = .79 * _px;
  static const double messagePreviewSize = .71 * _px;
  static const double messageBadge = 18;
  static const EdgeInsets messageBadgePad = EdgeInsets.symmetric(horizontal: 5);
  static const double messageBadgeTextSize = .61 * _px;

  static const double statusPillDot = 6;
  static const double statusPillDotGap = 6;
  static const EdgeInsets statusPillPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  );
  static const double statusPillTextSize = .64 * _px;
  static const double cardChevron = 15;

  // --- Today's school status (3A1) ------------------------------------------

  static const EdgeInsets statusWellPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 11,
  );
  static const double statusWellGap = 8;
  static const double statusNumberSize = 1.1 * _px;
  static const double statusLabelSize = .6 * _px;
  static const double statusBlockGap = 7;
  static const double statusGroupTitleSize = .82 * _px;
  static const double statusGroupMetaSize = .68 * _px;
  static const double statusTroughHeight = 10;
  static const double legendGap = 6;
  static const EdgeInsets legendChipPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 6,
  );
  static const double legendDot = 7;
  static const double legendLabelSize = .66 * _px;
  static const double legendCountSize = .72 * _px;

  // --- Ratio monitoring and classroom shifts (3A2, 3S1) ---------------------

  static const EdgeInsets innerRowPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 10,
  );
  static const double innerRowGap = 10;
  static const double innerRowTitleSize = .82 * _px;
  static const double innerRowSubSize = .69 * _px;
  static const double innerRowFlagSize = .68 * _px;
  static const double ratioBarWidth = 8;
  static const double ratioBarHeight = 30;
  static const double ratioBarRadius = 4;
  static const double ratioRing = 80;
  static const double ratioRingStroke = 7;
  static const double ratioRingNumberSize = 1.3 * _px;
  static const double ratioRingCaptionSize = .54 * _px;
  static const double ratioRingCaptionSpacing = .06 * .54 * _px;
  static const double ratioRingGap = 14;
  static const double ratioClassroomTextGap = 7;

  // --- Availability and movements (3A2) -------------------------------------

  static const double summaryNumberSize = 1.3 * _px;
  static const double summaryLabelSize = .72 * _px;
  static const double summaryNumberGap = 6;
  static const double summaryDividerHeight = 26;
  static const double summaryGap = 14;

  // --- Billing (3A2, 3P2) ---------------------------------------------------

  static const double billingAmountSize = 1.08 * _px;
  static const double billingLabelSize = .62 * _px;
  static const double billingColumnGap = 10;
  static const EdgeInsets rangeKeyPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  );
  static const double rangeKeyGap = 6;
  static const double rangeKeyTextSize = .66 * _px;
  static const double rangeKeyCaret = 11;
  static const EdgeInsets unpaidRowPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double unpaidRowGap = 10;
  static const double unpaidTitleSize = .78 * _px;
  static const double unpaidSubSize = .66 * _px;
  static const double unpaidValueSize = .95 * _px;
  static const double unpaidChevron = 13;
  static const double balanceAmountSize = 1.85 * _px;
  static const double balanceAmountSpacing = -.02 * 1.85 * _px;
  static const double balanceSubSize = .74 * _px;
  static const EdgeInsets duePillPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );
  static const double duePillTextSize = .63 * _px;
  static const EdgeInsets payNowPad = EdgeInsets.all(14);

  // --- My shifts and my attendance (3S2) ------------------------------------

  static const EdgeInsets shiftRowPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double shiftRowGap = 12;
  static const double shiftDayColumn = 42;
  static const double shiftDayLabelSize = .58 * _px;
  static const double shiftDayNumberSize = 1.02 * _px;
  static const double shiftTitleSize = .83 * _px;
  static const double dayOffOpacity = .72;
  static const EdgeInsets todayPillPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 4,
  );
  static const double todayPillTextSize = .6 * _px;

  static const EdgeInsets rangeWellPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double rangeWellGap = 10;
  static const double rangeWellGlyph = 16;
  static const double rangeWellTextSize = .79 * _px;
  static const double rangeWellLinkSize = .69 * _px;
  static const EdgeInsets summaryTilePad = EdgeInsets.all(12);
  static const double summaryTileGap = 8;
  static const double summaryTileNumberSize = 1.22 * _px;
  static const double summaryTileLabelSize = .63 * _px;
  static const EdgeInsets dayRowPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double dayRowTextSize = .79 * _px;

  // --- Guardian (3P1, 3P2) --------------------------------------------------

  static const double childAvatar = 52;
  static const double childAvatarTextSize = .95 * _px;
  static const double childNameSize = 1.02 * _px;
  static const double childMetaSize = .73 * _px;
  static const double childHeaderGap = 13;
  static const double switcherTopGap = 14;
  static const double switcherGap = 8;
  static const EdgeInsets switcherPillPad = EdgeInsets.all(10);
  static const double switcherPillTextSize = .83 * _px;
  static const EdgeInsets singleChildPillPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 7,
  );
  static const double singleChildPillTextSize = .72 * _px;
  static const double chipAvatar = 30;
  static const double chipAvatarTextSize = .66 * _px;
  static const EdgeInsets childChipPad = EdgeInsets.fromLTRB(7, 7, 13, 7);
  static const double childChipGap = 9;
  static const double childChipTextSize = .8 * _px;
  static const double childChipRowGap = 8;

  static const EdgeInsets reminderRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double reminderTitleSize = .79 * _px;
  static const double reminderSubSize = .69 * _px;

  static const double activityCircle = 44;
  static const double activityImage = 32;
  static const double activityGap = 8;
  static const double activityTextGap = 6;
  static const double activityLabelSize = .66 * _px;

  static const double invoiceTitleSize = .8 * _px;
  static const double invoiceSubSize = .68 * _px;
  static const double invoiceAmountSize = .83 * _px;
  static const double newsletterIconTile = 44;
  static const double newsletterGlyph = 20;
  static const double newsletterGap = 13;
  static const double newsletterTitleSize = .88 * _px;

  // --- More (3M) ------------------------------------------------------------

  static const EdgeInsets moreHeaderPad = EdgeInsets.fromLTRB(18, 14, 18, 12);
  static const double moreHeaderGap = 12;
  static const double moreAvatar = 44;
  static const double moreAvatarTextSize = .8 * _px;
  static const double moreNameSize = 1.05 * _px;
  static const double moreRoleSize = .73 * _px;
  static const double moreChevron = 18;
  static const double moreGroupGap = 16;
  static const double moreTileGap = 11;
  static const EdgeInsets moreTilePad = EdgeInsets.all(13);
  static const double moreTileInnerGap = 10;
  static const double moreIconTile = 40;
  static const double moreIconGlyph = 21;
  static const double moreTileLabelSize = .88 * _px;
  static const double moreBadge = 20;
  static const EdgeInsets moreBadgePad = EdgeInsets.symmetric(horizontal: 6);
  static const double moreBadgeTextSize = .66 * _px;
  static const double moreEyebrowSize = .66 * _px;
  static const double moreEyebrowSpacing = .14 * .66 * _px;
  static const int moreColumns = 2;
  static const EdgeInsets moreBodyPad = EdgeInsets.fromLTRB(18, 4, 18, 96);

  // --- Account (3M2) --------------------------------------------------------

  static const double accountAvatar = 52;
  static const double accountAvatarTextSize = .95 * _px;
  static const double accountNameSize = 1 * _px;
  static const EdgeInsets accountRowPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 14,
  );
  static const double accountRowGap = 13;
  static const double accountRowTitleSize = .9 * _px;
  static const double accountRowSubSize = .71 * _px;
  static const double accountRowChevron = 16;
  static const double accountPinSize = .85 * _px;
  static const double accountPinSpacing = .1 * .85 * _px;
  static const EdgeInsets rolesPillPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 3,
  );
  static const double rolesPillTextSize = .62 * _px;
  static const double helpLinkSize = .68 * _px;
  static const EdgeInsets logoutPad = EdgeInsets.all(15);
  static const double logoutTextSize = .9 * _px;

  // --- Sheets (3A3, 3S3, 3P3, 13d) ------------------------------------------

  static const double sheetSectionGap = 15;
  static const double sheetTitleGap = 4;
  static const double sheetBodySize = .81 * _px;
  static const EdgeInsets timeCardPad = EdgeInsets.all(16);
  static const double timeCardGap = 12;
  static const double timeEyebrowSize = .64 * _px;
  static const double timeEyebrowSpacing = .12 * .64 * _px;
  static const double timeValueSize = 1.55 * _px;
  static const double timeValueSpacing = -.02 * 1.55 * _px;
  static const double adjustKey = 42;
  static const double adjustKeyGap = 9;
  static const double adjustGlyph = 18;
  static const double timeNoteSize = .72 * _px;
  static const EdgeInsets nowPillPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const double nowPillTextSize = .65 * _px;
  static const double factLabelSize = .78 * _px;
  static const double factValueSize = .81 * _px;
  static const EdgeInsets personCardPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 14,
  );
  static const double personAvatar = 36;
  static const double personAvatarTextSize = .73 * _px;
  static const double personNameSize = .87 * _px;
  static const EdgeInsets warningPad = EdgeInsets.all(14);
  static const double warningGap = 11;
  static const double warningGlyph = 18;
  static const double warningTextSize = .77 * _px;
  static const double sheetKeyGap = 10;
  static const EdgeInsets confirmKeyPad = EdgeInsets.all(16);
  static const double confirmKeyTextSize = .97 * _px;
  static const double sheetChildAvatar = 44;
  static const double sheetChildAvatarTextSize = .82 * _px;
  static const double sheetChildNameSize = .92 * _px;

  /// The confirm sign-out sheets step the time in five-minute nudges.
  static const int adjustStepMinutes = 5;

  static const EdgeInsets personaCardPad = EdgeInsets.all(15);
  static const double personaCardGap = 12;
  static const double personaAvatar = 38;
  static const double personaMarkSize = .68 * _px;
  static const double personaSelectedBorder = 1.5;
  static const double personaListGap = 10;
  static const EdgeInsets sheetNotePad = EdgeInsets.all(12);
  static const double sheetNoteGap = 9;
  static const double sheetNoteDot = 6;
  static const double sheetNoteTextSize = .72 * _px;
  static const double sheetBodyLargeSize = .82 * _px;
  static const double passwordIconTile = 52;
  static const double passwordGlyph = 24;
  static const double sheetEmailSize = .75 * _px;
  static const EdgeInsets logoutNotePad = EdgeInsets.all(14);
  static const double logoutNoteGap = 8;
  static const double logoutNoteTextSize = .73 * _px;
}
