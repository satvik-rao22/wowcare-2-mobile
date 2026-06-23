import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/entities/payment_settings_entity.dart';

/// `data` from `GET /api/v1/payment/settings`.
class PaymentSettingsModel {
  const PaymentSettingsModel({
    required this.acceptCreditCard,
    required this.creditCardFeePaidBy,
    required this.acceptDebitCard,
    required this.debitCardFeePaidBy,
    required this.acceptAch,
    required this.achFeePaidBy,
    this.schoolCode,
  });

  final bool acceptCreditCard;
  final String creditCardFeePaidBy;
  final bool acceptDebitCard;
  final String debitCardFeePaidBy;
  final bool acceptAch;
  final String achFeePaidBy;
  final String? schoolCode;

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    bool b(String key) => json[key] == true;
    String s(String key) => (json[key] ?? '').toString();
    return PaymentSettingsModel(
      acceptCreditCard: b('acceptCreditCard'),
      creditCardFeePaidBy: s('creditCardFeePaidBy'),
      acceptDebitCard: b('acceptDebitCard'),
      debitCardFeePaidBy: s('debitCardFeePaidBy'),
      acceptAch: b('acceptAch'),
      achFeePaidBy: s('achFeePaidBy'),
      schoolCode: json['schoolCode']?.toString(),
    );
  }

  static FeePayer _payer(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'PARENT':
        return FeePayer.parent;
      case 'SCHOOL':
        return FeePayer.school;
      default:
        return FeePayer.unknown;
    }
  }

  PaymentSettingsEntity toEntity() => PaymentSettingsEntity(
        acceptCreditCard: acceptCreditCard,
        creditCardFeePaidBy: _payer(creditCardFeePaidBy),
        acceptDebitCard: acceptDebitCard,
        debitCardFeePaidBy: _payer(debitCardFeePaidBy),
        acceptAch: acceptAch,
        achFeePaidBy: _payer(achFeePaidBy),
        schoolCode: schoolCode ?? '',
      );
}

/// One item from `GET /school-forte-configs` (`data.content[]`).
class SchoolForteConfigModel {
  const SchoolForteConfigModel({
    required this.apiLoginId,
    this.code,
    this.schoolCode,
    this.organizationCode,
    this.status,
    this.maxPaymentMethods,
  });

  final String apiLoginId;
  final String? code;
  final String? schoolCode;
  final String? organizationCode;
  final String? status;
  final int? maxPaymentMethods;

  factory SchoolForteConfigModel.fromJson(Map<String, dynamic> json) {
    // The max-methods limit may arrive under a few possible keys.
    final maxRaw = json['maxPaymentMethods'] ??
        json['maxMethods'] ??
        json['paymentMethodLimit'] ??
        json['maxPaymentMethodCount'];
    return SchoolForteConfigModel(
      apiLoginId: (json['apiLoginId'] ?? '').toString(),
      code: json['code']?.toString(),
      schoolCode: json['schoolCode']?.toString(),
      organizationCode: json['organizationCode']?.toString(),
      status: json['status']?.toString(),
      maxPaymentMethods:
          maxRaw is num ? maxRaw.toInt() : int.tryParse('${maxRaw ?? ''}'),
    );
  }

  SchoolForteConfigEntity toEntity() => SchoolForteConfigEntity(
        apiLoginId: apiLoginId,
        code: code,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        status: status,
        maxPaymentMethods: maxPaymentMethods,
      );
}

/// `data` from `GET /payment-gateway/autopay/status`.
class AutoPayStatusModel {
  const AutoPayStatusModel({
    required this.guardianCode,
    required this.autopayEnabled,
  });

  final String guardianCode;
  final bool autopayEnabled;

  factory AutoPayStatusModel.fromJson(Map<String, dynamic> json) {
    return AutoPayStatusModel(
      guardianCode: (json['guardianCode'] ?? '').toString(),
      autopayEnabled: json['autopayEnabled'] == true,
    );
  }

  AutoPayStatusEntity toEntity() => AutoPayStatusEntity(
        guardianCode: guardianCode,
        autopayEnabled: autopayEnabled,
      );
}

