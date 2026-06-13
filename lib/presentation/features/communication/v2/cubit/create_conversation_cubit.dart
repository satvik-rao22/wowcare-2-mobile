import 'package:bloc/bloc.dart';
import 'package:wowcare/core/feature_flags/feature_flag_names.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/create_conversation_entity_usecase.dart';
import 'package:wowcare/presentation/features/messaging/cubit/feature_flag_cubit.dart';
import 'create_conversation_state.dart';

/// Creates a new conversation for any supported type:
/// STAFF_DIRECT, ROOM_CHAT, or ADMIN_CHAT.
///
/// Validates role restrictions and feature flags before calling the API.
/// Callers provide the current user's role string ('admin', 'staff', 'parent').
class CreateConversationEntityCubit extends Cubit<CreateConversationState> {
  CreateConversationEntityCubit({
    required CreateConversationEntityUseCase createConversationUseCase,
    required FeatureFlagCubit featureFlagCubit,
  })  : _createConversationUseCase = createConversationUseCase,
        _featureFlagCubit = featureFlagCubit,
        super(const CreateConversationState.initial());

  final CreateConversationEntityUseCase _createConversationUseCase;
  final FeatureFlagCubit _featureFlagCubit;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Create a STAFF_DIRECT conversation.
  ///
  /// Allowed roles: admin, staff.
  /// [participantCodes] — at least one recipient required.
  Future<void> createStaffConversation({
    required String callerRole,
    required List<String> participantCodes,
    String? studentCode,
  }) {
    return _validate(
      type: ConversationType.staffDirect,
      callerRole: callerRole,
      participantCodes: participantCodes,
      studentCode: studentCode,
      featureFlagKey: FeatureFlagNames.staffMessagingEnabled,
    );
  }

  /// Create a ROOM_CHAT conversation (parent + staff/teacher in a classroom).
  ///
  /// Allowed roles: admin, staff, parent.
  /// [studentCode] — required (scoped to a student's classroom).
  Future<void> createParentConversation({
    required String callerRole,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
  }) {
    return _validate(
      type: ConversationType.roomChat,
      callerRole: callerRole,
      participantCodes: participantCodes ?? [],
      studentCode: studentCode,
      classroomCode: classroomCode,
      featureFlagKey: FeatureFlagNames.parentMessagingEnabled,
    );
  }

  /// Create an ADMIN_CHAT conversation (admin + parent, no teachers/staff).
  ///
  /// Allowed roles: admin, parent.
  /// [studentCode] — required.
  Future<void> createAdminConversation({
    required String callerRole,
    required String studentCode,
    List<String>? participantCodes,
  }) {
    return _validate(
      type: ConversationType.adminChat,
      callerRole: callerRole,
      participantCodes: participantCodes ?? [],
      studentCode: studentCode,
      featureFlagKey: FeatureFlagNames.adminChatEnabled,
    );
  }

  /// Generic entry point — selects the correct validation path from [type].
  Future<void> createConversation({
    required ConversationType type,
    required String callerRole,
    required List<String> participantCodes,
    String? studentCode,
    String? classroomCode,
  }) {
    switch (type) {
      case ConversationType.staffDirect:
        return createStaffConversation(
          callerRole: callerRole,
          participantCodes: participantCodes,
          studentCode: studentCode,
        );
      case ConversationType.roomChat:
        return createParentConversation(
          callerRole: callerRole,
          studentCode: studentCode ?? '',
          classroomCode: classroomCode,
          participantCodes: participantCodes,
        );
      case ConversationType.adminChat:
        return createAdminConversation(
          callerRole: callerRole,
          studentCode: studentCode ?? '',
          participantCodes: participantCodes,
        );
    }
  }

  /// Reset to idle so the screen can create another conversation.
  void reset() => emit(const CreateConversationState.initial());

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _validate({
    required ConversationType type,
    required String callerRole,
    required List<String> participantCodes,
    required String? studentCode,
    String? classroomCode,
    required String featureFlagKey,
  }) async {
    // Feature flag check
    if (!_featureFlagCubit.state.isCommunicationEnabled) {
      return _emitValidation('Messaging is currently disabled.');
    }
    if (!_featureFlagCubit.isFlagEnabled(featureFlagKey)) {
      return _emitValidation(
        '${_typeLabel(type)} is currently disabled.',
      );
    }

    // Role restriction check
    final roleError = _checkRoleRestriction(type, callerRole);
    if (roleError != null) return _emitValidation(roleError);

    // Student scope check
    if (type != ConversationType.staffDirect &&
        (studentCode == null || studentCode.trim().isEmpty)) {
      return _emitValidation('A student must be selected for this conversation.');
    }

    // Participant check (STAFF_DIRECT requires at least one explicit recipient)
    if (type == ConversationType.staffDirect && participantCodes.isEmpty) {
      return _emitValidation('Select at least one participant.');
    }

    await _submit(
      type: type,
      studentCode: studentCode,
      classroomCode: classroomCode,
      participantCodes: participantCodes.isEmpty ? null : participantCodes,
    );
  }

  Future<void> _submit({
    required ConversationType type,
    required String? studentCode,
    String? classroomCode,
    List<String>? participantCodes,
  }) async {
    emit(
      state.copyWith(
        status: CreateConversationStatus.loading,
        conversationType: type,
        clearValidationError: true,
        clearError: true,
      ),
    );

    final result = await _createConversationUseCase(
      type: type,
      studentCode: studentCode ?? '',
      classroomCode: classroomCode,
      participantCodes: participantCodes,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreateConversationStatus.failure,
          errorMessage: failure.message ?? 'Failed to create conversation.',
        ),
      ),
      (conversation) => emit(
        state.copyWith(
          status: CreateConversationStatus.success,
          createdConversation: conversation,
          clearError: true,
        ),
      ),
    );
  }

  void _emitValidation(String message) {
    emit(
      state.copyWith(
        status: CreateConversationStatus.failure,
        validationError: message,
        clearError: true,
      ),
    );
  }

  /// Returns an error string if [callerRole] is not allowed to create [type],
  /// null if allowed.
  String? _checkRoleRestriction(ConversationType type, String callerRole) {
    final role = callerRole.toLowerCase();
    switch (type) {
      case ConversationType.staffDirect:
        // STAFF_DIRECT: admin, staff only — parents excluded
        if (role == 'parent') {
          return 'Parents cannot start staff direct conversations.';
        }
        return null;
      case ConversationType.roomChat:
        // ROOM_CHAT: all roles allowed
        return null;
      case ConversationType.adminChat:
        // ADMIN_CHAT: admin and parent only — staff/teacher excluded
        if (role == 'staff') {
          return 'Staff cannot start admin chat conversations.';
        }
        return null;
    }
  }

  String _typeLabel(ConversationType type) {
    switch (type) {
      case ConversationType.staffDirect:
        return 'Staff messaging';
      case ConversationType.roomChat:
        return 'Parent messaging';
      case ConversationType.adminChat:
        return 'Admin chat';
    }
  }
}
