import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../data/features/messaging/datasources/feature_flag_local_data_source.dart';

/// Use case for setting/updating a feature flag state.
/// Persists the flag value to local storage.
///
/// Example:
///   await useCase(flagName: 'bulkMessaging', enabled: true);
///
/// Note: This is primarily for testing/debugging. In production, feature flags
/// should be controlled by backend API. This local override is useful for:
/// - Testing features before backend rollout
/// - Debugging in development
/// - Emergency disable (manual toggle)
class SetFeatureFlagUseCase {
  final FeatureFlagLocalDataSource _dataSource;

  SetFeatureFlagUseCase(this._dataSource);

  /// Set a feature flag to enabled/disabled state.
  /// Returns Either<Failure, void>.
  Future<Either<Failure, void>> call({
    required String flagName,
    required bool enabled,
  }) async {
    try {
      await _dataSource.setFeatureEnabled(flagName, enabled);
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to set feature flag $flagName: ${e.toString()}'),
      );
    }
  }

  /// Clear all feature flag overrides and revert to defaults.
  /// Used for testing and debugging.
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _dataSource.clearAllFlags();
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to clear feature flags: ${e.toString()}'),
      );
    }
  }
}
