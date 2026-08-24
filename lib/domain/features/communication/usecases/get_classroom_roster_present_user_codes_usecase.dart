import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/conversation_entity_repository.dart';

/// User codes currently present on a classroom's staff roster — used to hide
/// a Classroom Notes participant chip for anyone the conversation still
/// lists but who has since left/been removed from the classroom (the
/// backend's `missing` list). See
/// `GET /conversations/classroom/{classroomCode}/roster-status`.
class GetClassroomRosterPresentUserCodesUseCase {
  final ConversationEntityRepository _repository;

  GetClassroomRosterPresentUserCodesUseCase(this._repository);

  Future<Either<Failure, Set<String>>> call(String classroomCode) {
    return _repository.getClassroomRosterPresentUserCodes(classroomCode);
  }
}
