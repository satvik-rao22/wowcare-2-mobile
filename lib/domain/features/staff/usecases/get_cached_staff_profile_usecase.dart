import '../entities/staff_profile.dart';
import '../repositories/staff_repository.dart';

/// Reads a staff profile from the repository's local cache only (no network
/// call), when the repository implementation supports one. Returns `null`
/// when there's no cached copy, or the repository doesn't cache at all.
class GetCachedStaffProfileUseCase {
  GetCachedStaffProfileUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffProfile?> call(String staffCode) {
    final repo = _repository;
    if (repo is StaffRepositoryWithCache) {
      return (repo as StaffRepositoryWithCache).loadCachedStaffProfile(
        staffCode,
      );
    }
    return Future.value(null);
  }
}
