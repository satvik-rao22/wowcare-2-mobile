import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Approves one request, optionally modifying the time (§9.6).
///
/// [signOutLocal] `null` approves as submitted; supplying it becomes the
/// approved time while the original stays on the request (§7.4). There is no
/// reject (§8.4).
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
