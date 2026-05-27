import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/features/communication/models/create_conversation_request.dart';
import '../../../../domain/features/communication/entities/conversation.dart';
import '../../../../domain/features/communication/usecases/create_conversation_usecase.dart';
import 'create_conversation_state.dart';

class CreateConversationCubit extends Cubit<CreateConversationState> {
  final CreateConversationUseCase createConversationUseCase;

  CreateConversationCubit({required this.createConversationUseCase})
    : super(CreateConversationInitial());

  Future<void> createConversation({
    required String title,
    required String organizationCode,
    required String schoolCode,
    required List<String> participantUserCodes,
    String type = 'DIRECT',
    required String description,
    required String avatarUrl,
  }) async {
    emit(CreateConversationLoading());

    final request = CreateConversationRequest(
      title: title,
      type: type,
      description: description,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      avatarUrl: avatarUrl,
      participantUserCodes: participantUserCodes,
    );

    final result = await createConversationUseCase(request);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        CreateConversationError(
          failure.message ?? 'Failed to create conversation',
        ),
      ),
      (conversation) => emit(CreateConversationSuccess(conversation)),
    );
  }

  /// Creates a conversation and returns it directly, without emitting state.
  /// Returns null on failure.
  Future<Conversation?> createConversationAndReturn({
    required String title,
    required String organizationCode,
    required String schoolCode,
    required List<String> participantUserCodes,
    String type = 'DIRECT',
    required String description,
    required String avatarUrl,
  }) async {
    final request = CreateConversationRequest(
      title: title,
      type: type,
      description: description,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      avatarUrl: avatarUrl,
      participantUserCodes: participantUserCodes,
    );

    final result = await createConversationUseCase(request);
    return result.fold((_) => null, (conversation) => conversation);
  }
}
