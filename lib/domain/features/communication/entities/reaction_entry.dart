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
  });

  final String userCode;
  final String emoji;

  /// Case-insensitive, whitespace-trimmed match on the reacting user.
  bool matchesUser(String otherUserCode) =>
      userCode.trim().toLowerCase() == otherUserCode.trim().toLowerCase();

  @override
  List<Object?> get props => [userCode, emoji];
}
