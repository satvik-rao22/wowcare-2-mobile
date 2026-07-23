import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';

/// Repository contract for message data in the communication v2.1 module.
///
/// Backend API is the source of truth.
/// Isar is the local cache.
/// Firestore triggers selective API refreshes (see [RealtimeRepository]).
///
/// The existing [CommunicationRepository] is preserved untouched.
abstract class MessageEntityRepository {
  // ─── Queries ────────────────────────────────────────────────────────────────

  /// Fetch messages for a conversation, newest first.
  ///
  /// [beforeMessageCode] — for backwards pagination (older messages).
  /// [size] — number of messages per page.
  ///
  /// Returns cached data first, then refreshes from API.
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String conversationCode,
    String? beforeMessageCode,
    int size = 50,
  });

  /// Return messages directly from Isar (no network call).
  Future<Either<Failure, List<MessageEntity>>> getCachedMessages(
    String conversationCode, {
    String? currentUserCode,
  });

  // ─── Send / Edit / Delete ───────────────────────────────────────────────────

  /// Send a new message.
  ///
  /// Offline behaviour (no connectivity):
  ///   1. Create [MessageEntity] with [MessageStatus.pending] and a local temp code.
  ///   2. Persist to Isar immediately so the UI can show it.
  ///   3. Add to [SyncQueueCollection] for retry.
  ///   4. Return the optimistic entity so the cubit can emit it.
  ///
  /// Online behaviour:
  ///   1. POST to API.
  ///   2. On success: replace temp code with real code, set status = sent.
  ///   3. On failure: set status = failed, add to sync queue.
  ///
  /// [isPrivate] — sends within the sender's private mode session.
  ///   Backend enforces visibility; the client sends the flag and renders
  ///   only what the API returns.
  ///
  /// [attachmentIds] — messaging-service attachment ids (see
  /// [AttachmentEntity.attachmentId]), already uploaded and registered
  /// against [conversationCode] by the caller before this is invoked (see
  /// `ChatAttachmentUploader`). Not document-service asset codes.
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationCode,
    required String text,
    List<int> attachmentIds = const [],
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
  });

  /// Edit a message the current user sent (admin/director may edit any).
  ///
  /// Offline behaviour: queued; optimistic Isar update.
  ///
  /// Failure types:
  ///   [AuthorizationFailure] — caller is not the sender or admin/director.
  ///   [NotFoundFailure]      — message deleted.
  Future<Either<Failure, MessageEntity>> editMessage({
    required String messageCode,
    required String newText,
  });

  /// Soft-delete a message.
  ///
  /// Offline behaviour: queued; message removed from Isar immediately
  /// (replaced with deleted placeholder in UI).
  ///
  /// Failure types:
  ///   [AuthorizationFailure] — caller is not sender or admin/director.
  Future<Either<Failure, void>> deleteMessage(String messageCode);

  /// Removes a single attachment from [messageCode] without deleting the
  /// whole message — mirrors legacy `CommunicationRepository.deleteAttachment`,
  /// reusing the same `DELETE /messages/attachments/{id}` endpoint.
  ///
  /// Offline behaviour: optimistic Isar update, rolled back on failure (no
  /// sync-queue entry — matches legacy's exact behaviour for this operation).
  Future<Either<Failure, void>> deleteAttachment({
    required String messageCode,
    required int attachmentId,
  });

  /// Retry sending a message that has [MessageStatus.failed].
  Future<Either<Failure, MessageEntity>> retryFailedMessage(
    String localTempCode,
  );

  // ─── Reactions ──────────────────────────────────────────────────────────────

  /// Add an emoji reaction to a message.
  ///
  /// Offline behaviour: queued; optimistic Isar update.
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  });

  /// Remove the current user's reaction from a message.
  ///
  /// Offline behaviour: queued; optimistic Isar update.
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  });

  // ─── Read receipts ──────────────────────────────────────────────────────────

  /// Mark a message as read by the current user.
  ///
  /// Fire-and-forget for online; silently ignored when offline
  /// (not critical enough to queue).
  Future<Either<Failure, void>> markMessageRead(String messageCode);

  // ─── Search ─────────────────────────────────────────────────────────────────

  /// Full-text prefix search within a conversation using the Isar [textPlain] index.
  /// Does not make a network call.
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String conversationCode,
    required String query,
    int limit = 20,
  });

  // ─── Offline sync ───────────────────────────────────────────────────────────

  /// Return all pending [SyncQueueEntity] items for the current user/school.
  Future<Either<Failure, List<SyncQueueEntity>>> getPendingSyncOperations();

  /// Marks a queued sync operation as successfully replayed. Thin
  /// pass-through to the already-implemented
  /// `MessageEntityLocalDataSource.markOperationCompleted` — exposed here so
  /// `DrainSyncQueueUseCase` (which already called this) compiles.
  Future<Either<Failure, void>> markSyncOperationCompleted(int id);

  /// Marks a queued sync operation as terminally failed (attempt ceiling
  /// reached) so it stops being retried. Pass-through to
  /// `MessageEntityLocalDataSource.markOperationFailed`.
  Future<Either<Failure, void>> markSyncOperationFailed({
    required int id,
    required String error,
    required int attempts,
  });

  /// Remove completed / old sync operations from Isar.
  Future<Either<Failure, int>> cleanupSyncQueue({
    int olderThanDays = 7,
  });

  // ─── Cache management ───────────────────────────────────────────────────────

  /// Invalidate cached messages for a conversation.
  Future<Either<Failure, void>> clearMessagesCache(String conversationCode);

  // ─── Realtime streams (Firestore) ────────────────────────────────────────────

  /// Realtime stream of messages for a conversation, oldest-first.
  ///
  /// Falls back to an empty stream if Firestore has no messages subcollection
  /// for this conversation — callers must handle empty gracefully and load
  /// from the API path instead.
  ///
  /// [organizationCode]/[schoolCode] override the session's currently-active
  /// org/school for building the Firestore path — pass the conversation's
  /// own values when known (e.g. `state.conversation?.organizationCode`).
  /// A stale/mismatched session org or school builds a Firestore path that
  /// doesn't correspond to where this conversation's messages actually
  /// live, surfacing as a permission-denied error rather than just empty
  /// results. Falls back to session resolution when omitted.
  Stream<List<MessageEntity>> watchMessages({
    required String conversationCode,
    int limit = 100,
    String? organizationCode,
    String? schoolCode,
  });
}
