import '../../core/config/reg_config.dart';
import '../entities/reg_raise_input.dart';
import '../entities/regularization_request.dart';
import '../repositories/regularization_repository.dart';

/// Branch on the response `status`: staff land `PENDING`, an admin's is applied.
class RaiseRegularizationUseCase {
  RaiseRegularizationUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<RegularizationRequest> call(
    RegRaiseInput input, {
    String method = RegConfig.method,
  }) {
    return _repository.raise(input, method: method);
  }
}