class PaymentMethodCardModel {
  const PaymentMethodCardModel({
    this.nameOnCard,
    this.last4,
    this.maskedAccountNumber,
    this.expireMonth,
    this.expireYear,
    this.cardType,
  });

  final String? nameOnCard;
  final String? last4;
  final String? maskedAccountNumber;
  final int? expireMonth;
  final int? expireYear;
  final String? cardType;

  factory PaymentMethodCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodCardModel(
      nameOnCard: json['name_on_card']?.toString(),
      last4: json['last_4_account_number']?.toString(),
      maskedAccountNumber: json['masked_account_number']?.toString(),
      expireMonth: (json['expire_month'] as num?)?.toInt(),
      expireYear: (json['expire_year'] as num?)?.toInt(),
      cardType: json['card_type']?.toString(),
    );
  }

  PaymentMethodCardEntity toEntity() => PaymentMethodCardEntity(
        nameOnCard: nameOnCard,
        last4: last4,
        maskedAccountNumber: maskedAccountNumber,
        expireMonth: expireMonth,
        expireYear: expireYear,
        cardType: cardType,
      );
}

class PaymentMethodEcheckModel {
  const PaymentMethodEcheckModel({
    this.accountHolder,
    this.maskedAccountNumber,
    this.last4,
    this.routingNumber,
    this.accountType,
    this.itemDescription,
  });

  final String? accountHolder;
  final String? maskedAccountNumber;
  final String? last4;
  final String? routingNumber;
  final String? accountType;
  final String? itemDescription;

  factory PaymentMethodEcheckModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodEcheckModel(
      accountHolder: json['account_holder']?.toString(),
      maskedAccountNumber: json['masked_account_number']?.toString(),
      last4: json['last_4_account_number']?.toString(),
      routingNumber: json['routing_number']?.toString(),
      accountType: json['account_type']?.toString(),
      itemDescription: json['item_description']?.toString(),
    );
  }

  PaymentMethodEcheckEntity toEntity() => PaymentMethodEcheckEntity(
        accountHolder: accountHolder,
        maskedAccountNumber: maskedAccountNumber,
        last4: last4,
        routingNumber: routingNumber,
        accountType: accountType,
        itemDescription: itemDescription,
      );
}

/// A saved payment method from list/create/primary responses.
class PaymentMethodModel {
  const PaymentMethodModel({
    required this.code,
    required this.methodType,
    this.label,
    this.last4,
    this.primary = false,
    this.autopay = false,
    this.defaultAtGateway = false,
    this.status,
    this.card,
    this.echeck,
  });

  final String code;
  final String? methodType;
  final String? label;
  final String? last4;
  final bool primary;
  final bool autopay;
  final bool defaultAtGateway;
  final String? status;
  final PaymentMethodCardModel? card;
  final PaymentMethodEcheckModel? echeck;

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final cardJson = json['card'];
    final echeckJson = json['echeck'];
    return PaymentMethodModel(
      code: (json['code'] ?? '').toString(),
      methodType: json['methodType']?.toString(),
      label: json['label']?.toString(),
      last4: json['last4']?.toString(),
      primary: json['primary'] == true,
      autopay: json['autopay'] == true,
      defaultAtGateway: json['defaultAtGateway'] == true,
      status: json['status']?.toString(),
      card: cardJson is Map<String, dynamic>
          ? PaymentMethodCardModel.fromJson(cardJson)
          : null,
      echeck: echeckJson is Map<String, dynamic>
          ? PaymentMethodEcheckModel.fromJson(echeckJson)
          : null,
    );
  }

  PaymentMethodEntity toEntity() => PaymentMethodEntity(
        code: code,
        methodType: PaymentMethodTypeX.fromApi(methodType),
        label: label,
        last4: last4,
        primary: primary,
        autopay: autopay,
        defaultAtGateway: defaultAtGateway,
        status: status,
        card: card?.toEntity(),
        echeck: echeck?.toEntity(),
      );
}

/// Request body for `POST /payment-gateway/payment-methods`.
class AddPaymentMethodRequestModel {
  const AddPaymentMethodRequestModel({
    required this.organizationCode,
    required this.schoolCode,
    required this.guardianCode,
    required this.oneTimeToken,
    required this.methodType,
    required this.payMethodHolderName,
    this.label,
    this.familyCode,
    this.makePrimary = false,
    this.makeAutopay = false,
  });

