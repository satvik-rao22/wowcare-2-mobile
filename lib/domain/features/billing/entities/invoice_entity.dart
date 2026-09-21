import 'package:equatable/equatable.dart';

/// A single row from the Transactions list (`GET /invoices/transactions`).
class InvoiceTransactionEntity extends Equatable {
  const InvoiceTransactionEntity({
    required this.id,
    required this.type,
    required this.date,
    required this.familyCode,
    required this.familyName,
    required this.studentCode,
    required this.studentName,
    required this.description,
    required this.status,
    required this.method,
    required this.amount,
    required this.paidAmount,
    required this.refundedAmount,
    required this.invoiceCode,
    this.gatewayPayment = false,
  });

  final String id;
  final String type;
  final DateTime? date;
  final String familyCode;
  final String familyName;
  final String studentCode;
  final String studentName;
  final String description;
  final String status;
  final String? method;
  final double amount;

  /// Whether this transaction was processed through the payment gateway
  /// (an "Online" card/ACH charge) rather than manually recorded (Cash,
  /// Cheque, Other).
  final bool gatewayPayment;

  /// Amount already paid against this invoice; `0` means it can still be cancelled.
  final double paidAmount;

  /// Amount already refunded against this invoice (max refundable = amount −
  /// refundedAmount).
  final double refundedAmount;
  final String invoiceCode;

  @override
  List<Object?> get props => [
        id,
        type,
        date,
        familyCode,
        familyName,
        studentCode,
        studentName,
        description,
        status,
        method,
        amount,
        paidAmount,
        refundedAmount,
        invoiceCode,
        gatewayPayment,
      ];
}

/// One page of transactions plus whether more pages exist.
typedef InvoiceTransactionsPage = ({
  List<InvoiceTransactionEntity> items,
  bool hasMore,
  int totalElements,
});

/// Params for creating a single invoice (one student per invoice).
class CreateInvoiceItemParams extends Equatable {
  const CreateInvoiceItemParams({
    required this.itemType,
    required this.description,
    required this.amount,
    this.quantity = 1,
    this.sourceCode,
    this.valueType,
    this.valueInput,
  });

  final String itemType;
  final String description;
  final double amount;
  final int quantity;
  final String? sourceCode;
  final String? valueType;
  final double? valueInput;

  @override
  List<Object?> get props =>
      [itemType, description, amount, quantity, sourceCode, valueType, valueInput];
}

class CreateInvoiceParams extends Equatable {
  const CreateInvoiceParams({
    required this.organizationCode,
    required this.schoolCode,
    required this.studentCode,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    this.periodStart,
    this.periodEnd,
    this.notes,
    this.currency,
  });

  final String organizationCode;
  final String schoolCode;
  final String studentCode;
  final DateTime issueDate;
  final DateTime dueDate;

  /// Optional service period sent as `periodStart` / `periodEnd`.
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<CreateInvoiceItemParams> items;
  final String? notes;
  final String? currency;

  @override
  List<Object?> get props => [
        organizationCode,
        schoolCode,
        studentCode,
        issueDate,
        dueDate,
        periodStart,
        periodEnd,
        items,
        notes,
        currency,
      ];
}

/// Params for `PATCH /api/v1/invoices/{invoiceCode}/draft` (edit draft invoice).
///
/// The draft endpoint takes the same body shape as create, so items reuse
/// [CreateInvoiceItemParams] (each carries `itemType`/`amount`). `schoolCode` is
/// required by the backend.
class UpdateInvoiceParams extends Equatable {
  const UpdateInvoiceParams({
    this.organizationCode,
    this.schoolCode,
    this.studentCode,
    this.ownerType,
    this.ownerCode,
    this.issueDate,
    this.dueDate,
    this.periodStart,
    this.periodEnd,
    this.currency,
    this.notes,
    this.items,
  });

  final String? organizationCode;
  final String? schoolCode;
  final String? studentCode;
  final String? ownerType;
  final String? ownerCode;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? currency;
  final String? notes;
  final List<CreateInvoiceItemParams>? items;

  @override
  List<Object?> get props => [
        organizationCode,
        schoolCode,
        studentCode,
        ownerType,
        ownerCode,
        issueDate,
        dueDate,
        periodStart,
        periodEnd,
        currency,
        notes,
        items,
      ];
}

