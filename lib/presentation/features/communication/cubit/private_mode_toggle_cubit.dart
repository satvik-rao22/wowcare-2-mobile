import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/room_chat_privacy_helper.dart';
import 'private_mode_toggle_state.dart';

/// Manages private mode for a single conversation in the parent thread.
///
/// Instantiated directly at the callsite with the conversation code and
/// initial state read from [ConversationEntity.privateModeStates]. This keeps
/// the cubit scoped to the thread widget lifetime.
///
/// Follows the same optimistic-update + rollback pattern as
/// [ConversationThreadCubit].
class PrivateModeToggleCubit extends Cubit<PrivateModeToggleState> {
  PrivateModeToggleCubit({
    required TogglePrivateModeUseCase togglePrivateModeUseCase,
    required String conversationCode,
    required RoomChatViewerRole Function() viewerRole,
    bool initialEnabled = false,
  })  : _useCase = togglePrivateModeUseCase,
        _conversationCode = conversationCode,
        _viewerRole = viewerRole,
        super(PrivateModeToggleState(isEnabled: initialEnabled));

  final TogglePrivateModeUseCase _useCase;
  final String _conversationCode;

  /// Resolved at toggle-time (not captured once at construction) so it
  /// always reflects the latest known role even if it loads asynchronously
  /// after this cubit is created.
  final RoomChatViewerRole Function() _viewerRole;

  /// Applies a private mode state update received from a remote source (e.g.
  /// another device, Firestore inbox change) without calling the API. The
  /// state is only updated when the remote value differs from the current one
  /// to avoid redundant rebuilds.
  void syncFromRemote({required bool active, String? activatedBy}) {
    if (state.isLoading || state.isEnabled == active) return;
    emit(state.copyWith(isEnabled: active, clearError: true, clearSuccess: true));
  }

  /// Toggles private mode to the opposite of the current state.
  ///
  /// Authorization is enforced here — not just in the UI — so an
  /// unauthorized mutation can't slip through even if a widget fails to
  /// hide/disable the control. See [RoomChatPrivacyHelper.canModifyPrivateMode].
  ///
  /// Applies optimistically so the UI updates immediately. Rolls back and
  /// surfaces [PrivateModeToggleState.errorMessage] on API failure.
  Future<void> toggle() async {
    if (state.isLoading) return;

    if (!RoomChatPrivacyHelper.canModifyPrivateMode(_viewerRole())) {
      emit(
        state.copyWith(
          errorMessage: 'Only the guardian can change Private Mode.',
        ),
      );
      return;
    }

    final newValue = !state.isEnabled;

    // Optimistic update
    emit(state.copyWith(isEnabled: newValue, isLoading: true, clearError: true));

    final result = await _useCase(
      conversationCode: _conversationCode,
      enable: newValue,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        // Roll back to previous value on error
        emit(state.copyWith(
          isEnabled: !newValue,
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to update private mode.',
        ));
      },
      (_) {
        emit(state.copyWith(
          isLoading: false,
          clearError: true,
          successMessage: newValue
              ? 'Private messaging is ON'
              : 'Private messaging is OFF',
        ));
      },
    );
  }
}
