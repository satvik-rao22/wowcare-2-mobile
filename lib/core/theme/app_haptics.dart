/// The app's haptic vocabulary: one call per kind of moment, so a press, a
/// toggle or a failure feels the same on every screen.
///
/// Each moment maps once to the platform's own feedback type:
///
/// * [tap]: a key was pressed. Confirm, cancel, add, a PIN digit.
/// * [select]: a value changed. A toggle flipped, an option picked.
/// * [warning] and [error]: an orange or red banner went up.
///   `CoreUtils.showTopSnackBar` plays these itself, so a screen that shows
///   a banner never calls them.
/// * [success]: a milestone finished. Green banners stay silent on purpose:
///   the press that led to them already played a [tap], and a second buzz a
///   moment later reads as a stutter.
///
/// Nothing here is awaited and nothing here throws. A device with no haptic
/// hardware, a user who turned system haptics off, or a widget test with no
/// engine behind the platform channel all get silence, never a broken action.
///
/// New code calls these, never [HapticFeedback] directly; the guard test in
/// `test/core/theme/centralized_theme_test.dart` enforces it. That also keeps
/// out `HapticFeedback.vibrate()`, which on iOS is the long notification
/// buzz, not a tap. The chat bubble's swipe-to-reply and reaction haptics
/// predate this file and are deliberately left as they were built.
library;

import 'dart:async';

import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  /// A key was pressed.
  static void tap() => _play(HapticFeedback.lightImpact);

  /// A value changed: a toggle flipped, an option picked.
  static void select() => _play(HapticFeedback.selectionClick);

  /// A milestone finished.
  static void success() => _play(HapticFeedback.successNotification);

  /// Something needs attention. Plays with an orange banner.
  static void warning() => _play(HapticFeedback.warningNotification);

  /// Something failed. Plays with a red banner.
  static void error() => _play(HapticFeedback.errorNotification);

  static void _play(Future<void> Function() feedback) {
    // A missing buzz must never surface as an error in the action it
    // accompanies, so any platform failure is dropped here.
    unawaited(feedback().catchError((Object _) {}));
  }
}
