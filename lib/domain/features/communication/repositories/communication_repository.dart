import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/data/features/communication/models/create_conversation_request.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

abstract class CommunicationRepository {
  Future<Either<Failure, List<Message>>> getMessages(
    String threadId, {
    String? currentUserId,
  });
  Future<Either<Failure, Message>> sendMessage(
    String threadId,
    Message message,
  );
  Future<Either<Failure, void>> markAsRead(String threadId, String messageId);
  Future<Either<Failure, String>> uploadAttachment(ChatAttachment attachment);
  Future<Either<Failure, void>> sendBulkMessage({
    required String text,
    required List<String> recipientIds,
    List<ChatAttachment> attachments = const [],
  });
  Future<Either<Failure, Conversation>> createConversation(
    CreateConversationRequest request,
  );
  Future<Either<Failure, List<Conversation>>> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  });
  Future<Either<Failure, List<Conversation>>> loadCachedConversations();
  Future<Either<Failure, List<Message>>> loadCachedMessages(String threadId);
  Future<Either<Failure, void>> addReaction(
    String threadId,
    String messageId,
    String emoji,
  );
}
