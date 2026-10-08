import '../entities/reg_edit_input.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// The raiser fixing their own request before review. Replaces cancel: the
/// pending row stays alive, so the gate is never re-triggered by a correction.
class EditRegularizationUseCase {
  EditRegularizationUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegularizationRequest> call(RegEditInput input) =>
      _repository.edit(input);
}
