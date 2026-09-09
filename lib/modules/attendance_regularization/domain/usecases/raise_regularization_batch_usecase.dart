import '../entities/reg_batch_result.dart';
import '../entities/reg_raise_input.dart';
import '../repositories/regularization_repository.dart';

/// Raises many requests in one call (§9.2b) — the bulk sign-in gate's submit.
///
/// Admin-only, so every item is auto-approved and applied (§8.2b). Items that
/// already have a request are skipped, not errored (§8.6).
class RaiseRegularizationBatchUseCase {
  RaiseRegularizationBatchUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegBatchResult> call(
    List<RegRaiseInput> items, {
    required String sharedReason,
  }) {
    if (items.isEmpty) return Future.value(const RegBatchResult.empty());
    return _repository.raiseBatch(items, sharedReason: sharedReason);
  }
}
