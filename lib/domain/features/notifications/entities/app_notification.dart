import 'package:equatable/equatable.dart';

import 'notification_category.dart';

/// A single item in the in-app notification center (the list opened from the
/// app-bar bell).
///
/// This is distinct from [PushNotification] (the FCM transport model): a
/// [PushNotification] is a message arriving from the OS, whereas an
/// [AppNotification] is a persisted, categorised, read/unread record the user
/// browses. The optional [data] map carries any structured payload (e.g.
/// `staffName`, `classroomCode`) used for deep-link routing on tap.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.isRead,
    this.body,
    this.subjectName,
    this.data = const <String, String>{},
  });

  final String id;
  final String title;
  final String? body;

  /// The person/entity this notification is about (e.g. "Parker Long"). Drives
  /// the avatar initials in the list. Null when not applicable.
  final String? subjectName;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, String> data;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      subjectName: subjectName,
      category: category,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    subjectName,
    category,
    createdAt,
    isRead,
    data,
  ];
}
