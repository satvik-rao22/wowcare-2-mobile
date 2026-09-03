import 'package:flutter/widgets.dart';

/// The radius ladder. Every rounded corner in the app is one of these.
///
/// The ladder is what keeps the material consistent: a card is always rounder
/// than the rows inside it, and a chip is always tighter than both. A radius
/// that is not on this ladder is a bug.
abstract final class AppRadii {
  /// Cards, impact cards, and anything raised off the tray.
  static const double card = 20;

  /// Inner rows, wells, keys, icon tiles, segmented controls, fields.
  static const double inner = 16;

  /// The FAB, which is tighter than a key so the square reads as a square.
  static const double fab = 14;

  /// Chips and small tags.
  static const double chip = 12;

  /// A bottom sheet's top corners.
  static const double sheet = 28;

  /// The kiosk pad's keys and the toast, both a touch rounder than [inner].
  static const double pad = 18;

  /// An empty state's well-backed icon.
  static const double emptyIcon = 22;

  /// Pills, avatars, troughs, toggle tracks.
  static const double pill = 999;

  /// The 34px back key, one rung tighter than a 38px action key (5a, 7a).
  static const double backKey = 12;

  /// A checkbox (5a select mode).
  static const double check = 7;

  /// A bottom sheet's grabber.
  static const double grabber = 3;

  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius innerR = BorderRadius.all(Radius.circular(inner));
  static const BorderRadius backKeyR = BorderRadius.all(
    Radius.circular(backKey),
  );
  static const BorderRadius checkR = BorderRadius.all(Radius.circular(check));
  static const BorderRadius grabberR = BorderRadius.all(
    Radius.circular(grabber),
  );
  static const BorderRadius fabR = BorderRadius.all(Radius.circular(fab));
  static const BorderRadius chipR = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius padR = BorderRadius.all(Radius.circular(pad));
  static const BorderRadius emptyIconR = BorderRadius.all(
    Radius.circular(emptyIcon),
  );
  static const BorderRadius pillR = BorderRadius.all(Radius.circular(pill));

  /// A sheet is rounded on top only. Its bottom meets the screen edge.
  static const BorderRadius sheetR = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
