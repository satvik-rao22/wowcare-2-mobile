import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Omitting [signOutLocal] approves as submitted; supplying it keeps both the
/// requested and the approved time on the record.
class ApproveRequestUseCase {
  ApproveRequestUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegularizationRequest> call(
    String code, {
    DateTime? signOutLocal,
    String note = '',
  }) {
    return _repository.approve(code, signOutLocal: signOutLocal, note: note);
  }
}
