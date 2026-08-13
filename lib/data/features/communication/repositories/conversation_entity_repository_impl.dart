import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/communication/datasources/conversation_entity_local_data_source.dart';
import 'package:wowcare/data/features/communication/datasources/conversation_entity_remote_data_source.dart';
import 'package:wowcare/data/features/communication/realtime/conversation_realtime_data_source.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

/// Implements [ConversationEntityRepository] with an offline-first strategy:
///
///   1. Return cached Isar data immediately (fast path).
///   2. Fetch from API in background and update cache.
///
/// Mirrors the pattern used in the existing [CommunicationRepositoryImpl].
class ConversationEntityRepositoryImpl implements ConversationEntityRepository {
  final ConversationEntityRemoteDataSource _remote;
  final ConversationEntityLocalDataSource _local;
  final ConversationRealtimeDataSource _realtime;
  final StorageService _storage;

  /// Conversation codes we've already tried to lazy-hydrate (see
  /// watchConversations). Prevents re-fetching the same missing item on every
  /// inbox emission. The repository is a singleton, so this is shared across
  /// all watchers (dashboard, list, unread badge).
  final Set<String> _hydrationAttempted = {};

  ConversationEntityRepositoryImpl({
    required ConversationEntityRemoteDataSource remoteDataSource,
    required ConversationEntityLocalDataSource localDataSource,
    required ConversationRealtimeDataSource realtimeDataSource,
    required StorageService storageService,
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _realtime = realtimeDataSource,
       _storage = storageService;

  // ─── Tenancy helpers ────────────────────────────────────────────────────────

  Future<String> get _orgCode async =>
      (await _storage.getString(StorageKeys.organizationCode)) ?? '';

  Future<String> get _schoolCode async =>
      (await _storage.getString(StorageKeys.schoolCode)) ?? '';

  Future<String> get _userCode async =>
      (await _storage.getString(StorageKeys.userCode))?.trim() ?? '';

  /// The REST `/conversations/type/{TYPE}` list's own `unreadCount` field
  /// (top-level, and on every `participants[]` entry) is confirmed always
  /// empty — the backend doesn't compute it there. `/messages/unread-per-
  /// conversation` is a separate, sibling endpoint to the aggregate-by-type
  /// one (`/messages/unread-summary`, already relied on for the top app
  /// bar's badge) that HAS been confirmed reliable against real traffic,
  /// but it only ever returns conversations with a NON-ZERO unread count.
  /// So a successful response that doesn't mention a conversation means
  /// that conversation has genuinely been read (0 unread) — not "unknown,
  /// guess from the participant field". The participant-field fallback is
  /// only appropriate when the endpoint call fails outright and there's no
  /// authoritative data at all.
  Future<List<ConversationEntity>> _resolveUnreadCounts(
    List<ConversationEntity> conversations,
  ) async {
    Map<String, int>? perConversation;
    try {
      perConversation = await _remote.getUnreadCountsPerConversation();
    } catch (_) {
      // Endpoint unreachable — fall through to the participant-field guess.
    }
    final userCode = await _userCode;
    return conversations.map((c) {
      if (perConversation != null) {
        return c.copyWith(unreadCount: perConversation[c.code] ?? 0);
      }
      if (userCode.isEmpty) return c;
      ParticipantEntity? mine;
      for (final p in c.participants) {
        if (p.userCode == userCode) {
          mine = p;
          break;
        }
      }
      if (mine == null) return c;
      return c.copyWith(unreadCount: mine.unreadCount);
    }).toList();
  }

  // ─── Queries ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    ConversationType? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
    bool? unreadOnly,
  }) async {
    try {
      final dtos = await _remote.getConversations(
        type: type,
        status: status,
        page: page,
        size: size,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        designations: designations,
        studentStatuses: studentStatuses,
        staffStatuses: staffStatuses,
        search: search,
        unreadOnly: unreadOnly,
      );
      final entities = await _resolveUnreadCounts(
        dtos.map((d) => d.toEntity()).toList(),
      );

      // Update Isar — replace page 0 entirely; append subsequent pages.
      // Note: When filters are applied, we always replace at page 0
      if (page == 0) {
        final org = await _orgCode;
        final school = await _schoolCode;
        await _local.clearConversations(
          organizationCode: org,
          schoolCode: school,
          type: type,
        );
      }
      await _local.saveConversations(entities);

      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> getCachedConversations({
    ConversationType? type,
  }) async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      final collections = await _local.getConversations(
        organizationCode: org,
        schoolCode: school,
        type: type,
      );
      return Right(collections.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity>> getConversation(
    String conversationCode,
  ) async {
    try {
      final dto = await _remote.getConversation(conversationCode);
      final entity = (await _resolveUnreadCounts([dto.toEntity()])).first;
      await _local.saveConversation(entity);
      return Right(entity);
    } catch (e) {
      // Network failed — try cache
      final cached = await _local.getConversation(conversationCode);
      if (cached != null) return Right(cached.toEntity());
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity?>> getCachedConversation(
    String conversationCode,
  ) async {
    try {
      final cached = await _local.getConversation(conversationCode);
      return Right(cached?.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessagingStaffResult>>> searchStaffForMessaging({
    required String query,
    required String organizationCode,
    required String schoolCode,
  }) async {
    try {
      final results = await _remote.searchStaffForMessaging(
        query: query,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity?>> findStaffDirectConversation(
    String recipientUserCode,
  ) async {
    try {
      final dto = await _remote.findStaffDirectConversation(recipientUserCode);
      if (dto == null) return const Right(null);
      final entity = dto.toEntity();
      await _local.saveConversation(entity);
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity?>> findRoomChatConversation({
    required String studentCode,
    String? classroomCode,
  }) async {
    try {
      final dto = await _remote.findRoomChatConversation(
        studentCode: studentCode,
        classroomCode: classroomCode,
      );
      if (dto == null) return const Right(null);
      final entity = dto.toEntity();
      await _local.saveConversation(entity);
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity?>> findAdminChatConversation({
    required String studentCode,
  }) async {
    try {
      final dto = await _remote.findAdminChatConversation(
        studentCode: studentCode,
      );
      if (dto == null) return const Right(null);
      final entity = dto.toEntity();
      await _local.saveConversation(entity);
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversationsForStudent(
    String studentCode,
  ) async {
    try {
      final dtos = await _remote.getConversationsForStudent(studentCode);
      final entities = dtos.map((d) => d.toEntity()).toList();
      await _local.saveConversations(entities);
      return Right(entities);
    } catch (e) {
      final org = await _orgCode;
      final school = await _schoolCode;
      final cached = await _local.getConversationsForStudent(
        studentCode: studentCode,
        organizationCode: org,
        schoolCode: school,
      );
      if (cached.isNotEmpty) {
        return Right(cached.map((c) => c.toEntity()).toList());
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>>
  getConversationsForClassroom(String classroomCode) async {
    try {
      final dtos = await _remote.getConversationsForClassroom(classroomCode);
      final entities = dtos.map((d) => d.toEntity()).toList();
      await _local.saveConversations(entities);
      return Right(entities);
    } catch (e) {
      final org = await _orgCode;
      final school = await _schoolCode;
      final cached = await _local.getConversationsForClassroom(
        classroomCode: classroomCode,
        organizationCode: org,
        schoolCode: school,
      );
      if (cached.isNotEmpty) {
        return Right(cached.map((c) => c.toEntity()).toList());
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> reconcileClassroomChat(
    String classroomCode, {
    String? classroomName,
  }) async {
    try {
      await _remote.reconcileClassroomChat(
        classroomCode: classroomCode,
        classroomName: classroomName,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  // ─── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ConversationEntity>> createConversation({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
    String title = '',
    String description = '',
    String avatarUrl = '',
  }) async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;

      // The backend only adds whoever is explicitly listed in
      // `participantUserCodes` — callers pass just the OTHER party's
      // code(s), so without the creator's own code added here, the
      // conversation gets created without them as a member. They'd then
      // get a 403 "not authorized" the moment they try to open the very
      // conversation they just started.
      final currentUserCode =
          (await _storage.getString(StorageKeys.userCode))?.trim() ?? '';
      final allParticipants = <String>{
        if (currentUserCode.isNotEmpty) currentUserCode,
        ...(participantCodes ?? const []),
      }.toList();

      final dto = await _remote.createConversation(
        type: type.toApiString(),
        studentCode: studentCode,
        classroomCode: classroomCode,
        participantCodes: allParticipants,
        organizationCode: org,
        schoolCode: school,
        title: title,
        description: description,
        avatarUrl: avatarUrl,
      );
      final entity = dto.toEntity();
      await _local.saveConversation(entity);
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<ParticipantEntity>>> addParticipants({
    required String conversationCode,
    required List<String> userCodes,
  }) async {
    try {
      final dtos = await _remote.addParticipants(
        conversationCode: conversationCode,
        userCodes: userCodes,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> removeParticipants({
    required String conversationCode,
    required List<String> userCodes,
  }) async {
    try {
      await _remote.removeParticipants(
        conversationCode: conversationCode,
        userCodes: userCodes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    try {
      await _remote.togglePrivateMode(
        conversationCode: conversationCode,
        enable: enable,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  // ─── Unread ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Map<String, int>>> getUnreadAggregates() async {
    try {
      final map = await _remote.getUnreadAggregates();
      return Right(map);
    } catch (e) {
      // Fall back to cached unread counts summed by type
      try {
        final org = await _orgCode;
        final school = await _schoolCode;
        final cached = await _local.getUnreadCounts(
          organizationCode: org,
          schoolCode: school,
        );
        final aggregated = <String, int>{};
        for (final u in cached) {
          aggregated[u.conversationType] =
              (aggregated[u.conversationType] ?? 0) + u.unreadCount;
        }
        return Right(aggregated);
      } catch (_) {
        return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
      }
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>>
  getUnreadCountsPerConversation() async {
    try {
      final map = await _remote.getUnreadCountsPerConversation();
      return Right(map);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getUnreadCountsByType() async {
    try {
      final map = await _remote.getUnreadCountsByType();
      return Right(map);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markConversationRead(
    String conversationCode,
  ) async {
    try {
      await _remote.markConversationRead(conversationCode);

      // Zero unreadCount in ConversationEntityCollection immediately so that
      // any subsequent Isar read (before Firestore confirms) returns 0.
      final cachedConv = await _local.getConversation(conversationCode);
      if (cachedConv != null) {
        final zeroed = cachedConv.toEntity();
        // Rebuild entity with unreadCount = 0. We reconstruct because
        // ConversationEntity is immutable (no copyWith on the domain class).
        await _local.saveConversation(
          ConversationEntity(
            id: zeroed.id,
            code: zeroed.code,
            type: zeroed.type,
            title: zeroed.title,
            description: zeroed.description,
            avatarUrl: zeroed.avatarUrl,
            status: zeroed.status,
            organizationCode: zeroed.organizationCode,
            schoolCode: zeroed.schoolCode,
            createdAt: zeroed.createdAt,
            createdBy: zeroed.createdBy,
            updatedAt: zeroed.updatedAt,
            updatedBy: zeroed.updatedBy,
            participantCount: zeroed.participantCount,
            unreadCount: 0,
            lastMessagePreview: zeroed.lastMessagePreview,
            lastMessageAt: zeroed.lastMessageAt,
            lastMessageBy: zeroed.lastMessageBy,
            lastMessageSenderName: zeroed.lastMessageSenderName,
            participants: zeroed.participants,
            studentCode: zeroed.studentCode,
            classroomCode: zeroed.classroomCode,
            privateModeStates: zeroed.privateModeStates,
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markConversationDelivered(
    String conversationCode,
  ) async {
    try {
      await _remote.markConversationDelivered(conversationCode);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<UnreadEntity>>> syncUnreadCounts() async {
    try {
      // Full per-conversation unread refresh requires a dedicated endpoint.
      // getUnreadAggregates returns type-level totals only.
      // Phase 1C use cases will orchestrate the per-conversation sync.
      await _remote.getUnreadAggregates();
      return Right([]);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> clearConversationsCache() async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      await _local.clearConversations(
        organizationCode: org,
        schoolCode: school,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Realtime streams (Firestore) ────────────────────────────────────────────

  @override
  Stream<List<ConversationEntity>> watchConversations({
    ConversationType? type,
  }) async* {
    final org = await _orgCode;
    final school = await _schoolCode;
    final user = (await _storage.getString(StorageKeys.userCode)) ?? '';

    yield* _realtime
        .watchInbox(
          organizationCode: org,
          schoolCode: school,
          userCode: user,
          filterType: type?.toApiString(),
        )
        .asyncMap((inboxItems) async {
          // For each Firestore inbox item, merge with the Isar-cached entity so
          // metadata fields (title, avatarUrl, participants) are preserved.
          var cached = await _local.getConversations(
            organizationCode: org,
            schoolCode: school,
            type: type,
          );
          var cacheMap = {for (final c in cached) c.code: c.toEntity()};

          // Lazy-hydrate metadata for inbox items not yet in Isar. The Firestore
          // inbox doc carries no title/participants, so an un-cached item would
          // fall to toMinimalEntity (empty title -> "Conversation" placeholder)
          // until the user opens it (which fetches + persists it). Fetch each
          // missing conversation once (guarded), persist to Isar, then reload the
          // cache so the merge below resolves the real title/roster on first load.
          final missing = <String>[];
          for (final item in inboxItems) {
            final code = item.conversationCode;
            if (!cacheMap.containsKey(code) &&
                !_hydrationAttempted.contains(code)) {
              _hydrationAttempted.add(code);
              missing.add(code);
            }
          }
          if (missing.isNotEmpty) {
            await Future.wait(
              missing.map((code) async {
                try {
                  final dto = await _remote.getConversation(code);
                  await _local.saveConversation(dto.toEntity());
                } catch (_) {
                  // Best-effort: leave the minimal entity if the fetch fails.
                }
              }),
            );
            cached = await _local.getConversations(
              organizationCode: org,
              schoolCode: school,
              type: type,
            );
            cacheMap = {for (final c in cached) c.code: c.toEntity()};
          }

          final merged = inboxItems.map((item) {
            final existing = cacheMap[item.conversationCode];
            // Firestore wins for unreadCount / lastMessage* fields.
            // Isar provides metadata (title, avatarUrl, participants).
            // Do NOT write back to Isar here — that caused a race condition when
            // both ConversationListCubit and UnreadBadgeCubit ran asyncMap
            // concurrently on the same records.
            if (existing != null) return item.mergeWith(existing);
            return item.toMinimalEntity(
              organizationCode: org,
              schoolCode: school,
            );
          }).toList();

          return merged;
        });
  }

  @override
  Stream<int> watchUnreadCountForType(ConversationType type) async* {
    final org = await _orgCode;
    final school = await _schoolCode;
    final user = (await _storage.getString(StorageKeys.userCode)) ?? '';

    yield* _realtime.watchUnreadCountForType(
      organizationCode: org,
      schoolCode: school,
      userCode: user,
      conversationType: type.toApiString(),
    );
  }

  @override
  Stream<int> watchUnreadCountForConversation(String conversationCode) async* {
    if (conversationCode.isEmpty) {
      yield 0;
      return;
    }
    final org = await _orgCode;
    final school = await _schoolCode;
    final user = (await _storage.getString(StorageKeys.userCode)) ?? '';

    yield* _realtime.watchUnreadCountForConversation(
      organizationCode: org,
      schoolCode: school,
      userCode: user,
      conversationCode: conversationCode,
    );
  }

  @override
  Stream<int> watchTotalUnreadCount() async* {
    final org = await _orgCode;
    final school = await _schoolCode;
    final user = (await _storage.getString(StorageKeys.userCode)) ?? '';

    yield* _realtime.watchTotalUnreadCount(
      organizationCode: org,
      schoolCode: school,
      userCode: user,
    );
  }
}
