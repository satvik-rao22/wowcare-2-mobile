import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../data/features/messaging/datasources/feature_flag_local_data_source.dart';

/// Use case for retrieving feature flag state.
/// Returns true if flag is enabled, false otherwise.
///
/// Example:
///   final isEnabled = await useCase('bulkMessaging');
///   if (isEnabled) {
///     // Show bulk messaging UI
///   }
class GetFeatureFlagUseCase {
  final FeatureFlagLocalDataSource _dataSource;

  GetFeatureFlagUseCase(this._dataSource);

  /// Check if a feature flag is enabled.
  /// Returns true if enabled, false otherwise (including default value).
  ///
  /// Throws [ArgumentError] if flagName is not a valid feature flag.
  Future<bool> call(String flagName) async {
    try {
      return await _dataSource.isFeatureEnabled(flagName);
    } catch (e) {
      // If flag lookup fails, return safe default (false)
      return false;
    }
  }

  /// Get all feature flags at once (more efficient for bulk load).
  /// Returns Either<Failure, Map<flagName, enabled>>
  Future<Either<Failure, Map<String, bool>>> getAll() async {
    try {
      final flags = await _dataSource.getAllFlags();
      return Right(flags);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load feature flags: ${e.toString()}'),
      );
    }
  }

  /// Check flag in a specific org/school context.
  /// Allows future multi-tenant flag support.
  Future<bool> callForContext({
    required String flagName,
    String? organizationCode,
    String? schoolCode,
    String? userId,
  }) async {
    try {
      return await _dataSource.isFlagEnabledForContext(
        flagName: flagName,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        userId: userId,
      );
    } catch (e) {
      return false;
    }
  }
}
