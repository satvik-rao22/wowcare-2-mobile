import 'package:equatable/equatable.dart';

/// A single emoji reaction placed by one user on one message.
///
/// Maps 1:1 to a backend reaction row (`UNIQUE(message_id, user_code, emoji)`),
/// a Firestore reactions-array element, and an Isar
/// `MessageReactionEntityCollection`/`MessageReactionCollection` entry.
///
/// A user may hold MULTIPLE distinct emoji reactions on the same message; each
/// distinct emoji is a separate [ReactionEntry]. The same (userCode, emoji)
/// pair must never appear twice.
class ReactionEntry extends Equatable {
  const ReactionEntry({
    required this.userCode,
    required this.emoji,
    this.role,
    this.userName,
  });

  final String userCode;
  final String emoji;

  /// Raw backend role string (e.g. `"STAFF"`, `"PARENT"`) the reactor was
  /// acting AS when they placed this reaction — the REST payload carries
  /// this per-reaction (`role`/`userRole`), so a dual-role account's reaction
  /// doesn't need to be guessed from the participant list. Null for
  /// realtime/Firestore-sourced reactions, which don't carry this field.
  final String? role;

  /// The reactor's display name, when the payload carries one.
  final String? userName;

  /// Case-insensitive, whitespace-trimmed match on the reacting user.
  bool matchesUser(String otherUserCode) =>
      userCode.trim().toLowerCase() == otherUserCode.trim().toLowerCase();

  @override
  List<Object?> get props => [userCode, emoji, role, userName];
}
