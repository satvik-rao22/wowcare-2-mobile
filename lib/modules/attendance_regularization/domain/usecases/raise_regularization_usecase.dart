import '../entities/reg_raise_input.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Raises a regularization request (§9.2).
///
/// The resulting status comes from the server's view of the authenticated
/// role — staff `PENDING`, admin auto-approved (§8.2b) — so callers read
/// [RegularizationRequest.status] to choose between "sent for approval" and
/// "applied" rather than guessing.
class RaiseRegularizationUseCase {
  RaiseRegularizationUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegularizationRequest> call(RegRaiseInput input) {
    return _repository.raise(input);
  }
}
