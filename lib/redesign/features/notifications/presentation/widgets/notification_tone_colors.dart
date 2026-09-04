import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';

/// How a notification's tone lands on the colourway.
///
/// Colour here says what the notification is about, never who is looking:
/// teal for a student, sun for staff, green for money, pink for something a
/// person wrote, and the neutral alt-well for everything else. It is the
/// design's own module map, and the same one the shipped
/// `notification_category_style.dart` draws.
///
/// The pink is a tint, not a key. Pink as the one action on a screen is
/// spent on Mark all as read, and a tinted tag is not an action.
extension NotificationToneColors on NotificationTone {
  Color fill(Colourway c) => switch (this) {
    NotificationTone.student => c.studentBg,
    NotificationTone.staff => c.staffBg,
    NotificationTone.money => c.successBg,
    NotificationTone.message => c.pinkBg,
    NotificationTone.neutral => c.neutralBg,
  };

  Color ink(Colourway c) => switch (this) {
    NotificationTone.student => c.student,
    NotificationTone.staff => c.staffFg,
    NotificationTone.money => c.successFg,
    NotificationTone.message => c.onPinkTint,
    NotificationTone.neutral => c.ink,
  };
}
