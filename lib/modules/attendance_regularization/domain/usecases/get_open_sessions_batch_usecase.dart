import '../entities/reg_batch_gate.dart';
import '../repositories/regularization_repository.dart';

/// Checks many staff for unresolved days in one call (§9.1b), so an admin bulk
/// sign-in can sign the clear staff in immediately and gate only the rest.
class GetOpenSessionsBatchUseCase {
  GetOpenSessionsBatchUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegBatchGate> call(List<String> staffCodes) {
    if (staffCodes.isEmpty) return Future.value(const RegBatchGate.empty());
    return _repository.getOpenSessionsBatch(staffCodes);
  }
}
