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

  /// Org/school the notification belongs to. A multi-school user may receive a
  /// push for a school other than the one currently selected — the app switches
  /// to it before redirecting. Backend may send camelCase or snake_case.
  String? get organizationCode =>
      data['organizationCode'] ?? data['orgCode'] ?? data['organization_code'];
  String? get schoolCode => data['schoolCode'] ?? data['school_code'];

  @override
  List<Object?> get props => [title, body, action, type, data, messageId];
}
