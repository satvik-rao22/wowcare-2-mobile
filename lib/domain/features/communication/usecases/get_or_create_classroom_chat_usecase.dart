import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

/// Resolves a classroom's CLASSROOM_CHAT conversation, creating it (with the classroom name as
/// title + staff roster) on first use if it doesn't exist yet. Mirrors the web Notes tab.
class GetOrCreateClassroomChatUseCase {
  final ConversationEntityRepository _repository;

  GetOrCreateClassroomChatUseCase(this._repository);

  Future<Either<Failure, ConversationEntity>> call(
    String classroomCode, {
    String? classroomName,
  }) async {
    // 1. Existing classroom chat?
    final existing = await _find(classroomCode);
    if (existing != null) return Right(existing);

    // 2-3. Only a first message gets here: logged as a conversation open.
    return AppEvents.track(
      AppEvent.communicationConversationOpen,
      () => _create(classroomCode, classroomName),
      failureOf: AppEvents.leftFailure,
    );
  }

  Future<Either<Failure, ConversationEntity>> _create(
    String classroomCode,
    String? classroomName,
  ) async {
    // 2. Get-or-create + reconcile on the server.
    final recon =
        await _repository.reconcileClassroomChat(classroomCode, classroomName: classroomName);
    final reconFailure = recon.fold<Failure?>((l) => l, (_) => null);
    if (reconFailure != null) return Left(reconFailure);

    // 3. Re-fetch the now-created conversation.
    final created = await _find(classroomCode);
    if (created != null) return Right(created);
    return Left(ServerFailure('Classroom chat could not be created'));
  }

  /// GET-only: returns the classroom's existing CLASSROOM_CHAT conversation, or
  /// null if it hasn't been created yet. Used to open the thread as a draft
  /// (composer over an empty list) without creating it — the conversation is
  /// created lazily on the first message via [call]. Mirrors the web Notes tab.
  Future<ConversationEntity?> findExisting(String classroomCode) =>
      _find(classroomCode);

  Future<ConversationEntity?> _find(String classroomCode) async {
    final result = await _repository.getConversationsForClassroom(classroomCode);
    return result.fold((_) => null, (list) {
      final matches = list.where(
        (c) => c.type == ConversationType.classroomChat &&
            c.status.toUpperCase() == 'ACTIVE',
      );
      return matches.isEmpty ? null : matches.first;
    });
  }
}