/// Aggregated billing totals from `GET /api/v1/invoices/overview`.
class InvoiceOverviewEntity extends Equatable {
  const InvoiceOverviewEntity({
    required this.amountInvoiced,
    required this.paid,
    required this.refunded,
    required this.netPaid,
    required this.inProcess,
    required this.outstanding,
  });

  final double amountInvoiced;
  final double paid;
  final double refunded;
  final double netPaid;
  final double inProcess;
  final double outstanding;

  double _pct(double value) =>
      amountInvoiced <= 0 ? 0 : (value / amountInvoiced) * 100;

  double get netPaidPercent => _pct(netPaid);
  double get paidPercent => _pct(paid);
  double get refundedPercent => _pct(refunded);
  double get inProcessPercent => _pct(inProcess);
  double get outstandingPercent => _pct(outstanding);

  @override
  List<Object?> get props =>
      [amountInvoiced, paid, refunded, netPaid, inProcess, outstanding];
}

/// Params for a payment (`/payments`) or refund (`/refunds`).
class InvoicePaymentParams extends Equatable {
  const InvoicePaymentParams({
    required this.schoolCode,
    required this.amount,
    required this.date,
    this.ownerType,
    this.ownerCode,
    this.studentCode,
    this.method,
    this.reference,
    this.narration,
    this.idempotencyKey,
  });

  final String schoolCode;
  final double amount;
  final DateTime date;
  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? method;
  final String? reference;
  final String? narration;

  /// Stable per-operation key sent as the `Idempotency-Key` header so the
  /// backend dedupes a retried/replayed payment or refund. Kept stable across
  /// retries of the SAME logical operation; the cubit rotates it after success.
  final String? idempotencyKey;

  @override
  List<Object?> get props => [
        schoolCode,
        amount,
        date,
        ownerType,
        ownerCode,
        studentCode,
        method,
        reference,
        narration,
        idempotencyKey,
      ];
}

/// Params for a credit (`POST /api/v1/invoices/credits`).
class CreateCreditParams extends Equatable {
  const CreateCreditParams({
    required this.schoolCode,
    required this.amount,
    this.ownerType,
    this.ownerCode,
    this.studentCode,
    this.reason,
    this.description,
    this.idempotencyKey,
  });

  final String schoolCode;
  final double amount;
  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? reason;
  final String? description;

  /// Stable per-operation `Idempotency-Key` for the credit POST (see
  /// [InvoicePaymentParams.idempotencyKey]).
  final String? idempotencyKey;

  @override
  List<Object?> get props => [
        schoolCode,
        amount,
        ownerType,
        ownerCode,
        studentCode,
        reason,
        description,
        idempotencyKey,
      ];
}

/// One student's result from `POST /api/v1/invoices/check-recipients`.
class RecipientEligibilityEntity extends Equatable {
  const RecipientEligibilityEntity({
    required this.studentCode,
    required this.eligible,
    this.reason,
  });

  final String studentCode;
  final bool eligible;

  /// Populated when [eligible] is false — why this student can't receive an
  /// invoice yet (e.g. no family/billing profile).
  final String? reason;

  @override
  List<Object?> get props => [studentCode, eligible, reason];
}

/// Result of `POST /api/v1/invoices/check-recipients` — run before creating
/// an invoice to confirm every selected student can actually receive one.
class CheckRecipientsResultEntity extends Equatable {
  const CheckRecipientsResultEntity({
    required this.allEligible,
    required this.recipients,
  });

  final bool allEligible;
  final List<RecipientEligibilityEntity> recipients;

  /// The subset that failed the check, for surfacing reasons to the user.
  List<RecipientEligibilityEntity> get ineligible =>
      recipients.where((r) => !r.eligible).toList();

  @override
  List<Object?> get props => [allEligible, recipients];
}

class InvoicePaymentResultEntity extends Equatable {
  const InvoicePaymentResultEntity({
    this.ledgerCode,
    this.amount,
    this.amountApplied,
    this.creditBalance,
  });

  final String? ledgerCode;
  final double? amount;
  final double? amountApplied;
  final double? creditBalance;

  @override
  List<Object?> get props => [ledgerCode, amount, amountApplied, creditBalance];
}

class InvoiceResultEntity extends Equatable {
  const InvoiceResultEntity({
    required this.code,
    this.status,
    this.invoiceStatus,
    this.total,
  });

  final String code;
  final String? status;
  final String? invoiceStatus;
  final double? total;

  @override
  List<Object?> get props => [code, status, invoiceStatus, total];
}
