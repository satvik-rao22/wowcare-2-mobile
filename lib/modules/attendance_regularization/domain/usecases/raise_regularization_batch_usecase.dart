import '../entities/reg_batch_result.dart';
import '../entities/reg_raise_input.dart';
import '../repositories/regularization_repository.dart';

/// Admin only. Items that already have a request are skipped, not failed.
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
