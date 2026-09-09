import '../entities/reg_batch_result.dart';
import '../repositories/regularization_repository.dart';

/// Approves a chosen set of requests as submitted (§9.7).
///
/// The admin always picks the set — there is no "approve all pending".
/// Already-decided items come back under [RegBatchResult.skipped] so a
/// concurrent approval by another admin does not fail the batch (§10.3).
class ApproveSelectedUseCase {
  ApproveSelectedUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegBatchResult> call(List<String> codes) {
    if (codes.isEmpty) return Future.value(const RegBatchResult.empty());
    return _repository.approveSelected(codes);
  }
}
