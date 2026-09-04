import 'package:flutter/widgets.dart';

/// Measurements the M07 frames use that the core token layer does not carry.
///
/// Module-local by design: core tokens belong to another engineer. Every value
/// is retyped from the frame DOM (`7a.txt` and friends); `rem` values are
/// multiplied out at the frames' 16px root.
abstract final class ClassroomsSizes {
  // --- 7a · the list --------------------------------------------------------

  /// The chips under the search well sit a pixel tighter than the core gap.
  static const double chipGap = 7;

  static const EdgeInsets impactPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double impactGap = 9;
  static const EdgeInsets impactPillPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 6,
  );

  static const EdgeInsets classroomCardPad = EdgeInsets.all(13);
  static const double classroomCardGap = 11;
  static const double classroomInitial = 46;
  static const double classroomHeadGap = 11;
  static const double classroomTitleGap = 3;
  static const double agePillGap = 6;
  static const EdgeInsets agePillPad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 3,
  );
  static const EdgeInsets ratioPillPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );
  static const double cardChevron = 15;
  static const double capacityBar = 8;
  static const double leadAvatar = 26;
  static const double leadGap = 8;

  static const EdgeInsets alertPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 9,
  );
  static const double alertGap = 8;
  static const double alertGlyph = 15;

  /// The dashed "Every classroom is covered" panel.
  static const EdgeInsets coveredPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 22,
  );
  static const double coveredGap = 7;
  static const double dashLength = 5;
  static const double dashGap = 4;

  /// The extended FAB: a plus, a label, and the 20px card radius.
  static const EdgeInsets extendedFabPad = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 14,
  );
  static const double extendedFabGap = 8;
  static const double extendedFabGlyph = 17;

  // --- 7b · no classrooms yet ----------------------------------------------

  static const double bigEmptyIcon = 96;
  static const double bigEmptyGlyph = 42;
  static const double bigEmptyGap = 16;
  static const double bigEmptyTextGap = 7;
  static const EdgeInsets bigEmptyKeyPad = EdgeInsets.symmetric(
    horizontal: 22,
    vertical: 15,
  );

  // --- 7c · one classroom ---------------------------------------------------

  static const EdgeInsets headerKeyPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );

  static const EdgeInsets headCardPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double headAvatar = 52;
  static const double headLeadAvatar = 22;
  static const double headLeadGap = 7;
  static const double headTextGap = 4;
  static const double countTileGap = 7;
  static const EdgeInsets countTilePad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const double countTileTextGap = 1;

  /// The "Classroom profile" link on the header card, held to a width so a
  /// long classroom name never squeezes the pills beside it out of sight.
  static const double profileLinkWidth = 108;

  static const double tabsTopGap = 11;
  static const double toolbarGap = 9;
  static const double rosterGap = 9;

  static const EdgeInsets rosterRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );
  static const double rosterGapInner = 11;
  static const double rosterAvatar = 44;
  static const double rosterRing = 2.5;
  static const double rosterRingPad = 2;
  static const EdgeInsets flagPillPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 5,
  );
  static const double rowCaret = 15;

  static const EdgeInsets expandedPad = EdgeInsets.fromLTRB(13, 2, 13, 13);
  static const double expandedGap = 11;
  static const double expandedLabelWidth = 74;
  static const double tagGap = 5;
  static const EdgeInsets tagPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 5,
  );
  static const double tagRadius = 9;
  static const double dayGap = 5;
  static const EdgeInsets dayPad = EdgeInsets.symmetric(vertical: 6);
  static const double dayRadius = 9;
  static const double dayOffOpacity = .6;
  static const double factGap = 5;
  static const double actionGap = 8;
  static const EdgeInsets actionKeyPad = EdgeInsets.all(12);

  /// The dashed "Nobody matches that" panel inside a tab.
  static const EdgeInsets inlineEmptyPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 20,
  );
  static const double inlineEmptyGap = 6;

  // --- 7c · the Staff tab ---------------------------------------------------

  static const EdgeInsets noticePad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double noticeGap = 10;
  static const double noticeGlyph = 17;
  static const EdgeInsets staffRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double staffAvatar = 44;
  static const double staffTrailingGap = 7;
  static const double staffRowTextGap = 2;

  // --- 7c · the Notes tab ---------------------------------------------------

  static const EdgeInsets dayPillPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 5,
  );
  static const double noteGap = 11;
  static const double noteAvatar = 28;
  static const double noteBubbleGap = 8;
  static const EdgeInsets notePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const double noteBubbleRadius = 18;
  static const double noteBubbleTail = 6;
  static const double noteMaxWidthFactor = .88;
  static const double noteTextGap = 4;
  static const double noteMetaGap = 8;
  static const double newRuleGap = 8;

  static const EdgeInsets composerPad = EdgeInsets.fromLTRB(18, 10, 18, 12);
  static const double composerGap = 9;
  static const double composerKey = 38;
  static const double composerSendKey = 42;
  static const double composerGlyph = 17;

  // --- 7c · select mode -----------------------------------------------------

  static const EdgeInsets selectBarPad = EdgeInsets.fromLTRB(18, 11, 18, 12);
  static const double selectBarGap = 8;
  static const EdgeInsets selectKeyPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const EdgeInsets bulkKeyPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 13,
  );

  // --- 7d · the filter sheet ------------------------------------------------

  static const double sheetGroupGap = 14;
  static const double sheetFieldGap = 8;
  static const EdgeInsets statusKeyPad = EdgeInsets.symmetric(vertical: 11);

  // --- 7e · a teacher's classroom -------------------------------------------

  static const EdgeInsets yourClassroomPillPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 6,
  );
  static const double clockCardGap = 12;
  static const double clockAvatar = 46;
  static const EdgeInsets clockKeyPad = EdgeInsets.all(15);
  static const double overRatioGlyph = 19;
  static const double overRatioGap = 10;
  static const double overRatioTextGap = 4;

  static const EdgeInsets miniCardPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double miniAvatar = 40;
  static const double miniGap = 10;

  static const double lockScrimAlpha = .84;
  static const EdgeInsets lockCardPad = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 18,
  );
  static const double lockCardGap = 10;
  static const double lockIcon = 54;
  static const double lockGlyph = 24;
  static const double lockedRowOpacity = .45;

  // --- 7f · the classroom profile -------------------------------------------

  static const EdgeInsets profileCardPad = EdgeInsets.all(14);
  static const double profileCardGap = 11;
  static const double profileHeadGap = 12;
  static const double profileAvatar = 64;

  static const EdgeInsets uploadWellPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 16,
  );
  static const double uploadGap = 11;
  static const double uploadTile = 38;
  static const double uploadGlyph = 18;
  static const EdgeInsets uploadStatePad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const EdgeInsets uploadBusyPad = EdgeInsets.all(14);
  static const double uploadBusyGap = 9;
  static const EdgeInsets retryKeyPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );
  static const double retryKeyRadius = 12;

  static const double placesTrough = 11;
  static const EdgeInsets statTilePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double statTileGap = 8;
  static const double statTileTextGap = 1;
  static const int statColumns = 2;

  static const EdgeInsets movementRowPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 10,
  );
  static const double movementGap = 10;
  static const double movementTile = 30;
  static const double movementTileRadius = 12;
  static const double movementGlyph = 15;

  static const double centerCardGap = 12;
  static const double centerTableGap = 6;
  static const EdgeInsets centerRowPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const double centerRowGap = 8;
  static const double centerColumnCount = 52;
  static const double centerColumnRatio = 62;
  static const EdgeInsets centerHeaderPad = EdgeInsets.symmetric(horizontal: 2);
  static const EdgeInsets centerPillPad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  /// The navy card's own recessed tiles and rows, as fractions of black and
  /// warm white: the only place the design tints on top of the impact ground.
  static const double onImpactWellAlpha = .22;
  static const double onImpactRowAlpha = .07;

  // --- 7g · 7h · assign ------------------------------------------------------

  static const double railDot = 26;
  static const double railGap = 7;
  static const double railLine = 26;
  static const double railLineHeight = 2;
  static const double railStepGap = 8;

  static const EdgeInsets candidateRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double candidateAvatar = 42;
  static const double candidateGap = 11;
  static const double removeKey = 30;
  static const double removeKeyRadius = 12;
  static const double removeGlyph = 14;

  static const EdgeInsets changesCardPad = EdgeInsets.all(14);
  static const double changesGap = 11;

  static const EdgeInsets footerPad = EdgeInsets.fromLTRB(18, 11, 18, 22);
  static const double footerGap = 9;
  static const EdgeInsets footerKeyPad = EdgeInsets.all(15);
  static const EdgeInsets footerBackPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 15,
  );

  static const EdgeInsets infoWellPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double infoWellGap = 10;
  static const double infoWellGlyph = 16;

  // --- 7i · the two refusals -------------------------------------------------

  static const double refusalAvatar = 52;
  static const double refusalGap = 13;
  static const double refusalHeadGap = 12;
  static const EdgeInsets refusalCardPad = EdgeInsets.all(13);
  static const double refusalCardGap = 10;
  static const double refusalGlyph = 18;
  static const EdgeInsets optionRowPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double optionGap = 11;
  static const double costDot = 6;
  static const double costGap = 9;
  static const double costRowGap = 9;

  // --- 7j · the four states --------------------------------------------------

  static const double stateIcon = 76;
  static const double stateGlyph = 32;
  static const double stateGap = 13;
  static const double stateTextGap = 7;
  static const EdgeInsets deadKeyPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets tryAgainKeyPad = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 13,
  );

  // --- Added · the create form -----------------------------------------------

  static const double formGap = 14;
  static const double formRowGap = 11;
}
