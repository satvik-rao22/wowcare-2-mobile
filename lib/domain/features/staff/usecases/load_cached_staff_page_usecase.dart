import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

/// Reads the locally cached first page of the staff list, so the list can
/// paint before the network round-trip completes.
///
/// Caching is an optional capability: a [StaffRepository] that does not
/// implement [StaffRepositoryWithCache] simply has no cache, and this use case
/// reports a miss rather than making the caller type-test the repository.
/// That test is what previously forced [StaffCubit] to hold a repository
/// reference in violation of the View → Cubit → UseCase → Repository rule.
class LoadCachedStaffPageUseCase {
  LoadCachedStaffPageUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffPage?> call(
    String schoolCode, {
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  }) {
    final repository = _repository;
    if (repository is! StaffRepositoryWithCache) return Future.value(null);
    return (repository as StaffRepositoryWithCache).loadCachedStaffPage(
      schoolCode,
      status: status,
      designation: designation,
      search: search,
      primaryClassroomCodes: primaryClassroomCodes,
      classCodes: classCodes,
      sortBy: sortBy,
      attendanceStatuses: attendanceStatuses,
    );
  }
}
