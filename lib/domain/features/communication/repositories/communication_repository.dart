import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

abstract class CommunicationRepository {
  Future<Either<Failure, List<Message>>> getMessages(String threadId);
  Future<Either<Failure, Message>> sendMessage(String threadId, Message message);
  Future<Either<Failure, void>> markAsRead(String threadId, String messageId);
  Future<Either<Failure, String>> uploadAttachment(ChatAttachment attachment);
}
