import '../entities/reg_edit_input.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Revises a still-`PENDING` request (§9.4).
///
/// This replaces cancel (§8.4): the `PENDING` row stays alive while its time
/// and/or reason change, so the gate remains satisfied and the staff is never
/// re-blocked mid-day by their own correction. Fails with `409` once the
/// request is approved.
class EditRegularizationUseCase {
  EditRegularizationUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegularizationRequest> call(RegEditInput input) {
    return _repository.edit(input);
  }
}
