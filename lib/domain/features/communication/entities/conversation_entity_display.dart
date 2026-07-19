import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

/// Viewer-relative display helpers for [ConversationEntity].
///
/// A STAFF_DIRECT (1:1) conversation carries a `title` frozen at creation time
/// to the creator's counterpart name — rendering it verbatim shows the other
/// side their OWN name. So 1:1 rows must resolve the OTHER participant relative
/// to the logged-in user. Group chats (ROOM_CHAT / ADMIN_CHAT / CLASSROOM_CHAT)
/// keep their stored title (the student / room / classroom name).
///
/// This lives in the domain layer so every surface (dashboard, messaging list,
/// thread header) derives the same title from a single rule.
extension ConversationEntityDisplay on ConversationEntity {
  /// The other participant in a 1:1 conversation (userCode != [currentUserCode]),
  /// preferring an active (`leftAt == null`), named one. Null when it can't be
  /// resolved (not a direct chat, unknown current user, or empty roster).
  ParticipantEntity? otherParticipant(String? currentUserCode) {
    if (type != ConversationType.staffDirect) return null;
    final me = currentUserCode?.trim() ?? '';
    if (me.isEmpty || participants.isEmpty) return null;
    final others = participants.where((p) => p.userCode.trim() != me).toList();
    if (others.isEmpty) return null;
    // Prefer an active participant with a non-empty name (lower score = better).
    int score(ParticipantEntity p) =>
        (p.leftAt == null ? 0 : 1) + (p.userName.trim().isEmpty ? 2 : 0);
    others.sort((a, b) => score(a).compareTo(score(b)));
    return others.first;
  }

  /// Title to show for a conversation row / thread header. For 1:1 chats this is
  /// the other participant's name; otherwise the stored title. Falls back to
  /// [fallback] so the UI never renders an empty label.
  String displayTitle(String? currentUserCode, {String fallback = 'Conversation'}) {
    final other = otherParticipant(currentUserCode);
    if (other != null && other.userName.trim().isNotEmpty) {
      return other.userName.trim();
    }
    if (title.trim().isNotEmpty) return title.trim();
    return fallback;
  }
}
