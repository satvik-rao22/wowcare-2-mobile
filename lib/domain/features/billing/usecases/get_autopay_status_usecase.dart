import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Reads the guardian's auto-pay on/off status
/// (`GET /payment-gateway/autopay/status`).
class GetAutoPayStatusUseCase {
  GetAutoPayStatusUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<AutoPayStatusEntity> call(GuardianScopeParams params) =>
      _repository.getAutoPayStatus(params);
}
