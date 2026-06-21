import 'package:wowcare/data/features/billing/datasources/auto_pay_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/auto_pay_models.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/auto_pay_repository.dart';

class AutoPayRepositoryImpl implements AutoPayRepository {
  AutoPayRepositoryImpl(this._dataSource);

  final AutoPayRemoteDataSource _dataSource;

  @override
  Future<SchoolForteConfigEntity?> getSchoolForteConfig({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final model = await _dataSource.getSchoolForteConfig(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
    return model?.toEntity();
  }

  @override
  Future<AutoPayStatusEntity> getAutoPayStatus(
      GuardianScopeParams params) async {
    final model = await _dataSource.getAutoPayStatus(
      organizationCode: params.organizationCode,
      schoolCode: params.schoolCode,
      guardianCode: params.guardianCode,
    );
    return model.toEntity();
  }

  @override
  Future<AutoPayStatusEntity> setAutoPayStatus({
    required GuardianScopeParams scope,
    required bool autopayEnabled,
  }) async {
    final model = await _dataSource.setAutoPayStatus(
      organizationCode: scope.organizationCode,
      schoolCode: scope.schoolCode,
      guardianCode: scope.guardianCode,
      autopayEnabled: autopayEnabled,
    );
    return model.toEntity();
  }

  @override
  Future<List<PaymentMethodEntity>> getPaymentMethods(
      GuardianScopeParams params) async {
    final models = await _dataSource.getPaymentMethods(
      organizationCode: params.organizationCode,
      schoolCode: params.schoolCode,
      guardianCode: params.guardianCode,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PaymentMethodEntity> addPaymentMethod(
      AddPaymentMethodParams params) async {
    final model = await _dataSource.addPaymentMethod(
      AddPaymentMethodRequestModel(
        organizationCode: params.organizationCode,
        schoolCode: params.schoolCode,
        guardianCode: params.guardianCode,
        oneTimeToken: params.oneTimeToken,
        methodType: params.methodType.apiValue,
        payMethodHolderName: params.payMethodHolderName,
        label: params.label,
        familyCode: params.familyCode,
        makePrimary: params.makePrimary,
        makeAutopay: params.makeAutopay,
      ),
    );
    return model.toEntity();
  }

  @override
  Future<PaymentMethodEntity> setPrimaryPaymentMethod({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  }) async {
    final model = await _dataSource.setPrimaryPaymentMethod(
      paymentMethodCode: paymentMethodCode,
      organizationCode: scope.organizationCode,
      schoolCode: scope.schoolCode,
      guardianCode: scope.guardianCode,
    );
    return model.toEntity();
  }

  @override
  Future<PaymentMethodEntity> setAutopayMethod({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  }) async {
    final model = await _dataSource.setAutopayMethod(
      paymentMethodCode: paymentMethodCode,
      organizationCode: scope.organizationCode,
      schoolCode: scope.schoolCode,
      guardianCode: scope.guardianCode,
    );
    return model.toEntity();
  }

  @override
  Future<void> deletePaymentMethod({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  }) {
    return _dataSource.deletePaymentMethod(
      paymentMethodCode: paymentMethodCode,
      organizationCode: scope.organizationCode,
      schoolCode: scope.schoolCode,
      guardianCode: scope.guardianCode,
    );
  }

  @override
  Future<PaymentMethodEntity> updatePaymentMethod({
    required String paymentMethodCode,
    required UpdatePaymentMethodParams params,
  }) async {
    final card = params.card;
    final echeck = params.echeck;
    final model = await _dataSource.updatePaymentMethod(
      paymentMethodCode: paymentMethodCode,
      request: UpdatePaymentMethodRequestModel(
        organizationCode: params.organizationCode,
        schoolCode: params.schoolCode,
        guardianCode: params.guardianCode,
        label: params.label,
        notes: params.notes,
        // Only the editable fields are sent per method type.
        card: card == null
            ? null
            : <String, dynamic>{
                if (card.nameOnCard != null) 'name_on_card': card.nameOnCard,
                if (card.expireMonth != null) 'expire_month': card.expireMonth,
                if (card.expireYear != null) 'expire_year': card.expireYear,
              },
        echeck: echeck == null
            ? null
            : <String, dynamic>{
                if (echeck.accountHolder != null)
                  'account_holder': echeck.accountHolder,
                if (echeck.routingNumber != null)
                  'routing_number': echeck.routingNumber,
                if (echeck.accountType != null)
                  'account_type': echeck.accountType,
                if (echeck.itemDescription != null)
                  'item_description': echeck.itemDescription,
              },
      ),
    );
    return model.toEntity();
  }
}
