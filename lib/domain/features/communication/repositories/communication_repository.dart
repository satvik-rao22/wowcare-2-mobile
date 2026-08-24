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

  /// [classroomCodes]/[tagCodes] — ROOM_CHAT student filters.
  /// [designations]/[staffStatuses] — STAFF_DIRECT filters. Mirrors the
  /// backend's getConversationsByType query contract exactly.
  Future<Either<Failure, ConversationsPage>> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
  });

  /// Server-side search across ALL of the account's conversations of [type]
  /// matching [query] — not limited to whatever's already loaded/cached
  /// client-side. Read-only: unlike [getConversations], results are never
  /// written to the conversations cache.
  Future<Either<Failure, List<Conversation>>> searchConversations({
    required String query,
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 50,
  });
  Future<Either<Failure, List<Conversation>>> loadCachedConversations();
  Future<Either<Failure, List<Message>>> loadCachedMessages(
    String threadId, {
    String? currentUserId,
  });

  /// Persists [message] (typically a [Message.isSending] or
  /// [Message.isFailed] optimistic bubble) into the local cache immediately —
  /// independent of [sendMessage]'s own post-success cache write — so an
  /// in-flight or failed send (including its local attachment previews)
  /// survives navigating away, the thread's cubit being recreated, or the
  /// app being killed before the server confirms it.
  Future<Either<Failure, void>> cacheMessage(String threadId, Message message);

  /// Removes a single cached draft row by [messageId] (its [Message.id],
  /// the local temp id assigned before the server confirms) — used once a
  /// send finally succeeds, since [sendMessage] caches the *confirmed*
  /// message under its real server code rather than overwriting the draft
  /// row, which would otherwise leave a stale duplicate behind.
  Future<Either<Failure, void>> discardCachedMessage(String messageId);
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

  /// Per-conversation unread counts, keyed by conversation code.
  ///
  /// Backed by `/messages/unread-per-conversation` — confirmed reliable
  /// (unlike the conversation-list endpoint's own `unreadCount` field, which
  /// the backend never actually populates).
  Future<Either<Failure, Map<String, int>>> getUnreadCountsPerConversation();

  /// Full per-recipient-per-persona receipts for one message, fetched
  /// on-demand for the Message Info dialog — see
  /// [ApiPaths.messagingMessageReceipts]'s doc comment.
  Future<
    Either<
      Failure,
      ({List<RecipientStatus> deliveredTo, List<RecipientStatus> readBy})
    >
  >
  getMessageReceipts(String messageCode);

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
