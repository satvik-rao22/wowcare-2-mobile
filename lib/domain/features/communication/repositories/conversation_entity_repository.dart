import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';

/// Repository contract for conversation data in the communication v2.1 module.
///
/// Implementations follow the WowCare offline-first pattern:
///   1. Return cached Isar data immediately (fast path).
///   2. Refresh from backend API in the background.
///   3. Update Isar and notify listeners.
///
/// The existing [CommunicationRepository] is preserved untouched.
/// New cubits and screens use this interface.
abstract class ConversationEntityRepository {
  // ─── Queries ────────────────────────────────────────────────────────────────

  /// Fetch conversations for the current user, filtered by type.
  ///
  /// Returns cached data first, then refreshes from API.
  /// Callers should call [getCachedConversations] for immediate cache reads
  /// and subscribe to updates via a Cubit that calls this in background.
  ///
  /// [type] — null returns all accessible types for current user role.
  /// [page] / [size] — pagination parameters.
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    ConversationType? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  });

  /// Return conversations directly from Isar (no network call).
  /// Used for initial screen render before the API refresh completes.
  Future<Either<Failure, List<ConversationEntity>>> getCachedConversations({
    ConversationType? type,
  });

  /// Fetch a single conversation with full participant list.
  Future<Either<Failure, ConversationEntity>> getConversation(
    String conversationCode,
  );

  /// Return a single conversation from Isar cache.
  Future<Either<Failure, ConversationEntity?>> getCachedConversation(
    String conversationCode,
  );

  // ─── Staff-direct helpers ────────────────────────────────────────────────────

  /// Returns the existing STAFF_DIRECT conversation between the current user
  /// and [recipientUserCode], or null when none exists.
  ///
  /// Use this before [createConversation] to avoid duplicate 1:1 threads.
  Future<Either<Failure, ConversationEntity?>> findStaffDirectConversation(
    String recipientUserCode,
  );

  /// Returns the existing active ROOM_CHAT conversation for [studentCode],
  /// optionally narrowed to [classroomCode], or null when none exists.
  ///
  /// Use this before [createConversation] to avoid duplicate per-student
  /// (or per-classroom, when known) rooms.
  Future<Either<Failure, ConversationEntity?>> findRoomChatConversation({
    required String studentCode,
    String? classroomCode,
  });

  /// Returns the existing active ADMIN_CHAT conversation for [studentCode],
  /// or null when none exists.
  ///
  /// Use this before [createConversation] to avoid duplicate admin threads
  /// for the same student.
  Future<Either<Failure, ConversationEntity?>> findAdminChatConversation({
    required String studentCode,
  });

  /// Search active and upcoming staff by name fragment.
  ///
  /// Used by the Staff Messaging inbox to start a new conversation with a
  /// staff member who has no existing thread with the current user.
  Future<Either<Failure, List<MessagingStaffResult>>> searchStaffForMessaging({
    required String query,
    required String organizationCode,
    required String schoolCode,
  });

  // ─── Student-scoped helpers ─────────────────────────────────────────────────

  /// All conversations (ROOM_CHAT + ADMIN_CHAT) for a specific student.
  /// Used in parent and admin views.
  Future<Either<Failure, List<ConversationEntity>>> getConversationsForStudent(
    String studentCode,
  );

  /// All ROOM_CHAT conversations for a specific classroom.
  /// Used in teacher and staff views.
  Future<Either<Failure, List<ConversationEntity>>> getConversationsForClassroom(
    String classroomCode,
  );

  // ─── Mutations ──────────────────────────────────────────────────────────────

  /// Create a new conversation.
  ///
  /// [type] must be ROOM_CHAT or ADMIN_CHAT; STAFF_DIRECT is created via
  /// [StaffMessagingRepository.createOrGetDirectConversation].
  ///
  /// [participantCodes] is optional — the backend auto-selects participants
  /// when null (parents of student, classroom staff, admins).
  ///
  /// Failure types:
  ///   [AuthorizationFailure] — caller lacks permission to create this type.
  ///   [ValidationFailure]    — invalid participant roles for type.
  ///   [NetworkFailure]       — no connectivity; operation is NOT queued.
  Future<Either<Failure, ConversationEntity>> createConversation({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
    String title = '',
    String description = '',
    String avatarUrl = '',
  });

  /// Add participants to an existing conversation (admin/director only).
  ///
  /// Failure types:
  ///   [AuthorizationFailure] — caller is not admin/director.
  ///   [ValidationFailure]    — participant role not allowed for conversation type.
  Future<Either<Failure, List<ParticipantEntity>>> addParticipants({
    required String conversationCode,
    required List<String> userCodes,
  });

  /// Remove participants from a conversation (admin/director only).
  Future<Either<Failure, void>> removeParticipants({
    required String conversationCode,
    required List<String> userCodes,
  });

  /// Enable or disable private mode for the current user in a conversation.
  ///
  /// Only the original enabler (or admin/director) can set [enable] = false.
  ///
  /// Offline behaviour: queued in [SyncQueueCollection]; applied optimistically
  /// to Isar. Retried on reconnect.
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  });

  // ─── Unread ─────────────────────────────────────────────────────────────────

  /// Aggregate unread counts by conversation type.
  /// Returns a map of [ConversationType.toApiString()] → total unread.
  /// Used to populate drawer badges.
  Future<Either<Failure, Map<String, int>>> getUnreadAggregates();

  /// Mark all messages in a conversation as read for the current user.
  ///
  /// Offline behaviour: queued and retried on reconnect.
  Future<Either<Failure, void>> markConversationRead(String conversationCode);

  /// Marks every unread message in [conversationCode] as delivered for the
  /// current user — called on a new incoming message even if the thread
  /// isn't open, so the sender's ticks advance promptly.
  Future<Either<Failure, void>> markConversationDelivered(
    String conversationCode,
  );

  /// Sync unread counts from the backend (called on reconnect).
  Future<Either<Failure, List<UnreadEntity>>> syncUnreadCounts();

  // ─── Cache management ───────────────────────────────────────────────────────

  /// Invalidate cached conversations, forcing a fresh API fetch.
  Future<Either<Failure, void>> clearConversationsCache();

  // ─── Realtime streams (Firestore) ────────────────────────────────────────────

  /// Realtime stream of conversations for the current user.
  ///
  /// Firestore is the source of truth for [unreadCount], [lastMessagePreview],
  /// and [lastMessageAt]. Isar provides metadata (title, avatarUrl).
  /// [type] — when non-null, filters to a specific [ConversationType].
  Stream<List<ConversationEntity>> watchConversations({
    ConversationType? type,
  });

  /// Lightweight per-type unread sum — reads Firestore only, no Isar merge.
  /// Use this in badge cubits to avoid duplicating the full stream pipeline.
  Stream<int> watchUnreadCountForType(ConversationType type);

  /// Realtime stream of total unread count across all conversations.
  Stream<int> watchTotalUnreadCount();
}