  final String organizationCode;
  final String schoolCode;
  final String guardianCode;
  final String oneTimeToken;
  final String methodType;
  final String payMethodHolderName;
  final String? label;
  final String? familyCode;
  final bool makePrimary;
  final bool makeAutopay;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
        'oneTimeToken': oneTimeToken,
        'methodType': methodType,
        if (label != null && label!.trim().isNotEmpty) 'label': label,
        'payMethodHolderName': payMethodHolderName,
        if (familyCode != null && familyCode!.trim().isNotEmpty)
          'familyCode': familyCode,
        'makePrimary': makePrimary,
        'makeAutopay': makeAutopay,
      };
}

/// Request body for `PUT /payment-gateway/payment-methods/{code}`.
class UpdatePaymentMethodRequestModel {
  const UpdatePaymentMethodRequestModel({
    required this.organizationCode,
    required this.schoolCode,
    required this.guardianCode,
    this.label,
    this.notes,
    this.card,
    this.echeck,
  });

  final String organizationCode;
  final String schoolCode;
  final String guardianCode;
  final String? label;
  final String? notes;
  final Map<String, dynamic>? card;
  final Map<String, dynamic>? echeck;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
        if (label != null && label!.trim().isNotEmpty) 'label': label,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
        if (card != null) 'card': card,
        if (echeck != null) 'echeck': echeck,
      };
}

/// Request body for `POST /payment-gateway/guardian/pay`.
class GuardianPayRequestModel {
  const GuardianPayRequestModel(this.params);

  final GuardianPayParams params;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'organizationCode': params.organizationCode,
        'schoolCode': params.schoolCode,
        'guardianCode': params.guardianCode,
        'ownerType': params.ownerType,
        'ownerCode': params.ownerCode,
        'paymentMethodCode': params.paymentMethodCode,
        'preference': params.preference,
        'amount': params.amount,
        'idempotencyKey': params.idempotencyKey,
        'payMethodHolderName': params.payMethodHolderName,
      };
}

/// `data` of the guardian pay response.
class GuardianPayResultModel {
  const GuardianPayResultModel({
    required this.paymentGatewayTransactionCode,
    required this.gatewayTransactionId,
    required this.status,
    required this.methodType,
    required this.baseAmount,
    required this.convenienceFee,
    required this.totalCharged,
    required this.feePayer,
    required this.ownerCode,
    required this.amountApplied,
    required this.creditBalance,
  });

  final String paymentGatewayTransactionCode;
  final String gatewayTransactionId;
  final String status;
  final String methodType;
  final double baseAmount;
  final double convenienceFee;
  final double totalCharged;
  final String feePayer;
  final String ownerCode;
  final double amountApplied;
  final double creditBalance;

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
  static String _s(dynamic v) => (v as String?)?.trim() ?? '';

  factory GuardianPayResultModel.fromJson(Map<String, dynamic> json) =>
      GuardianPayResultModel(
        paymentGatewayTransactionCode: _s(json['paymentGatewayTransactionCode']),
        gatewayTransactionId: _s(json['gatewayTransactionId']),
        status: _s(json['status']),
        methodType: _s(json['methodType']),
        baseAmount: _d(json['baseAmount']),
        convenienceFee: _d(json['convenienceFee']),
        totalCharged: _d(json['totalCharged']),
        feePayer: _s(json['feePayer']),
        ownerCode: _s(json['ownerCode']),
        amountApplied: _d(json['amountApplied']),
        creditBalance: _d(json['creditBalance']),
      );

  GuardianPayResultEntity toEntity() => GuardianPayResultEntity(
        paymentGatewayTransactionCode: paymentGatewayTransactionCode,
        gatewayTransactionId: gatewayTransactionId,
        status: status,
        methodType: methodType,
        baseAmount: baseAmount,
        convenienceFee: convenienceFee,
        totalCharged: totalCharged,
        feePayer: feePayer,
        ownerCode: ownerCode,
        amountApplied: amountApplied,
        creditBalance: creditBalance,
      );
}
