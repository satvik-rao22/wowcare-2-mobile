import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Enables or disables auto-pay for a guardian
/// (`PUT /payment-gateway/autopay/status`).
class SetAutoPayStatusUseCase {
  SetAutoPayStatusUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<AutoPayStatusEntity> call({
    required GuardianScopeParams scope,
    required bool autopayEnabled,
  }) =>
      _repository.setAutoPayStatus(
        scope: scope,
        autopayEnabled: autopayEnabled,
      );
}
