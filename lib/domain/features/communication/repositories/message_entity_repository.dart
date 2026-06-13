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
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationCode,
    required String text,
    List<String> attachmentCodes = const [],
    bool isPrivate = false,
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

  /// Remove completed / old sync operations from Isar.
  Future<Either<Failure, int>> cleanupSyncQueue({
    int olderThanDays = 7,
  });

  // ─── Cache management ───────────────────────────────────────────────────────

  /// Invalidate cached messages for a conversation.
  Future<Either<Failure, void>> clearMessagesCache(String conversationCode);
}
