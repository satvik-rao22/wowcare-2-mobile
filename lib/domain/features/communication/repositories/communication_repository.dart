import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/data/features/communication/models/create_conversation_request.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

abstract class CommunicationRepository {
  Future<Either<Failure, List<Message>>> getMessages(
    String threadId, {
    String? currentUserId,
    int page = 0,
    int size = 100,
  });
  Future<Either<Failure, Message>> sendMessage(
    String threadId,
    Message message,
  );
  Future<Either<Failure, void>> markAsRead(String threadId, String messageId);

  /// Marks every unread message in [threadId] as delivered for the current
  /// user — called when a new message arrives via the realtime conversation
  /// watcher, even if the thread isn't open, so the sender's ticks advance
  /// promptly (mirrors the web app's `markAllAsDelivered`).
  Future<Either<Failure, void>> markAllAsDelivered(String threadId);
  Future<Either<Failure, void>> sendBulkMessage({
    required String text,
    required List<String> recipientIds,
    List<ChatAttachment> attachments = const [],
  });
  Future<Either<Failure, Conversation>> createConversation(
    CreateConversationRequest request,
  );
  Future<Either<Failure, ConversationsPage>> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  });
  Future<Either<Failure, List<Conversation>>> loadCachedConversations();
  Future<Either<Failure, List<Message>>> loadCachedMessages(String threadId, {String? currentUserId});
  Future<Either<Failure, void>> addReaction(
    String threadId,
    String messageCode,
    String emoji,
  );
  Future<Either<Failure, Message>> editMessage(
    String messageCode,
    String content,
  );
  Future<Either<Failure, void>> deleteMessage(String messageCode);
  Future<Either<Failure, void>> removeReaction(
    String messageCode,
    String emoji,
  );
  Future<Either<Failure, void>> deleteAttachment(int attachmentId);
  Future<Either<Failure, void>> clearMessagesCache(String threadId);
  Future<Either<Failure, void>> clearConversationsCache();

  /// Realtime delta stream for a conversation's messages, sourced from
  /// Firestore. Never replaces history — every emission is merged into the
  /// Isar cache (upsert by message code) and the merged, full cached list is
  /// re-emitted. Used purely as a "what changed" notification layer on top
  /// of the API → Isar → UI flow.
  ///
  /// [organizationCode]/[schoolCode] override the session's currently-active
  /// org/school for building the Firestore path — pass the conversation's
  /// own values when known. A stale/mismatched session org or school (e.g.
  /// a multi-school parent, or a recently-switched active school) builds a
  /// Firestore path that doesn't correspond to where this conversation's
  /// messages actually live, surfacing as a permission-denied error rather
  /// than simply empty results. Falls back to session resolution when
  /// omitted (unchanged prior behavior).
  Stream<List<Message>> watchMessages(
    String threadId, {
    String? organizationCode,
    String? schoolCode,
  });

  /// Realtime delta stream for the conversation list, sourced from
  /// Firestore's per-user inbox. Same merge-into-Isar semantics as
  /// [watchMessages] — only `unreadCount` / `lastMessage*` fields are
  /// updated; everything else is preserved from the API-sourced cache.
  Stream<List<Conversation>> watchConversations({String? type});
}
