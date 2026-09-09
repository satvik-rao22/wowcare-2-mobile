import '../entities/reg_page.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Loads a page of the staff's own requests (§9.3). [status] `null` = all.
class GetMyRequestsUseCase {
  GetMyRequestsUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegPage<RegularizationRequest>> call({
    required String staffCode,
    RegStatus? status,
    int page = 0,
    int size = 20,
    RegSortOrder sort = RegSortOrder.newestFirst,
  }) {
    return _repository.getMyRequests(
      staffCode: staffCode,
      status: status,
      page: page,
      size: size,
      sort: sort,
    );
  }
}
