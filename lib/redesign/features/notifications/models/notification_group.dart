import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/notifications/models/notification_item.dart';

/// The day band a row sits under: 12a's TODAY and YESTERDAY rules, plus the
/// EARLIER one the frame never reaches because it only draws two days.
enum NotificationDay { today, yesterday, earlier }

/// A day band and the rows under it, in the order the inbox returned them.
@immutable
class NotificationGroup extends Equatable {
  const NotificationGroup({required this.day, required this.items});

  final NotificationDay day;
  final List<NotificationItem> items;

  @override
  List<Object?> get props => [day, items];
}
