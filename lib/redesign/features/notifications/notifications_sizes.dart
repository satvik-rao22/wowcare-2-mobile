import 'package:flutter/widgets.dart';

/// Measurements the M12 frames use that the core token layer does not carry.
/// Module-local by rule: core tokens belong to the core engineer.
abstract final class NotificationsSizes {
  // --- The screen -----------------------------------------------------------

  /// The toolbar under the chips: Mark all as read, then the unread switch.
  static const EdgeInsets toolbarPad = EdgeInsets.fromLTRB(18, 12, 18, 0);
  static const double toolbarGap = 10;

  /// The unread line under the title.
  static const EdgeInsets unreadLinePad = EdgeInsets.fromLTRB(18, 2, 18, 0);

  /// The gap above the filter chips, and above the list.
  static const double chipsTopPad = 12;
  static const EdgeInsets listPad = EdgeInsets.fromLTRB(18, 14, 18, 0);

  /// The gap between rows, and between a band and the row under it.
  static const double listGap = 11;
  static const double bandGap = 9;
  static const EdgeInsets bandPad = EdgeInsets.only(top: 8, bottom: 2);

  /// Mark all as read is a smaller face than a screen's one tall key.
  static const EdgeInsets markKeyPad = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 10,
  );

  /// The gap between the switch's label and the switch.
  static const double switchGap = 9;

  // --- A row ----------------------------------------------------------------

  static const EdgeInsets rowPad = EdgeInsets.all(16);
  static const double rowGap = 11;
  static const double rowTextGap = 4;

  /// A row's bubble. One rung under the everyday 44px avatar, which is what
  /// keeps four rows on the screen at once.
  static const double avatar = 40;

  /// The gap between the time and the module tag under a row's body.
  static const double metaGap = 9;

  /// The chevron, and the unread dot under it.
  static const double chevron = 17;
  static const double unreadDot = 10;
  static const double trailingGap = 8;

  // --- The states -----------------------------------------------------------

  /// How far down the body an empty or failed state sits.
  static const EdgeInsets emptyPad = EdgeInsets.fromLTRB(20, 52, 20, 20);

  /// The "one arrived" line over the list.
  static const EdgeInsets arrivedPad = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 11,
  );
  static const double arrivedGap = 9;
  static const double arrivedDot = 7;

  /// The footer that says the next page is on its way.
  static const EdgeInsets footerPad = EdgeInsets.symmetric(vertical: 16);
  static const double footerGap = 9;

  /// How close to the end of the list the next page is asked for.
  static const double pageTrigger = 400;

  // --- The skeleton ---------------------------------------------------------

  /// Three rows of it, which is what 12b draws.
  static const int skeletonRows = 3;
  static const double skeletonTitle = 11;
  static const double skeletonLine = 9;
  static const double skeletonBarRadius = 6;
  static const double skeletonGap = 8;

  /// The three bar widths, as a fraction of the row.
  static const List<double> skeletonWidths = <double>[.7, .9, .38];
}
