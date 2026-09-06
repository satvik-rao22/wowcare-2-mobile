import '../repositories/staff_repository.dart';

/// Drops the cached staff-list page for a query, so the next load is forced to
/// come from the API.
///
/// Used after a mutation (activate / deactivate / delete) whose effect the
/// cached page would otherwise hide. A repository without a cache is a no-op —
/// see [LoadCachedStaffPageUseCase] for why the capability test lives here
/// rather than in the cubit.
class InvalidateCachedStaffPageUseCase {
  InvalidateCachedStaffPageUseCase(this._repository);

  final StaffRepository _repository;

  Future<void> call(
    String schoolCode, {
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  }) async {
    final repository = _repository;
    if (repository is! StaffRepositoryWithCache) return;
    await (repository as StaffRepositoryWithCache).invalidateCachedStaffPage(
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
