import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/domain/features/communication/policies/room_chat_privacy_helper.dart';
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
    required String Function() currentUserCode,
    bool initialEnabled = false,
    String? initialActivatedBy,
  }) : _useCase = togglePrivateModeUseCase,
       _conversationCode = conversationCode,
       _viewerRole = viewerRole,
       _currentUserCode = currentUserCode,
       super(
         PrivateModeToggleState(
           isEnabled: initialEnabled,
           activatedBy: initialActivatedBy,
         ),
       );

  final TogglePrivateModeUseCase _useCase;
  final String _conversationCode;

  /// Resolved at toggle-time (not captured once at construction) so it
  /// always reflects the latest known role even if it loads asynchronously
  /// after this cubit is created.
  final RoomChatViewerRole Function() _viewerRole;

  /// Resolved at toggle-time for the same reason as [_viewerRole] — used to
  /// stamp [PrivateModeToggleState.activatedBy] with the current user's own
  /// code the moment THEY successfully turn private mode on.
  final String Function() _currentUserCode;

  /// Applies a private mode state update received from a remote source (the
  /// authoritative source, e.g. a REST refetch of the conversation) without
  /// calling the API. The toggle always reflects this value directly — no
  /// local override, grace period, or "trust what we just did" heuristic:
  /// whatever the API says is what's shown, full stop. (An earlier version
  /// of this method briefly ignored a conflicting remote value for a few
  /// seconds after local activity, to paper over one specific unreliable
  /// data source — that traded a correctness problem for a "the toggle can
  /// silently show a stale value" problem, which is worse.)
  ///
  /// Also updates [PrivateModeToggleState.activatedBy] — previously this
  /// param was accepted but silently discarded, so nothing ever knew (live)
  /// WHO activated private mode. A screen gating the toggle's `enabled` on
  /// "am I the activator" therefore had to fall back to a value captured
  /// once at construction and never refreshed, letting a non-activator tap
  /// the toggle and get a 403 the backend correctly (but confusingly,
  /// with no warning beforehand) rejected.
  void syncFromRemote({required bool active, String? activatedBy}) {
    if (state.isLoading) return;
    if (state.isEnabled == active && state.activatedBy == activatedBy) {
      return;
    }
    emit(
      state.copyWith(
        isEnabled: active,
        activatedBy: activatedBy,
        clearActivatedBy: activatedBy == null,
        clearError: true,
        clearSuccess: true,
      ),
    );
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

    // Backend enforces this too (403 "Only the guardian who activated
    // private mode can turn it off") — checking it here as well means a
    // non-activator gets an immediate, clear local message instead of
    // round-tripping to the server for a rejection the client already had
    // enough information to predict. Only relevant when turning OFF
    // something already on and activated by someone else; anyone can turn
    // it ON.
    final me = _currentUserCode();
    final activator = state.activatedBy;
    if (!newValue && activator != null && me.isNotEmpty && activator != me) {
      emit(
        state.copyWith(
          errorMessage:
              'Only the guardian who activated Private Mode can turn it off.',
        ),
      );
      return;
    }

    // Optimistic update
    emit(
      state.copyWith(isEnabled: newValue, isLoading: true, clearError: true),
    );

    final result = await _useCase(
      conversationCode: _conversationCode,
      enable: newValue,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        // Roll back to previous value on error
        emit(
          state.copyWith(
            isEnabled: !newValue,
            isLoading: false,
            errorMessage: failure.message ?? 'Failed to update private mode.',
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            isLoading: false,
            clearError: true,
            activatedBy: newValue ? me : null,
            clearActivatedBy: !newValue,
            successMessage: newValue
                ? 'Private messaging is ON'
                : 'Private messaging is OFF',
          ),
        );
      },
    );
  }
}
