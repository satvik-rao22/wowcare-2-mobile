import '../entities/reg_batch_gate.dart';
import '../repositories/regularization_repository.dart';

/// The gate. No [staffCodes] asks about the caller; a list asks about a roster.
class CheckGateUseCase {
  CheckGateUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegBatchGate> call({List<String>? staffCodes}) {
    if (staffCodes != null && staffCodes.isEmpty) {
      return Future.value(const RegBatchGate.empty());
    }
    return _repository.checkGate(staffCodes: staffCodes);
  }
}
