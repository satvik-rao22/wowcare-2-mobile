import 'package:dartz/dartz.dart';
import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/data/features/communication/datasources/communication_remote_data_source.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';
import 'package:wowcare/data/features/communication/models/message_model.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final CommunicationRemoteDataSource remoteDataSource;
  final CacheService cacheService;

  CommunicationRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, List<Message>>> getMessages(String threadId) async {
    try {
      final remoteMessages = await remoteDataSource.getMessages(threadId);

      // Save to cache for offline support
      final collections = remoteMessages
          .map((m) => MessageCollection.fromEntity(m, threadId))
          .toList();
      await cacheService.putAll(collections);

      return Right(remoteMessages);
    } catch (e) {
      // Fallback to cache if network fails
      final cachedCollections =
          await cacheService.getByField<MessageCollection>('threadId', threadId);
      final cachedMessages =
          cachedCollections.map((c) => c.toEntity()).toList();

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
      );
      final sentMessage = await remoteDataSource.sendMessage(
        threadId,
        messageModel,
      );

      // Save the sent message to cache
      await cacheService.put(MessageCollection.fromEntity(sentMessage, threadId));

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
      final results = await cacheService.getByField<MessageCollection>('id', messageId);
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
}
