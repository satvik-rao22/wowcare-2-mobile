import '../entities/payment_settings_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Reads a school's payment settings (`GET /api/v1/payment/settings`) — accepted
/// method types and who pays the convenience fee.
class GetPaymentSettingsUseCase {
  GetPaymentSettingsUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<PaymentSettingsEntity?> call({required String schoolCode}) =>
      _repository.getPaymentSettings(schoolCode: schoolCode);
}
