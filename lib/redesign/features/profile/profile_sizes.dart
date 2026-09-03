import 'package:flutter/widgets.dart';

/// Measurements the M13 frames use that the core token layer does not carry.
/// Module-local by rule: core tokens belong to the core engineer.
abstract final class ProfileSizes {
  // --- Hero card (13a, 13c) -------------------------------------------------

  /// The staff hero avatar, and the smaller guardian one.
  static const double heroAvatar = 76;
  static const double guardianHeroAvatar = 70;
  static const EdgeInsets heroPad = EdgeInsets.all(17);
  static const double heroGap = 14;
  static const double heroTextGap = 4;
  static const double roleChipGap = 5;
  static const EdgeInsets roleChipPad = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 4,
  );
  static const double heroGlyph = 26;
  static const double uploadRing = 4;
  static const double photoBorder = 2;

  /// The small pink Edit key in the header, and the small keys in the hero.
  static const EdgeInsets smallKeyPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 9,
  );
  static const EdgeInsets navyKeyPad = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 11,
  );
  static const EdgeInsets rowKeyPad = EdgeInsets.all(13);
  static const double photoBlockGap = 9;

  // --- Detail card ----------------------------------------------------------

  static const EdgeInsets detailCardPad = EdgeInsets.all(16);
  static const double detailGap = 13;
  static const double labelGap = 6;
  static const double labelTagGap = 8;
  static const EdgeInsets valueWellPad = EdgeInsets.all(14);
  static const EdgeInsets tagPad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 3,
  );

  /// The muted ink on a locked value.
  static const double lockedOpacity = .75;

  // --- Work schedule --------------------------------------------------------

  static const double scheduleGap = 12;
  static const double dayChipGap = 5;
  static const EdgeInsets dayChipPad = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets hoursWellPad = EdgeInsets.all(12);
  static const double hoursGap = 11;
  static const EdgeInsets pillKeyPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const EdgeInsets lockChipPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  );
  static const double lockChipGap = 5;
  static const double lockGlyph = 9;

  // --- Actions card ---------------------------------------------------------

  static const EdgeInsets actionRowPad = EdgeInsets.all(14);
  static const double actionRowGap = 11;
  static const double actionGlyph = 17;
  static const double pinTracking = 1.9;
  static const EdgeInsets pinKeyPad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );

  // --- Notes ----------------------------------------------------------------

  static const EdgeInsets notePad = EdgeInsets.all(13);
  static const EdgeInsets noteRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const double noteGap = 9;
  static const double noteDot = 7;
  static const double noteGlyph = 15;

  // --- Guardian children (13c) ---------------------------------------------

  static const double childAvatar = 36;
  static const EdgeInsets childRowPad = EdgeInsets.all(12);
  static const double childRowGap = 11;
  static const double childListGap = 10;
  static const EdgeInsets openPillPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  // --- Skeleton (13f) -------------------------------------------------------

  static const double skeletonLine = 14;
  static const double skeletonSub = 10;
  static const double skeletonWell = 44;
  static const double skeletonGap = 9;
  static const double skeletonNameWidth = .65;
  static const double skeletonRoleWidth = .45;
  static const double skeletonNoteWidth = .3;

  // --- Failed card (13f) ----------------------------------------------------

  static const EdgeInsets failedCardPad = EdgeInsets.all(20);
  static const double failedGap = 14;
  static const double failedTextGap = 6;
  static const double failedIcon = 56;
  static const double failedGlyph = 25;
  static const EdgeInsets retryKeyPad = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  );

  // --- Edit form (13b) ------------------------------------------------------

  static const double formGap = 14;
  static const double fieldRowGap = 10;
  static const int cityFlex = 13;
  static const int zipFlex = 10;
  static const int cancelFlex = 5;
  static const int saveFlex = 7;
  static const EdgeInsets footerPad = EdgeInsets.only(top: 6, bottom: 20);
  static const EdgeInsets footerKeyPad = EdgeInsets.all(15);

  // --- Notification settings (13e) -----------------------------------------

  static const double prefColumn = 52;
  static const double prefCheck = 22;
  static const double prefCheckBorder = 1.5;
  static const double prefTick = 13;
  static const EdgeInsets prefHeaderPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const EdgeInsets prefRowPad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 13,
  );
  static const double prefRowTextGap = 2;
  static const double savingOpacity = .45;
  static const EdgeInsets prefNotesPad = EdgeInsets.only(top: 16, bottom: 22);
  static const double legendBox = 20;
  static const double legendRadius = 6;

  // --- Change password ------------------------------------------------------

  static const double passwordFormGap = 14;
}
