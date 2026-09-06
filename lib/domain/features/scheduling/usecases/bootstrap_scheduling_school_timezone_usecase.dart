import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/school_timezone_resolver.dart';

/// Resolves and caches the current school's IANA timezone for scheduling
/// screens. [SchoolTimezoneResolver] caches its result internally, so
/// calling this from multiple cubits is cheap.
class BootstrapSchedulingSchoolTimezoneUseCase {
  const BootstrapSchedulingSchoolTimezoneUseCase({
    required StorageService storage,
    required ApiClient apiClient,
  })  : _storage = storage,
        _apiClient = apiClient;

  final StorageService _storage;
  final ApiClient _apiClient;

  Future<String> call() {
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
  }
}
