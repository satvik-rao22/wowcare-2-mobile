import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

/// Single shared "create-or-open" entry point for starting a conversation,
/// used by Staff, Parent, and Admin messaging alike.
///
/// Always looks for an existing active conversation matching the requested
/// scope first, and only creates a new one when none is found — this is
/// what prevents duplicate STAFF_DIRECT/ROOM_CHAT/ADMIN_CHAT threads across
/// every entry point in the app.
class CreateOrOpenConversationUseCase {
  final ConversationEntityRepository _repository;

  CreateOrOpenConversationUseCase(this._repository);

  /// Logged as one `communication.conversation_open`, whether the thread was
  /// found or created.
  Future<Either<Failure, ConversationEntity>> call({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
    String title = '',
    String description = '',
    String avatarUrl = '',
  }) {
    return AppEvents.track(
      AppEvent.communicationConversationOpen,
      () => _createOrOpen(
        type: type,
        studentCode: studentCode,
        classroomCode: classroomCode,
        participantCodes: participantCodes,
        title: title,
        description: description,
        avatarUrl: avatarUrl,
      ),
      failureOf: AppEvents.leftFailure,
    );
  }

  Future<Either<Failure, ConversationEntity>> _createOrOpen({
    required ConversationType type,
    required String studentCode,
    required String? classroomCode,
    required List<String>? participantCodes,
    required String title,
    required String description,
    required String avatarUrl,
  }) async {
    final Either<Failure, ConversationEntity?> existing;

    switch (type) {
      case ConversationType.staffDirect:
        final recipient = (participantCodes ?? const []).firstOrNull;
        if (recipient == null || recipient.isEmpty) {
          return const Left(
            ValidationFailure(
              'A single staff recipient is required for staff direct messages.',
            ),
          );
        }
        existing = await _repository.findStaffDirectConversation(recipient);
        break;
      case ConversationType.roomChat:
        // Room chat is usually scoped to one student (a parent's classroom
        // thread, or a single-recipient staff broadcast); dedupe is only
        // possible when that scope is known. An ad-hoc multi-recipient
        // broadcast with no single student scope has no existing thread to
        // reuse, so it always creates fresh — same as today.
        existing = studentCode.isEmpty
            ? const Right(null)
            : await _repository.findRoomChatConversation(
                studentCode: studentCode,
                classroomCode: classroomCode,
              );
        break;
      case ConversationType.adminChat:
        // Admin chat may be created without a student scope (general admin
        // discussion) — dedupe is only possible when a student is given.
        existing = studentCode.isEmpty
            ? const Right(null)
            : await _repository.findAdminChatConversation(
                studentCode: studentCode,
              );
        break;
      case ConversationType.classroomChat:
        // Classroom chats are provisioned server-side (reconcileClassroomChat),
        // not via this manual create flow.
        return const Left(ValidationFailure(
          'Classroom chats are created automatically for the classroom.',
        ));
    }

    final found = existing.fold((_) => null, (c) => c);
    if (found != null) return Right(found);

    return _repository.createConversation(
      type: type,
      studentCode: studentCode,
      classroomCode: classroomCode,
      participantCodes: participantCodes,
      title: title,
      description: description,
      avatarUrl: avatarUrl,
    );
  }
}
