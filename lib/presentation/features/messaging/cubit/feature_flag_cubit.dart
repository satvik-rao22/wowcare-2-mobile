import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/messaging/usecases/get_feature_flag_usecase.dart';
import '../../../../domain/features/messaging/usecases/set_feature_flag_usecase.dart';

part 'feature_flag_state.dart';

/// Cubit for managing feature flags.
/// Loaded on app startup and cached in memory during session.
///
/// Usage:
///   final flagCubit = context.read<FeatureFlagCubit>();
///   if (flagCubit.state.isBulkMessagingEnabled) {
///     // Show bulk messaging UI
///   }
class FeatureFlagCubit extends Cubit<FeatureFlagState> {
  final GetFeatureFlagUseCase _getFeatureFlagUseCase;
  final SetFeatureFlagUseCase _setFeatureFlagUseCase;

  FeatureFlagCubit({
    required GetFeatureFlagUseCase getFeatureFlagUseCase,
    required SetFeatureFlagUseCase setFeatureFlagUseCase,
  })  : _getFeatureFlagUseCase = getFeatureFlagUseCase,
        _setFeatureFlagUseCase = setFeatureFlagUseCase,
        super(const FeatureFlagState());

  /// Load all feature flags from local storage.
  /// Called on app startup (in main.dart or splash screen).
  Future<void> loadFlags() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    final result = await _getFeatureFlagUseCase.getAll();

    result.fold(
      (failure) {
        // On error, use defaults but show message
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: failure.message ?? 'Failed to load feature flags',
          ),
        );
      },
      (flags) {
        emit(
          state.copyWith(
            isLoading: false,
            flags: flags,
            errorMessage: '',
          ),
        );
      },
    );
  }

  /// Toggle a feature flag (for testing/debugging).
  /// Persists to storage and updates state.
  Future<void> toggleFlag(String flagName) async {
    final currentValue = state.isFlagEnabled(flagName);
    final newValue = !currentValue;

    final result = await _setFeatureFlagUseCase(
      flagName: flagName,
      enabled: newValue,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Failed to update flag',
          ),
        );
      },
      (_) {
        // Update local state
        final updatedFlags = Map<String, bool>.from(state.flags);
        updatedFlags[flagName] = newValue;
        emit(
          state.copyWith(
            flags: updatedFlags,
            errorMessage: '',
          ),
        );
      },
    );
  }

  /// Set a specific flag value.
  Future<void> setFlag({
    required String flagName,
    required bool enabled,
  }) async {
    final result = await _setFeatureFlagUseCase(
      flagName: flagName,
      enabled: enabled,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Failed to set flag',
          ),
        );
      },
      (_) {
        final updatedFlags = Map<String, bool>.from(state.flags);
        updatedFlags[flagName] = enabled;
        emit(
          state.copyWith(
            flags: updatedFlags,
            errorMessage: '',
          ),
        );
      },
    );
  }

  /// Clear all flag overrides and revert to defaults.
  /// Useful for testing/debugging.
  Future<void> clearAllFlags() async {
    final result = await _setFeatureFlagUseCase.clearAll();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Failed to clear flags',
          ),
        );
      },
      (_) {
        // Reset to empty map (defaults will be used)
        emit(
          state.copyWith(
            flags: const {},
            errorMessage: '',
          ),
        );
      },
    );
  }

  /// Check if a flag is enabled.
  /// Convenience method for widgets.
  bool isFlagEnabled(String flagName) {
    return state.isFlagEnabled(flagName);
  }
}
