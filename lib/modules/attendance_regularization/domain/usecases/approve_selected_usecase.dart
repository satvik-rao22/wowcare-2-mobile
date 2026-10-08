import '../entities/reg_batch_result.dart';
import '../repositories/regularization_repository.dart';

/// Each approved as submitted. Already-decided items come back skipped, so one
/// stale checkbox does not fail the other nine.
class ApproveSelectedUseCase {
  ApproveSelectedUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegBatchResult> call(List<String> codes) {
    if (codes.isEmpty) return Future.value(const RegBatchResult.empty());
    return _repository.approveSelected(codes);
  }
}
