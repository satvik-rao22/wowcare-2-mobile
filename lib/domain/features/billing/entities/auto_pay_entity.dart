import 'package:equatable/equatable.dart';

/// Supported Forte payment-method types (mirrors backend `PaymentMethodType`).
enum PaymentMethodType { visa, mast, echeck, discover, unknown }

extension PaymentMethodTypeX on PaymentMethodType {
  /// Wire value expected by the backend (`VISA`, `MAST`, `ECHECK`, `DISCOVER`).
  String get apiValue {
    switch (this) {
      case PaymentMethodType.visa:
        return 'VISA';
      case PaymentMethodType.mast:
        return 'MAST';
      case PaymentMethodType.echeck:
        return 'ECHECK';
      case PaymentMethodType.discover:
        return 'DISCOVER';
      case PaymentMethodType.unknown:
        return 'VISA';
    }
  }

  bool get isEcheck => this == PaymentMethodType.echeck;

  static PaymentMethodType fromApi(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'VISA':
        return PaymentMethodType.visa;
      case 'MAST':
      case 'MASTERCARD':
        return PaymentMethodType.mast;
      case 'ECHECK':
      case 'ACH':
        return PaymentMethodType.echeck;
      case 'DISC':
      case 'DISCOVER':
        return PaymentMethodType.discover;
      default:
        return PaymentMethodType.unknown;
    }
  }
}

