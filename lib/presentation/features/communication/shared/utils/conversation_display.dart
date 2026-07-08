import 'package:wowcare/domain/features/communication/entities/conversation.dart';

/// Viewer-relative display helpers for conversations.
///
/// A STAFF_DIRECT (1:1) conversation carries a fixed `title` chosen at creation
/// time — the creator's counterpart name. Rendering that stored title verbatim
/// leaks the creator's own name to the other side: e.g. when "Uttam Singh"
/// starts a chat with "Atoconn Test", the title is frozen to "Atoconn Test",
/// so "Atoconn Test" then sees their OWN name in the list row and chat header
/// instead of "Uttam Singh".
///
/// For 1:1 chats the row/header must therefore resolve the OTHER participant
/// relative to the logged-in user, not use the stored title. Group chats
/// (ROOM_CHAT / ADMIN_CHAT) keep their stored title (the room/student name).
class ConversationDisplay {
  ConversationDisplay._();

  /// STAFF_DIRECT is the only one-to-one conversation type; every other type is
  /// a group/room whose stored title is the correct label.
  static bool isDirect(String type) => type.trim().toUpperCase() == 'STAFF_DIRECT';

  /// The other participant in a 1:1 conversation (userCode != [currentUserCode]),
  /// preferring an active one with a name. Null when it can't be resolved (not a
  /// direct chat, unknown current user, or no counterpart in the roster yet).
  static ConversationParticipant? otherParticipant(
    Conversation c,
    String? currentUserCode,
  ) {
    if (!isDirect(c.type)) return null;
    final me = currentUserCode?.trim() ?? '';
    if (me.isEmpty || c.participants.isEmpty) return null;
    final others =
        c.participants.where((p) => p.userCode.trim() != me).toList();
    if (others.isEmpty) return null;
    // Prefer an active participant with a non-empty name.
    others.sort((a, b) {
      final an = (a.isActive ? 0 : 1) + (a.userName.trim().isEmpty ? 2 : 0);
      final bn = (b.isActive ? 0 : 1) + (b.userName.trim().isEmpty ? 2 : 0);
      return an.compareTo(bn);
    });
    return others.first;
  }

  /// Name to show for a conversation row / thread header. For 1:1 chats this is
  /// the other participant's name; otherwise the stored title. [fallback] is
  /// used when neither can be resolved (e.g. a just-created chat whose roster
  /// hasn't synced yet, where the caller already knows the counterpart name).
  static String name(
    Conversation c,
    String? currentUserCode, {
    String? fallback,
  }) {
    final other = otherParticipant(c, currentUserCode);
    if (other != null && other.userName.trim().isNotEmpty) {
      return other.userName.trim();
    }
    if (c.title.trim().isNotEmpty) return c.title.trim();
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
    return 'Unnamed Conversation';
  }

  /// Avatar source for a conversation row — the other participant's avatar for
  /// 1:1 chats (so the photo matches the name), else the conversation avatar.
  static String avatar(Conversation c, String? currentUserCode) {
    final other = otherParticipant(c, currentUserCode);
    final otherAvatar = other?.avatarUrl?.trim() ?? '';
    if (otherAvatar.isNotEmpty) return otherAvatar;
    return c.avatarUrl;
  }
}
