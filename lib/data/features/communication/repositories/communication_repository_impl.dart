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

      // Save to cache for offline support
      final collections = remoteMessages
          .map((m) => MessageCollection.fromEntity(m, threadId))
          .toList();
      await cacheService.putAll(collections);

      return Right(remoteMessages);
    } catch (e) {
      // Fallback to cache if network fails
      final cachedCollections = await cacheService
          .getByField<MessageCollection>('threadId', threadId);
      final cachedMessages = cachedCollections
          .map((c) => c.toEntity())
          .toList();

      if (cachedMessages.isNotEmpty) {
        return Right(cachedMessages);
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
        text: message.text,
        isSentByMe: message.isSentByMe,
        time: message.time,
        quotedMessageId: message.quotedMessageId,
        senderName: message.senderName,
        receivers: message.receivers,
        reactions: message.reactions,
        code: '',
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
  Future<Either<Failure, List<Message>>> loadCachedMessages(String threadId) async {
    try {
      final cachedCollections = await cacheService.getByField<MessageCollection>(
        'threadId',
        threadId,
      );
      final cachedMessages = cachedCollections
          .map((c) => c.toEntity())
          .toList();
      return Right(cachedMessages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReaction(
    String threadId,
    String messageId,
    String emoji,
  ) async {
    try {
      await remoteDataSource.addReaction(messageId, emoji);

      // Update local Isar cache
      final results = await cacheService.getByField<MessageCollection>(
        'id',
        messageId,
      );
      if (results.isNotEmpty) {
        final messageCollection = results.first;
        final list = List<MessageReactionCollection>.from(
          messageCollection.reactions ?? [],
        );
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
        messageCollection.reactions = list;
        await cacheService.put(messageCollection);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
