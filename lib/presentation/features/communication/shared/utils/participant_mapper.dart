import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';

/// Maps the v2 [ParticipantEntity] (returned by
/// `CreateOrOpenConversationUseCase`/`GetConversationEntityUseCase`) to the
/// legacy [ConversationParticipant] shape `ParentMessagingThread` and
/// `StaffMessagingThread` expect.
///
/// Single shared mapper — previously duplicated across
/// `staff_messaging_tab.dart` and `parent_direct_messaging_screen.dart`,
/// each with their own slightly different field list. Consolidated here so
/// future fields (e.g. the new `staffCode`/`guardianCode`/`adminCode` on
/// [ParticipantEntity]) only need to be added in one place.
ConversationParticipant legacyParticipantFromEntity(ParticipantEntity p) {
  return ConversationParticipant(
    id: p.id,
    conversationId: p.conversationId,
    userCode: p.userCode,
    userName: p.userName,
    role: p.role.toApiString(),
    joinedAt: p.joinedAt,
    leftAt: p.leftAt,
    lastReadAt: p.lastReadAt,
    muted: p.muted,
    notificationsEnabled: p.notificationsEnabled,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
    avatarUrl: p.avatarUrl,
    staffCode: p.staffCode,
  );
}

List<ConversationParticipant> legacyParticipantsFromEntities(
  List<ParticipantEntity> participants,
) => participants.map(legacyParticipantFromEntity).toList();
