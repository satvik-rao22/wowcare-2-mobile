import 'package:flutter/widgets.dart';

/// Measurements only M01's screens use, retyped from frames 1a to 2e.
///
/// Anything the whole app shares is in `AppSizes`; this file holds what is
/// particular to the sign-in lane and the kiosk, so no widget in the module
/// writes a number of its own.
abstract final class AuthSizes {
  // --- 1a Sign In -----------------------------------------------------------

  /// The brand mark above "Welcome back".
  static const double heroLogo = 64;
  static const double heroTopPad = 40;
  static const double heroGap = 9;

  /// The form sits 26 under the hero, 22 in from the edges.
  static const EdgeInsets formPad = EdgeInsets.fromLTRB(22, 26, 22, 0);
  static const double formGap = 12;

  /// The footer: the key, then the note under it.
  static const EdgeInsets footerPad = EdgeInsets.fromLTRB(22, 26, 22, 34);
  static const double footerGap = 14;

  /// The offline banner's inset from the screen edge.
  static const EdgeInsets bannerMargin = EdgeInsets.fromLTRB(20, 12, 20, 0);

  // --- 1b and 1c Scope ------------------------------------------------------

  static const EdgeInsets scopeHeaderPad = EdgeInsets.fromLTRB(22, 30, 22, 6);
  static const double scopeHeaderGap = 6;
  static const EdgeInsets scopeListPad = EdgeInsets.fromLTRB(20, 20, 20, 0);
  static const double scopeListGap = 11;
  static const EdgeInsets scopeFooterPad = EdgeInsets.fromLTRB(20, 20, 20, 34);

  /// 1c's rows: a 42px round badge, then the name over a sub-line.
  static const double schoolAvatar = 42;
  static const EdgeInsets schoolRowPad = EdgeInsets.all(16);
  static const double schoolRowGap = 13;
  static const double schoolTick = 18;
  static const double schoolListGap = 10;
  static const EdgeInsets searchPad = EdgeInsets.fromLTRB(20, 16, 20, 0);

  // --- 1d, 1e and 1f Password -----------------------------------------------

  /// 1d's lock tile and 1e's mail tile.
  static const double lockTile = 68;
  static const double lockGlyph = 30;
  static const double mailTile = 84;
  static const double mailGlyph = 36;
  static const double tileRadius = 28;

  static const EdgeInsets resetBodyPad = EdgeInsets.fromLTRB(22, 32, 22, 0);
  static const double resetBodyGap = 18;
  static const EdgeInsets resetFooterPad = EdgeInsets.fromLTRB(22, 22, 22, 34);
  static const double resetFooterGap = 12;

  static const EdgeInsets checkEmailPad = EdgeInsets.fromLTRB(30, 70, 30, 0);
  static const double checkEmailGap = 18;

  /// 1f's strength bar and the rule list under it.
  static const double strengthBar = 7;
  static const double ruleGap = 8;
  static const double ruleGlyph = 14;
  static const EdgeInsets rulesCardPad = EdgeInsets.all(18);
  static const double rulesCardGap = 12;

  // --- 2b The door screen ---------------------------------------------------

  static const double kioskLogo = 32;

  /// The mark on the screens behind the door (2d, 2e), which is a size up.
  static const double brandLogo = 40;
  static const EdgeInsets kioskHeaderPad = EdgeInsets.fromLTRB(18, 8, 18, 12);
  static const double kioskHeaderGap = 11;

  static const EdgeInsets qrHeadPad = EdgeInsets.fromLTRB(26, 14, 26, 0);
  static const double qrHeadGap = 6;

  /// The gap between the door screen's caption and the code under it.
  static const double qrTopGap = 6;

  /// The QR itself, and the frame it sits in.
  static const double qr = 164;
  static const EdgeInsets qrFramePad = EdgeInsets.all(6);
  static const double qrFrameBorder = 2;
  static const double qrImageRadius = 6;

  /// 2e's placeholder well, and the ring on the loading card.
  static const double qrPlaceholder = 150;
  static const double qrPlaceholderRadius = 18;
  static const EdgeInsets qrPlaceholderPad = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const double qrRing = 42;
  static const double qrRingStroke = 3;
  static const EdgeInsets qrCardPad = EdgeInsets.all(18);
  static const double qrCardGap = 12;
  static const double qrCardRadius = 24;

