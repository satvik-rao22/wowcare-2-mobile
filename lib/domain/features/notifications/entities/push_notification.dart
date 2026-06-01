import 'package:equatable/equatable.dart';

/// A push notification parsed into the domain model the app reacts to.
///
/// [title]/[body] are the human-visible parts shown by the OS. [action]/[type]
/// and the raw [data] map carry the structured payload the app uses for routing
/// and business logic (e.g. `action=EDIT_CLASSROOM`, `classroomCode=...`).
class PushNotification extends Equatable {
  const PushNotification({
    required this.title,
    required this.body,
    required this.action,
    required this.type,
    required this.data,
    this.messageId,
  });

  final String? title;
  final String? body;
  final String? action;
  final String? type;
  final Map<String, String> data;
  final String? messageId;

  String? get classroomCode => data['classroomCode'];
  String? get classroomName => data['classroomName'];

  @override
  List<Object?> get props => [title, body, action, type, data, messageId];
}