/// School-level Forte config (`GET /school-forte-configs`). The only field the
/// app needs today is [apiLoginId], used to initialize the Forte JS SDK.
class SchoolForteConfigEntity extends Equatable {
  const SchoolForteConfigEntity({
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

  /// Max saved payment methods allowed (from school config); null = unknown.
  final int? maxPaymentMethods;

  bool get hasApiLoginId => apiLoginId.trim().isNotEmpty;

  @override
  List<Object?> get props =>
      [apiLoginId, code, schoolCode, organizationCode, status, maxPaymentMethods];
}

/// Card details on a saved payment method.
class PaymentMethodCardEntity extends Equatable {
  const PaymentMethodCardEntity({
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

  @override
  List<Object?> get props =>
      [nameOnCard, last4, maskedAccountNumber, expireMonth, expireYear, cardType];
}

/// eCheck (ACH) details on a saved payment method.
class PaymentMethodEcheckEntity extends Equatable {
  const PaymentMethodEcheckEntity({
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

  @override
  List<Object?> get props => [
        accountHolder,
        maskedAccountNumber,
        last4,
        routingNumber,
        accountType,
        itemDescription,
      ];
}

/// A saved payment method (`GET/POST /payment-gateway/payment-methods`).
class PaymentMethodEntity extends Equatable {
  const PaymentMethodEntity({
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
    this.acceptedByPolicy = true,
  });

  final String code;
  final PaymentMethodType methodType;
  final String? label;
  final String? last4;
  final bool primary;
  final bool autopay;
  final bool defaultAtGateway;
  final String? status;
  final PaymentMethodCardEntity? card;
  final PaymentMethodEcheckEntity? echeck;

  /// Whether the school currently accepts this method's type (from
  /// `GET /payment-gateway/payment-methods`'s `acceptedByPolicy`). A school
  /// can stop accepting a method type (e.g. turn off credit cards) after a
  /// guardian already saved one — this stays `false` for that saved method
  /// until they either remove it or the school re-enables the type, and it's
  /// what drives greying the method out / the "AutoPay isn't able to run"
  /// banner when it's the active auto-pay method.
  final bool acceptedByPolicy;

  bool get isEcheck => methodType == PaymentMethodType.echeck;

  @override
  List<Object?> get props => [
        code,
        methodType,
        label,
        last4,
        primary,
        autopay,
        defaultAtGateway,
        status,
        card,
        echeck,
        acceptedByPolicy,
      ];
}

/// Auto-pay on/off status for a guardian (`GET /payment-gateway/autopay/status`).
class AutoPayStatusEntity extends Equatable {
  const AutoPayStatusEntity({
    required this.guardianCode,
    required this.autopayEnabled,
  });

  final String guardianCode;
  final bool autopayEnabled;

  @override
  List<Object?> get props => [guardianCode, autopayEnabled];
}

/// Params for `POST /payment-gateway/payment-methods`.
///
/// [makePrimary] and [makeAutopay] are always sent as `false` per current
/// product requirements; primary/auto-pay is changed via a separate endpoint.
class AddPaymentMethodParams extends Equatable {
  const AddPaymentMethodParams({
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
  final PaymentMethodType methodType;

  /// Cardholder / account-holder name — sent as `payMethodHolderName`. Forte
  /// requires this (name_on_card) when converting the one-time token.
  final String payMethodHolderName;
  final String? label;
  final String? familyCode;
  final bool makePrimary;
  final bool makeAutopay;

  @override
  List<Object?> get props => [
        organizationCode,
        schoolCode,
        guardianCode,
        oneTimeToken,
        methodType,
        payMethodHolderName,
        label,
        familyCode,
        makePrimary,
        makeAutopay,
      ];
}

/// Params for `PUT /payment-gateway/payment-methods/{code}` (edit metadata:
/// account-holder name / label — the tokenized card/account itself is immutable).
class UpdatePaymentMethodParams extends Equatable {
  const UpdatePaymentMethodParams({
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

  /// Updated card object (existing values + new name_on_card). Null for eCheck.
  final PaymentMethodCardEntity? card;

  /// Updated echeck object (existing values + new account_holder). Null for card.
  final PaymentMethodEcheckEntity? echeck;

  @override
  List<Object?> get props =>
      [organizationCode, schoolCode, guardianCode, label, notes, card, echeck];
}

/// Common org/school/guardian scope passed to the read + primary endpoints.
class GuardianScopeParams extends Equatable {
  const GuardianScopeParams({
    required this.organizationCode,
    required this.schoolCode,
    required this.guardianCode,
  });

  final String organizationCode;
  final String schoolCode;
  final String guardianCode;

  @override
  List<Object?> get props => [organizationCode, schoolCode, guardianCode];
}

/// A guardian's per-child split of a Pay Now charge. When the parent enters an
/// amount against individual children, each child becomes one allocation so the
/// backend applies the money to that student's invoices instead of the
/// family-wide oldest-invoice-first default.
class PaymentAllocationEntity extends Equatable {
  const PaymentAllocationEntity({
    required this.studentCode,
    required this.amount,
  });

  final String studentCode;
  final double amount;

  @override
  List<Object?> get props => [studentCode, amount];
}

/// Request to charge a guardian's saved payment method
/// (`POST /payment-gateway/guardian/pay`).
class GuardianPayParams extends Equatable {
  const GuardianPayParams({
    required this.organizationCode,
    required this.schoolCode,
    required this.guardianCode,
    required this.ownerType,
    required this.ownerCode,
    required this.paymentMethodCode,
    required this.amount,
    required this.idempotencyKey,
    required this.payMethodHolderName,
    this.preference = 'SELECTED',
    this.allocations = const <PaymentAllocationEntity>[],
  });

  final String organizationCode;
  final String schoolCode;
  final String guardianCode;
  final String ownerType;
  final String ownerCode;
  final String paymentMethodCode;
  final double amount;

  /// A unique key per payment attempt (`MOBILE-<uuid>`). The SAME key is reused
  /// across retries of one attempt so the backend can dedupe double-submits.
  final String idempotencyKey;
  final String payMethodHolderName;
  final String preference;

  /// Per-child split of [amount]. Empty means pay the whole [amount]
  /// family-wide (oldest invoice first); non-empty splits it per student.
  final List<PaymentAllocationEntity> allocations;

  @override
  List<Object?> get props => [
        organizationCode,
        schoolCode,
        guardianCode,
        ownerType,
        ownerCode,
        paymentMethodCode,
        amount,
        idempotencyKey,
        payMethodHolderName,
        preference,
        allocations,
      ];
}

/// Result of a guardian pay charge (`data` of the pay response).
class GuardianPayResultEntity extends Equatable {
  const GuardianPayResultEntity({
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

  @override
  List<Object?> get props => [
        paymentGatewayTransactionCode,
        gatewayTransactionId,
        status,
        methodType,
        baseAmount,
        convenienceFee,
        totalCharged,
        feePayer,
        ownerCode,
        amountApplied,
        creditBalance,
      ];
}