  static const EdgeInsets padDividerMargin = EdgeInsets.fromLTRB(20, 14, 20, 0);
  static const EdgeInsets pinTitlePad = EdgeInsets.fromLTRB(26, 13, 26, 0);

  /// The four PIN dots.
  static const double pinDot = 22;
  static const double pinDotBorder = 2;
  static const double pinDotGap = 14;
  static const EdgeInsets pinDotsPad = EdgeInsets.fromLTRB(0, 15, 0, 2);

  static const EdgeInsets pinNoticeMargin = EdgeInsets.fromLTRB(24, 8, 24, 0);
  static const EdgeInsets pinNoticePad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  /// The 3 by 4 pad: 11 between keys, 34 in from the edges.
  static const EdgeInsets padGridPad = EdgeInsets.fromLTRB(34, 14, 34, 0);
  static const double padGap = 11;
  static const double padKeyHeight = 58;

  static const EdgeInsets padFooterPad = EdgeInsets.fromLTRB(24, 12, 24, 28);
  static const double padFooterGap = 12;

  /// The leave-kiosk sheet's pad sits a little tighter than the door's.
  static const EdgeInsets sheetPadGridPad = EdgeInsets.symmetric(
    horizontal: 8,
  );

  // --- 2a The scanner -------------------------------------------------------

  static const EdgeInsets scannerHeaderPad = EdgeInsets.fromLTRB(20, 18, 20, 0);
  static const double scannerHeaderGap = 12;
  static const double scannerCloseTile = 38;
  static const double scannerCloseGlyph = 16;

  static const double viewfinder = 250;
  static const double viewfinderRadius = 28;
  static const double viewfinderCorner = 46;
  static const double viewfinderCornerRadius = 20;
  static const double viewfinderStroke = 4;
  static const double scanLine = 3;
  static const double scanLineInset = 14;
  static const double scanLineGlow = 18;
  static const EdgeInsets scannerBodyPad = EdgeInsets.symmetric(horizontal: 40);
  static const double scannerBodyGap = 26;
  static const EdgeInsets scannerFooterPad = EdgeInsets.fromLTRB(24, 0, 24, 32);
  static const double scannerKeyGap = 12;
  static const EdgeInsets scannerKeyPad = EdgeInsets.all(15);

  /// The translucent warm-white tiles on the navy scanner ground.
  static const double scannerTileAlpha = .12;
  static const double scannerTileBevelAlpha = .16;
  static const double scannerCaptionAlpha = .8;
  static const double scannerGlassAlpha = .06;
  static const double scanLineGlowAlpha = .55;
  static const double inRangeAlpha = .22;

  // --- 2c and 2d The family -------------------------------------------------

  static const EdgeInsets familyHeaderPad = EdgeInsets.fromLTRB(20, 22, 20, 0);
  static const EdgeInsets familyBodyPad = EdgeInsets.fromLTRB(18, 18, 18, 0);
  static const double familyGap = 11;
  static const EdgeInsets geofencePad = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const double geofenceGap = 10;
  static const double geofenceGlyph = 17;

  /// A pick card: a 26px check tile, a 46px avatar, the name over a line.
  static const EdgeInsets pickCardPad = EdgeInsets.all(16);
  static const double pickCardGap = 13;
  static const double pickCheck = 26;
  static const double pickCheckRadius = 9;
  static const double pickCheckGlyph = 15;
  static const double pickAvatar = 46;

  static const EdgeInsets recordedPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );
  static const double recordedGap = 4;

  static const EdgeInsets familyFooterPad = EdgeInsets.fromLTRB(18, 14, 18, 28);
  static const double familyFooterGap = 9;
  static const double familyKeyGap = 8;

  /// 2d's chooser: two tall pink keys, then the "On this PIN" well.
  static const EdgeInsets chooserPad = EdgeInsets.symmetric(horizontal: 24);
  static const double chooserGap = 16;
  static const EdgeInsets chooserKeyPad = EdgeInsets.symmetric(vertical: 22);
  static const EdgeInsets chooserHeaderPad = EdgeInsets.fromLTRB(24, 22, 24, 0);
  static const EdgeInsets onPinPad = EdgeInsets.all(16);
  static const double onPinGap = 9;
  static const double onPinRowGap = 10;
  static const double onPinAvatar = 32;
}
