import 'package:dartz/dartz.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/communication_remote_data_source.dart';
import '../models/message_collection.dart';
import '../models/message_model.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../domain/features/communication/repositories/communication_repository.dart';
import '../../../../domain/features/communication/entities/conversation.dart';
import '../models/conversation_collection.dart';
import '../models/create_conversation_request.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final CommunicationRemoteDataSource remoteDataSource;
  final CacheService cacheService;

  CommunicationRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    String threadId, {
    String? currentUserId,
  }) async {
    try {
      final remoteMessages = await remoteDataSource.getMessages(
        threadId,
        currentUserId: currentUserId,
      );

      // Synchronize cache: API response is the source of truth
      // Delete all old cached messages for this thread first
      final oldCachedCollections = await cacheService
          .getByField<MessageCollection>('threadId', threadId);
      for (final collection in oldCachedCollections) {
        await cacheService.delete<MessageCollection>(collection.isarId);
      }

      // Insert fresh messages from API (empty API → cache is now empty)
      final collections = remoteMessages
          .map((m) => MessageCollection.fromEntity(m, threadId))
          .toList();
      if (collections.isNotEmpty) {
        await cacheService.putAll(collections);
      }

      return Right(remoteMessages);
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
      return Left(ServerFailure(e.toString()));
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
        senderUserCode: '',
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
      return Left(ServerFailure(e.toString()));
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
        message.readAt = DateTime.now();
        await cacheService.put(message);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAttachment(
    ChatAttachment attachment,
  ) async {
    try {
      final attachmentModel = ChatAttachmentModel(
        name: attachment.name,
        type: attachment.type,
        sizeBytes: attachment.sizeBytes,
        mimeType: attachment.mimeType,
        remoteUrl: attachment.remoteUrl,
        localPath: attachment.localPath,
      );
      final url = await remoteDataSource.uploadAttachment(attachmentModel);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
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
          await cacheService.clear<ConversationCollection>();
          await cacheService.putAll(
            conversations
                .map((e) => ConversationCollection.fromEntity(e))
                .toList(),
          );
        }

        return Right(conversations);
      } else {
        return Left(ServerFailure(response.message));
      }
    } catch (e) {
      // If remote fails, try to return cache as fallback
      final cachedItems = await cacheService.getAll<ConversationCollection>();
      if (cachedItems.isNotEmpty) {
        return Right(cachedItems.map((e) => e.toEntity()).toList());
      }
      return Left(ServerFailure(e.toString()));
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

      final list = List<MessageReactionCollection>.from(originalReactions);
      final idx = list.indexWhere((r) => r.userId == 'me');
      if (idx != -1) {
        list[idx].emoji = emoji;
      } else {
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async {
    final results = await cacheService.getByField<MessageCollection>(
      'code',
      messageCode,
    );
    MessageCollection? originalCollection;
    if (results.isNotEmpty) {
      originalCollection = results.first;
      await cacheService.delete<MessageCollection>(originalCollection.isarId);
    }

    try {
      await remoteDataSource.deleteMessage(messageCode);
      return const Right(null);
    } catch (e) {
      if (originalCollection != null) {
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(e.toString()));
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

      final list = List<MessageReactionCollection>.from(originalReactions)
        ..removeWhere((r) => r.userId == 'me');
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
      return Left(ServerFailure(e.toString()));
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
      originalCollection.editedAt = DateTime.now();
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
          MessageCollection.fromEntity(editedMessage, originalCollection.threadId),
        );
      }

      return Right(editedMessage);
    } catch (e) {
      if (originalCollection != null) {
        originalCollection.text = originalText!;
        originalCollection.editedAt = originalEditedAt;
        await cacheService.put(originalCollection);
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
