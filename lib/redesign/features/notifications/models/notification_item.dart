import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/notifications/models/notification_module.dart';

/// One row of the inbox.
///
/// Mirrors the shipped `AppNotification` field for field, with two changes
/// that make the redesign's row drawable: [module] is the design's wider
/// module set rather than the three-value `NotificationCategory` (the shipped
/// card already reads `data['module']` for its chip, so this is the value it
/// actually draws), and the routing payload is narrowed to the two fields the
/// destination table needs, [action] and [targetCode], instead of a loose
/// string map.
@immutable
class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.module,
    required this.action,
    required this.createdAt,
    this.subjectName = '',
    this.isRead = false,
    this.targetCode,
  });

  final String id;
  final String title;

  /// The sentence under the title. Empty draws nothing.
  final String body;

  /// Who or what this is about: a student, a staff member, a classroom, a
  /// family. Drives the initials in the row's bubble.
  final String subjectName;

  final NotificationModule module;

  /// The backend's canonical `action`, from `NotificationAction`. It is what
  /// decides where a tap lands.
  final String action;

  /// The record the action is about: a student, staff, classroom or invoice
  /// code. Null when the notification is about the module as a whole.
  final String? targetCode;

  final DateTime createdAt;
  final bool isRead;

  /// One or two letters for the row's bubble.
  String get initials {
    final parts = subjectName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    subjectName: subjectName,
    module: module,
    action: action,
    targetCode: targetCode,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    subjectName,
    module,
    action,
    targetCode,
    createdAt,
    isRead,
  ];
}
