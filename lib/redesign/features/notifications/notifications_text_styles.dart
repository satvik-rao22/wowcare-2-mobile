import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type the M12 frames draw that is not on the core ladder.
///
/// Sizes are the frame's own rem value times 16, exactly as `AppTextStyles`
/// writes them. No colour: colour is a `Colourway` decision the call site
/// makes out loud.
abstract final class NotificationsTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  /// A row's title while it is unread.
  static const TextStyle rowTitle = TextStyle(
    fontFamily: _font,
    fontSize: .87 * _px,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// The same title once it has been read: a weight lighter, and in ink2.
  static const TextStyle rowTitleRead = TextStyle(
    fontFamily: _font,
    fontSize: .87 * _px,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// The sentence under a row's title.
  static const TextStyle rowBody = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// "4 mins ago".
  static const TextStyle rowTime = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
  );

  /// "7 unread" under the title, and "All read".
  static const TextStyle unreadLine = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The line on the navy slab that says a push landed.
  static const TextStyle arrivedLine = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
  );

  /// "Loading more", at the foot of the list.
  static const TextStyle footerLabel = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );
}
