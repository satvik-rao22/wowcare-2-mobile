import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class GetConversationsEntityUseCase {
  final ConversationEntityRepository _repository;

  GetConversationsEntityUseCase(this._repository);

  Future<Either<Failure, List<ConversationEntity>>> call({
    ConversationType? type,
    String? status,
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
    bool? unreadOnly,
    bool includeRestUnreadCounts = true,
  }) {
    return _repository.getConversations(
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
      includeRestUnreadCounts: includeRestUnreadCounts,
    );
  }
}
