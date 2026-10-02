import '../entities/reg_page.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Own rows for staff, the whole school for an admin — the token decides.
class GetRequestsUseCase {
  GetRequestsUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegPage<RegularizationRequest>> call({
    String? staffCode,
    RegStatus? status,
    int page = 0,
    int size = 20,
    RegSortOrder sort = RegSortOrder.newestFirst,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _repository.getRequests(
      staffCode: staffCode,
      status: status,
      page: page,
      size: size,
      sort: sort,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
