import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetConversationsUseCase {
  final CommunicationRepository _repository;

  GetConversationsUseCase(this._repository);

  Future<Either<Failure, ConversationsPage>> call({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
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
    );
  }
}
