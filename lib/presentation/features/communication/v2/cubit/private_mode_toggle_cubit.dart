import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
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
    bool initialEnabled = false,
  })  : _useCase = togglePrivateModeUseCase,
        _conversationCode = conversationCode,
        super(PrivateModeToggleState(isEnabled: initialEnabled));

  final TogglePrivateModeUseCase _useCase;
  final String _conversationCode;

  /// Toggles private mode to the opposite of the current state.
  ///
  /// Applies optimistically so the UI updates immediately. Rolls back and
  /// surfaces [PrivateModeToggleState.errorMessage] on API failure.
  Future<void> toggle() async {
    if (state.isLoading) return;

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
        emit(state.copyWith(isLoading: false, clearError: true));
      },
    );
  }
}
