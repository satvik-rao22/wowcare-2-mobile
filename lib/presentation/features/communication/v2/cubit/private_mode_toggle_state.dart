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
  });

  /// Whether private mode is currently active.
  final bool isEnabled;

  /// True while the [TogglePrivateModeUseCase] call is in flight.
  final bool isLoading;

  /// Non-null when the most recent toggle attempt failed. Cleared on next
  /// successful toggle or explicit reset.
  final String? errorMessage;

  PrivateModeToggleState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrivateModeToggleState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isEnabled, isLoading, errorMessage];
}
