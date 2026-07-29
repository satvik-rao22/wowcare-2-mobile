import 'dart:async';

import 'package:dartz/dartz.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/school_timezone_resolver.dart';
import '../../../../core/util/school_zone_datetime.dart';
import '../../../../core/util/storage_keys.dart';
import '../datasources/communication_remote_data_source.dart';
import '../models/message_collection.dart';
import '../models/message_model.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../domain/features/communication/entities/message_entity.dart';
import '../../../../domain/features/communication/repositories/communication_repository.dart';
import '../../../../domain/features/communication/entities/conversation.dart';
import '../models/conversation_collection.dart';
import '../models/create_conversation_request.dart';
import 'package:wowcare/core/util/app_time.dart';
import '../realtime/conversation_realtime_data_source.dart';
import '../realtime/message_realtime_data_source.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final CommunicationRemoteDataSource remoteDataSource;
  final CacheService cacheService;
  final ConversationRealtimeDataSource conversationRealtimeDataSource;
  final MessageRealtimeDataSource messageRealtimeDataSource;
  final StorageService storageService;

  CommunicationRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
    required this.conversationRealtimeDataSource,
    required this.messageRealtimeDataSource,
    required this.storageService,
  });

  Future<String> get _organizationCode async =>
      (await storageService.getString(StorageKeys.organizationCode))?.trim() ??
      '';
  Future<String> get _schoolCode async =>
      (await storageService.getString(StorageKeys.schoolCode))?.trim() ?? '';
  Future<String> get _userCode async =>
      (await storageService.getString(StorageKeys.userCode))?.trim() ?? '';

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    String threadId, {
    String? currentUserId,
    int page = 0,
    int size = 100,
  }) async {
    try {
      final remoteMessages = await remoteDataSource.getMessages(
        threadId,
        currentUserId: currentUserId,
        page: page,
        size: size,
      );

      final collections = remoteMessages
          .map((m) => MessageCollection.fromEntity(m, threadId))
          .toList();

      // Codes returned by the API — used to avoid double-counting below.
      final apiCodes = collections.map((c) => c.code).toSet();

      // Deleted messages that should be preserved across page-0 refreshes.
      // The backend omits truly-deleted messages from the list endpoint, so a
      // plain wipe-and-replace would make the "This message has been deleted."
      // placeholder disappear every time the thread is reopened or refreshed.
      // We hold on to any Isar-cached row that has a deletedAt timestamp and
      // isn't already present in the new API window.
      List<MessageCollection> preservedDeleted = const [];

      if (page == 0) {
        // Page 0 is the latest-window refresh: API response is the source
        // of truth for that window, so old rows for the thread are cleared
        // first. An older-history page (page > 0) must NOT do this — it
        // would wipe out the newer messages already cached locally.
        final oldCachedCollections = await cacheService
            .getByField<MessageCollection>('threadId', threadId);
        preservedDeleted = oldCachedCollections
            .where((c) => c.deletedAt != null && !apiCodes.contains(c.code))
            .toList();
        for (final collection in oldCachedCollections) {
          // Skip entries we are intentionally keeping.
          if (preservedDeleted.any((d) => d.isarId == collection.isarId)) {
            continue;
          }
          await cacheService.delete<MessageCollection>(collection.isarId);
        }
      }

      if (collections.isNotEmpty) {
        await cacheService.putAll(collections);
      }

      // Build the final message list: API messages + preserved deleted ones.
      final deletedMessages = preservedDeleted
          .map((c) => c.toEntity(currentUserId: currentUserId))
          .toList();
      return Right([...remoteMessages, ...deletedMessages]);
    } catch (e) {
      // Fallback to cache if network fails
      final cachedCollections = await cacheService
          .getByField<MessageCollection>('threadId', threadId);
      final fallbackMessages =
          cachedCollections
              .map((c) => c.toEntity(currentUserId: currentUserId))
              .toList()
            ..sort((a, b) => a.time.compareTo(b.time));

      if (fallbackMessages.isNotEmpty) {
        return Right(fallbackMessages);
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(
    String threadId,
    Message message,
  ) async {
    try {
      final messageModel = MessageModel(
        id: message.id,
        code: message.code,
        text: message.text,
        isSentByMe: message.isSentByMe,
        time: message.time,
        quotedMessageId: message.quotedMessageId,
        senderName: message.senderName,
        receivers: message.receivers,
        reactions: message.reactions,
        attachments: message.attachments,
        senderUserCode: '',
        isPrivate: message.isPrivate,
        privateParentUserCode: message.privateParentUserCode,
      );
      final sentMessage = await remoteDataSource.sendMessage(
        threadId,
        messageModel,
      );

      // Save the sent message to cache
      await cacheService.put(
        MessageCollection.fromEntity(sentMessage, threadId),
      );

      return Right(sentMessage);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String threadId,
    String messageId,
  ) async {
    try {
      await remoteDataSource.markAsRead(threadId, messageId);

      // Update cache status
      final results = await cacheService.getByField<MessageCollection>(
        'id',
        messageId,
      );
      if (results.isNotEmpty) {
        final message = results.first;
        message.readAt = AppTime.nowUtc();
        await cacheService.put(message);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsDelivered(String threadId) async {
    try {
      await remoteDataSource.markAllAsDelivered(threadId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> sendBulkMessage({
    required String text,
    required List<String> recipientIds,
    List<ChatAttachment> attachments = const [],
  }) {
    // TODO: implement sendBulkMessage
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Conversation>> createConversation(
    CreateConversationRequest request,
  ) async {
    try {
      final conversation = await remoteDataSource.createConversation(request);

      // Keep Isar in sync so returning to the list shows the new conversation
      // immediately (even before the next remote refresh).
      try {
        await cacheService.put(ConversationCollection.fromEntity(conversation));
      } catch (_) {}
      return Right(conversation);
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationsPage>> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    try {
      // 1. Try to load from cache first
      final cachedItems = await cacheService.getAll<ConversationCollection>();
      if (cachedItems.isNotEmpty && page == 0) {
        // Return cached entities immediately for a fast initial UI load
        // final entities = cachedItems.map((e) => e.toEntity()).toList();
        // Since this is a repository method returning a Future, we can't 'stream' results yet.
        // However, the Cubit already calls loadCachedConversations before calling this.
        // So this fallback is more of a safety measure.
      }

      // 2. Fetch from remote
      final response = await remoteDataSource.getConversations(
        type: type,
        status: status,
        page: page,
        size: size,
      );

      if (response.success && response.data != null) {
        final conversations = response.data!.content;

        // 3. Update cache (for first page)
        if (page == 0) {
          // Firestore is the source of truth for the live fields (unreadCount +
          // lastMessagePreview). The REST list returns the conversation-level,
          // shared-across-all-participants preview — which is the neutral
          // "Private message" placeholder for private messages — whereas the
          // per-user Firestore inbox carries the REAL last message for the
          // parent/staff who may see it. So DON'T let this REST refresh clobber
          // those fields on conversations we already have cached (that would make
          // a read private message revert from its real text to "Private
          // message"). Preserve them from the existing row; refresh everything
          // else from REST. New conversations take the REST value until the next
          // Firestore snapshot fills in the real preview.
          final existingByCode = {
            for (final c in await cacheService.getAll<ConversationCollection>())
              c.code: c,
          };
          final toStore = conversations.map((e) {
            final col = ConversationCollection.fromEntity(e);
            final prev = existingByCode[e.code];
            if (prev != null) {
              col.lastMessagePreview = prev.lastMessagePreview;
              col.unreadCount = prev.unreadCount;
              col.lastMessageAt = prev.lastMessageAt;
              col.lastMessageBy = prev.lastMessageBy;
            }
            return col;
          }).toList();
          await cacheService.clear<ConversationCollection>();
          await cacheService.putAll(toStore);
        }

        return Right(
          ConversationsPage(
            items: conversations,
            page: response.data!.number,
            // Backend's own pageable metadata — far more reliable than
            // guessing from `items.length == size`, which breaks the
            // instant the last page happens to be exactly full.
            hasMore: !response.data!.last,
          ),
        );
      } else {
        return Left(ServerFailure(response.message));
      }
    } catch (e) {
      // If remote fails, try to return cache as fallback. The cache has no
      // pagination metadata of its own, so treat it as a single complete
      // page rather than risk an infinite "load more" loop while offline.
      final cachedItems = await cacheService.getAll<ConversationCollection>();
      if (cachedItems.isNotEmpty) {
        return Right(
          ConversationsPage(
            items: cachedItems.map((e) => e.toEntity()).toList(),
            page: 0,
            hasMore: false,
          ),
        );
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> loadCachedConversations() async {
    try {
      final cachedItems = await cacheService.getAll<ConversationCollection>();
      return Right(cachedItems.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> loadCachedMessages(
    String threadId, {
    String? currentUserId,
  }) async {
    try {
      final cachedCollections = await cacheService
          .getByField<MessageCollection>('threadId', threadId);
      final cachedMessages =
          cachedCollections
              .map((c) => c.toEntity(currentUserId: currentUserId))
              .toList()
            ..sort((a, b) => a.time.compareTo(b.time));
      return Right(cachedMessages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReaction(
    String threadId,
    String messageCode,
    String emoji,
  ) async {
    final results = await cacheService.getByField<MessageCollection>(
      'code',
      messageCode,
    );
    MessageCollection? originalCollection;
    List<MessageReactionCollection>? originalReactions;

    if (results.isNotEmpty) {
      originalCollection = results.first;
      originalReactions = List<MessageReactionCollection>.from(
        originalCollection.reactions ?? [],
      );

      // A user may hold multiple distinct emojis; only append this (me, emoji)
      // pair if it isn't already present — do NOT replace their other emojis.
      final list = List<MessageReactionCollection>.from(originalReactions);
      final alreadyPresent =
          list.any((r) => r.userId == 'me' && r.emoji == emoji);
      if (!alreadyPresent) {
        list.add(
          MessageReactionCollection()
            ..userId = 'me'
            ..emoji = emoji,
        );
      }
      originalCollection.reactions = list;
      await cacheService.put(originalCollection);
    }

    try {
      await remoteDataSource.addReaction(messageCode, emoji);
      return const Right(null);
    } catch (e) {
      if (originalCollection != null) {
        originalCollection.reactions = originalReactions;
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async {
    final results = await cacheService.getByField<MessageCollection>(
      'code',
      messageCode,
    );
    MessageCollection? originalCollection;
    DateTime? originalDeletedAt;
    if (results.isNotEmpty) {
      originalCollection = results.first;
      originalDeletedAt = originalCollection.deletedAt;
      // Soft-delete in Isar so the page-0 wipe preservation logic can find it
      // on thread reopen, even if Firestore hasn't yet fired the realtime update.
      originalCollection.deletedAt = SchoolZoneDateTime.utcNowInSchool(
        SchoolTimezoneResolver.lastKnownTimeZone,
      );
      await cacheService.put(originalCollection);
    }

    try {
      await remoteDataSource.deleteMessage(messageCode);
      return const Right(null);
    } catch (e) {
      if (originalCollection != null) {
        originalCollection.deletedAt = originalDeletedAt;
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction(
    String messageCode,
    String emoji,
  ) async {
    final results = await cacheService.getByField<MessageCollection>(
      'code',
      messageCode,
    );
    MessageCollection? originalCollection;
    List<MessageReactionCollection>? originalReactions;

    if (results.isNotEmpty) {
      originalCollection = results.first;
      originalReactions = List<MessageReactionCollection>.from(
        originalCollection.reactions ?? [],
      );

      // Remove only the matching (me, emoji) pair, leaving any other emojis
      // this user placed on the message intact.
      final list = List<MessageReactionCollection>.from(originalReactions)
        ..removeWhere((r) => r.userId == 'me' && r.emoji == emoji);
      originalCollection.reactions = list;
      await cacheService.put(originalCollection);
    }

    try {
      await remoteDataSource.removeReaction(messageCode, emoji);
      return const Right(null);
    } catch (e) {
      if (originalCollection != null) {
        originalCollection.reactions = originalReactions;
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttachment(int attachmentId) async {
    // Attachments are embedded on whichever message carries them — there's
    // no indexed field to query by, so find the owning row by scanning the
    // (locally bounded) cache rather than adding a new index for a rare,
    // user-initiated action.
    final allMessages = await cacheService.getAll<MessageCollection>();
    MessageCollection? originalCollection;
    List<ChatAttachmentCollection>? originalAttachments;

    for (final candidate in allMessages) {
      final attachments = candidate.attachments ?? const [];
      if (attachments.any((a) => a.attachmentId == attachmentId)) {
        originalCollection = candidate;
        originalAttachments = List<ChatAttachmentCollection>.from(attachments);
        candidate.attachments = List<ChatAttachmentCollection>.from(attachments)
          ..removeWhere((a) => a.attachmentId == attachmentId);
        await cacheService.put(candidate);
        break;
      }
    }

    try {
      await remoteDataSource.deleteAttachment(attachmentId);
      return const Right(null);
    } catch (e) {
      if (originalCollection != null) {
        originalCollection.attachments = originalAttachments;
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> clearMessagesCache(String threadId) async {
    try {
      final collections = await cacheService.getByField<MessageCollection>(
        'threadId',
        threadId,
      );
      for (final c in collections) {
        await cacheService.delete<MessageCollection>(c.isarId);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearConversationsCache() async {
    try {
      await cacheService.clear<ConversationCollection>();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> editMessage(
    String messageCode,
    String content,
  ) async {
    final results = await cacheService.getByField<MessageCollection>(
      'code',
      messageCode,
    );
    MessageCollection? originalCollection;
    String? originalText;
    DateTime? originalEditedAt;

    if (results.isNotEmpty) {
      originalCollection = results.first;
      originalText = originalCollection.text;
      originalEditedAt = originalCollection.editedAt;

      originalCollection.text = content;
      originalCollection.editedAt = AppTime.nowUtc();
      await cacheService.put(originalCollection);
    }

    try {
      final editedMessage = await remoteDataSource.editMessage(
        messageCode,
        content,
      );

      // Update cache
      if (originalCollection != null) {
        await cacheService.put(
          MessageCollection.fromEntity(
            editedMessage,
            originalCollection.threadId,
          ),
        );
      }

      return Right(editedMessage);
    } catch (e) {
      if (originalCollection != null) {
        originalCollection.text = originalText!;
        originalCollection.editedAt = originalEditedAt;
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  // ─── Realtime (Firestore delta layer) ────────────────────────────────────
  //
  // API + Isar remain the source of truth for history. Firestore is only
  // consulted here to learn "something changed" and merge that delta into
  // the existing Isar row before re-emitting. Nothing is ever rendered
  // straight from Firestore, and a Firestore emission never replaces or
  // deletes Isar history outright.

  /// Tracks conversation CODES for which we've already triggered a best-effort
  /// REST refresh after spotting an inbox entry with no local Isar match (i.e.
  /// a brand new conversation). Keyed per-code (not per-type) so each new
  /// conversation is pulled in exactly once — a second new conversation later
  /// in the session still gets refreshed — while avoiding refresh storms when
  /// the same unknown code re-arrives on every snapshot.
  final Set<String> _refreshedConversationCodes = {};

  @override
  Stream<List<Conversation>> watchConversations({String? type}) async* {
    final org = await _organizationCode;
    final school = await _schoolCode;
    final user = await _userCode;
    if (org.isEmpty || school.isEmpty || user.isEmpty) return;

    yield* conversationRealtimeDataSource
        .watchInbox(
          organizationCode: org,
          schoolCode: school,
          userCode: user,
          filterType: type,
        )
        .asyncMap((items) async {
          final unknownCodes = <String>[];
          final merged = <Conversation>[];

          for (final item in items) {
            final cached = await cacheService
                .getByField<ConversationCollection>(
                  'code',
                  item.conversationCode,
                );
            if (cached.isEmpty) {
              // Not in the local Isar cache yet (e.g. a brand-new conversation
              // created after the initial REST load). Don't fabricate it from
              // the denormalized inbox doc (it lacks participants/avatar);
              // instead trigger a one-time REST backfill (below) so the next
              // snapshot renders it with full metadata.
              unknownCodes.add(item.conversationCode);
              continue;
            }
            final existing = cached.first;
            existing.unreadCount = item.unreadCount;
            existing.lastMessageAt =
                item.lastMessageAt ?? existing.lastMessageAt;
            existing.lastMessageBy =
                item.lastMessageSenderCode ?? existing.lastMessageBy;
            // Take the inbox preview verbatim, including empty. The Firestore snapshot is a
            // full-document read, so an empty preview means the backend cleared it (every
            // message in the conversation was deleted) — not a partial update. The previous
            // isNotEmpty guard skipped that clear, leaving a deleted last message showing as
            // the list preview after the conversation was fully emptied.
            existing.lastMessagePreview = item.lastMessagePreview;
            await cacheService.put(existing);
            merged.add(existing.toEntity());
          }

          // Backfill any conversation codes not in the local cache (e.g. a
          // brand-new conversation someone else started). AWAIT the REST fetch
          // (guarded to once per code so a repeating unknown can't storm) and
          // then INCLUDE the now-cached conversations in THIS emission. A
          // fire-and-forget refresh would leave them dropped until the next
          // Firestore snapshot re-runs the merge — which may never fire — so the
          // new conversation would stay invisible even though the API has it.
          final toBackfill = unknownCodes
              .where((c) => !_refreshedConversationCodes.contains(c))
              .toList();
          if (toBackfill.isNotEmpty) {
            _refreshedConversationCodes.addAll(toBackfill);
            try {
              await getConversations(type: type); // source of truth → persists to Isar
            } catch (_) {
              // best-effort; a later snapshot / pull-to-refresh will retry
            }
          }
          // Re-include any unknown conversation now present in the cache (from
          // this or a prior backfill) so it shows without waiting for the next
          // realtime event.
          for (final code in unknownCodes) {
            final backfilled = await cacheService
                .getByField<ConversationCollection>('code', code);
            if (backfilled.isNotEmpty) {
              merged.add(backfilled.first.toEntity());
            }
          }

          return merged;
        });
  }

  @override
  Stream<List<Message>> watchMessages(
    String threadId, {
    String? organizationCode,
    String? schoolCode,
  }) async* {
    final org = (organizationCode?.trim().isNotEmpty ?? false)
        ? organizationCode!.trim()
        : await _organizationCode;
    final school = (schoolCode?.trim().isNotEmpty ?? false)
        ? schoolCode!.trim()
        : await _schoolCode;
    final userCode = await _userCode;
    if (org.isEmpty || school.isEmpty || userCode.isEmpty) return;

    final roleJson = (await storageService.getString(StorageKeys.roles) ?? '').toUpperCase();
    final activeRole = (await storageService.getString(StorageKeys.activeSchoolRole) ?? '').toUpperCase();
    
    final isStaff = activeRole == 'STAFF' || activeRole == 'TEACHER' || (activeRole.isEmpty && (roleJson.contains('STAFF') || roleJson.contains('TEACHER')));
    final isAdmin = activeRole.contains('ADMIN') || activeRole.contains('DIRECTOR') || (activeRole.isEmpty && (roleJson.contains('ADMIN') || roleJson.contains('DIRECTOR')));

    yield* messageRealtimeDataSource
        .watchMessages(
          organizationCode: org,
          schoolCode: school,
          conversationCode: threadId,
          currentUserCode: userCode,
          isStaff: isStaff,
          isAdmin: isAdmin,
        )
        .asyncMap((entities) async {
          for (final entity in entities) {
            await _mergeRealtimeMessage(entity, threadId);
          }

          final currentUser = await _userCode;
          final cachedCollections = await cacheService
              .getByField<MessageCollection>('threadId', threadId);
          final messages =
              cachedCollections
                  .map((c) => c.toEntity(currentUserId: currentUser))
                  .toList()
                ..sort((a, b) => a.time.compareTo(b.time));
          return messages;
        });
  }

  /// Upserts a single realtime [MessageEntity] delta into the legacy Isar
  /// cache by message code, preserving fields Firestore doesn't carry
  /// (attachments, delivery/read receipts) from whatever is already cached.
  Future<void> _mergeRealtimeMessage(
    MessageEntity entity,
    String threadId,
  ) async {
    final existingRows = await cacheService.getByField<MessageCollection>(
      'code',
      entity.code,
    );
    final existing = existingRows.isNotEmpty ? existingRows.first : null;

    final merged = MessageCollection()
      ..id = existing?.id ?? entity.id
      ..code = entity.code
      ..threadId = threadId
      ..text = entity.isDeleted
          ? (entity.deletedPlaceholder ?? '🚫 This Message Has Been Deleted')
          : entity.text
      ..isSentByMe = existing?.isSentByMe
      ..senderUserCode = entity.senderCode.isNotEmpty
          ? entity.senderCode
          : existing?.senderUserCode
      ..time = existing?.time ?? entity.sentAt
      ..deliveredAt = existing?.deliveredAt
      ..readAt = existing?.readAt
      ..editedAt = entity.editedAt ?? existing?.editedAt
      // `entity.isDeleted` already drives the placeholder text above, but
      // without persisting `deletedAt` too, `Message.isDeleted` (derived
      // from it) reads back false once this cached row round-trips through
      // `toEntity()` — silently re-enabling Edit/Reply/Delete on a message
      // that visually looks deleted.
      ..deletedAt = entity.isDeleted
          ? (entity.deletedAt ?? AppTime.nowUtc())
          : existing?.deletedAt
      ..quotedMessageId = existing?.quotedMessageId ?? entity.threadParentCode
      ..senderName = entity.senderName.isNotEmpty
          ? entity.senderName
          : existing?.senderName
      ..receivers = existing?.receivers
      // Persist private-mode metadata through the realtime cache merge.
      // Leaving these unset made cached realtime messages default to
      // isPrivate=false, so private messages wrongly surfaced in the Group
      // tab instead of the owning parent's private tab. Never downgrade a
      // message already known to be private from either source.
      ..isPrivate = entity.isPrivate || (existing?.isPrivate ?? false)
      ..privateParentUserCode =
          entity.privateParentUserCode ?? existing?.privateParentUserCode
      ..deliveredTo = entity.readReceipts.isNotEmpty
          ? entity.readReceipts
                .map(
                  (r) => RecipientStatusCollection()
                    ..name = r.userName
                    ..userId = r.userCode
                    ..timestamp = r.deliveredAt,
                )
                .toList()
          : existing?.deliveredTo
      ..readBy = entity.readReceipts.any((r) => r.isRead)
          ? entity.readReceipts
                .where((r) => r.isRead)
                .map(
                  (r) => RecipientStatusCollection()
                    ..name = r.userName
                    ..userId = r.userCode
                    ..timestamp = r.readAt,
                )
                .toList()
          : existing?.readBy
      ..attachments = existing?.attachments
      // Firestore's reactions map can lag behind a just-added local reaction
      // (eventual consistency) — only overwrite the cache when the realtime
      // payload actually carries reactions, otherwise keep what's cached so
      // a reaction doesn't visually vanish the moment any other message
      // arrives via the realtime stream.
      ..reactions = entity.reactions.isNotEmpty
          ? entity.reactions
                .map(
                  (r) => MessageReactionCollection()
                    ..userId = r.userCode
                    ..emoji = r.emoji,
                )
                .toList()
          : existing?.reactions;

    await cacheService.put(merged);
  }
}
