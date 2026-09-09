import 'package:equatable/equatable.dart';

/// State for [PrivateModeToggleCubit].
///
/// Tracks whether private mode is active for the current parent within a
/// single conversation, plus loading and error state for the toggle operation.
class PrivateModeToggleState extends Equatable {
  const PrivateModeToggleState({
    required this.isEnabled,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.activatedBy,
  });

  /// Whether private mode is currently active.
  final bool isEnabled;

  /// userCode of the guardian who turned private mode on — only they (or an
  /// admin/director) can turn it off; the backend enforces this and 403s
  /// otherwise. Previously this only ever lived in a screen-local field
  /// captured once at mount (`widget.parentInfo['privateModeActivatedBy']`/
  /// `widget.conversation.privateModeActivatedBy`) and never refreshed, so a
  /// guardian who wasn't (or was no longer) the activator could still see
  /// the toggle as tappable and get a confusing 403 on tap. Now tracked
  /// live here instead, updated by [PrivateModeToggleCubit.syncFromRemote]
  /// and [PrivateModeToggleCubit.toggle] so the UI can disable the control
  /// correctly before the request is even sent.
  final String? activatedBy;

  /// True while the [TogglePrivateModeUseCase] call is in flight.
  final bool isLoading;

  /// Non-null when the most recent toggle attempt failed. Cleared on next
  /// successful toggle or explicit reset.
  final String? errorMessage;

  /// Non-null immediately after the API confirms a successful toggle.
  /// Consumers should display this once and treat it as a one-shot event.
  /// Not emitted by [PrivateModeToggleCubit.syncFromRemote] — only by a
  /// real user-initiated toggle — so realtime sync does not re-fire it.
  final String? successMessage;

  PrivateModeToggleState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? activatedBy,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearActivatedBy = false,
  }) {
    return PrivateModeToggleState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      activatedBy: clearActivatedBy ? null : (activatedBy ?? this.activatedBy),
    );
  }

  @override
  List<Object?> get props => [
    isEnabled,
    isLoading,
    errorMessage,
    successMessage,
    activatedBy,
  ];
}
