import 'package:flutter/widgets.dart';

/// Measurements the staff frames use that `AppSizes` does not carry.
/// Module-local; the core token files belong to another engineer.
abstract final class StaffSizes {
  // 6a expanded row.
  static const double expandedLabelWidth = 104;
  static const EdgeInsets expandedPad = EdgeInsets.fromLTRB(13, 2, 13, 13);
  static const double expandedGap = 10;
  static const double keyGridGap = 8;

  // 6a header keys.
  static const EdgeInsets selectKeyPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );

  // 6a select bar and 6c action bar.
  static const EdgeInsets dockedBarPad = EdgeInsets.fromLTRB(18, 11, 18, 22);
  static const EdgeInsets dockedKeyPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );

  // 6a / 6f sheet header.
  static const double sheetAvatar = 48;
  static const double actionGlyphTile = 30;
  static const EdgeInsets actionRowPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double actionRowGap = 7;
  static const EdgeInsets sheetKeyPad = EdgeInsets.all(15);

  // 6b filter sheet.
  static const double filterSectionGap = 14;
  static const double filterOptionGap = 8;
  static const double chipWrapGap = 7;
  static const EdgeInsets choiceChipPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );
  static const EdgeInsets choiceOptionPad = EdgeInsets.symmetric(vertical: 11);
  static const int applyKeyFlex = 13;
  static const int clearKeyFlex = 10;

  // 6c profile header and tabs.
  static const double profileAvatar = 52;
  static const double ownAvatar = 48;
  static const double dayAvatar = 36;
  static const double avatarRing = 2.5;
  static const double avatarRingPad = 2.5;
  static const EdgeInsets tabPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 9,
  );
  static const double tabGap = 7;
  static const EdgeInsets tabStripPad = EdgeInsets.fromLTRB(18, 0, 18, 2);
  static const double profileLabelWidth = 118;
  static const double fieldRowGap = 11;
  static const EdgeInsets smallKeyPad = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );
  static const EdgeInsets notePad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const double noteGap = 3;

  // 6c schedule tab.
  static const double dayColumnWidth = 40;
  static const EdgeInsets weekRowPad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );
  static const double weekRowGap = 12;

  // 6c documents tab.
  static const double documentTile = 36;
  static const EdgeInsets documentRowPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 12,
  );
  static const EdgeInsets dashedKeyPad = EdgeInsets.all(14);
  static const EdgeInsets structurePad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );

  // 6d wizard.
  static const double stepDot = 26;
  static const EdgeInsets stepPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double stepGap = 8;
  static const EdgeInsets stepsPad = EdgeInsets.fromLTRB(18, 0, 18, 4);
  static const EdgeInsets wizardBodyPad = EdgeInsets.fromLTRB(18, 12, 18, 14);
  static const double wizardFieldGap = 11;
  static const EdgeInsets rolePillPad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 11,
  );
  static const double shiftDayWidth = 40;
  static const EdgeInsets shiftWellPad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 10,
  );
  static const double shiftRowGap = 9;
  static const double shiftCardGap = 10;
  static const EdgeInsets backKeyPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );
  static const EdgeInsets wizardFooterPad = EdgeInsets.fromLTRB(18, 11, 18, 22);
  static const double wizardFooterGap = 9;

  // 6e.
  static const EdgeInsets bannerMargin = EdgeInsets.fromLTRB(18, 10, 18, 0);
  static const EdgeInsets bannerPad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const double bannerDot = 9;
  static const EdgeInsets openKeyPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 10,
  );
  static const EdgeInsets callKeyPad = EdgeInsets.all(11);
  static const double teamGap = 12;
  static const EdgeInsets blankPad = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 60,
  );

  // 6f.
  static const double sheetSectionGap = 14;
  static const double changeRowGap = 10;
}
