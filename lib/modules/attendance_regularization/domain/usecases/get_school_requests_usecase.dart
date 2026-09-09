import '../entities/reg_page.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Loads a page of the school's requests (§9.5) — the admin's pending queue
/// and its approved history, from the same endpoint.
///
/// [status] `null` = all. The default pairing is the queue: `PENDING`, oldest
/// first. A history tab passes `newestFirst`. The dashboard badge calls this
/// with `status: PENDING, size: 1` and reads [RegPage.total].
class GetSchoolRequestsUseCase {
  GetSchoolRequestsUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegPage<RegularizationRequest>> call({
    required String schoolCode,
    RegStatus? status = RegStatus.pending,
    int page = 0,
    int size = 10,
    RegSortOrder sort = RegSortOrder.oldestFirst,
  }) {
    return _repository.getSchoolRequests(
      schoolCode: schoolCode,
      status: status,
      page: page,
      size: size,
      sort: sort,
    );
  }
}
