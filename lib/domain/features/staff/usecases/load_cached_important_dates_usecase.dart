import '../entities/staff_important_date.dart';
import '../repositories/staff_repository.dart';

/// Reads the locally cached important dates for a staff member.
///
/// See [LoadCachedStaffProfileUseCase] for why the cache-capability test lives
/// here rather than in the cubit.
class LoadCachedImportantDatesUseCase {
  LoadCachedImportantDatesUseCase(this._repository);

  final StaffRepository _repository;

  Future<List<StaffImportantDate>?> call(String staffCode) {
    final repository = _repository;
    if (repository is! StaffRepositoryWithCache) return Future.value(null);
    return (repository as StaffRepositoryWithCache).loadCachedImportantDates(
      staffCode,
    );
  }
}
