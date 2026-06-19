import 'package:equatable/equatable.dart';

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
    this.notes,
    this.currency,
  });

  final String organizationCode;
  final String schoolCode;
  final String studentCode;
  final DateTime issueDate;
  final DateTime dueDate;
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
        items,
        notes,
        currency,
      ];
}

class UpdateInvoiceItemParams extends Equatable {
  const UpdateInvoiceItemParams({
    required this.description,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  final String description;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;

  @override
  List<Object?> get props => [description, quantity, unitPrice, totalPrice];
}

/// Params for `PATCH /api/v1/invoices/{invoiceCode}` (partial update).
class UpdateInvoiceParams extends Equatable {
  const UpdateInvoiceParams({
    this.code,
    this.studentCode,
    this.issueDate,
    this.dueDate,
    this.status,
    this.invoiceStatus,
    this.amount,
    this.total,
    this.paidAmount,
    this.subjectOwnerType,
    this.subjectOwnerCode,
    this.subscriptionCode,
    this.items,
  });

  final String? code;
  final String? studentCode;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? status;
  final String? invoiceStatus;
  final double? amount;
  final double? total;
  final double? paidAmount;
  final String? subjectOwnerType;
  final String? subjectOwnerCode;
  final String? subscriptionCode;
  final List<UpdateInvoiceItemParams>? items;

  @override
  List<Object?> get props => [
        code,
        studentCode,
        issueDate,
        dueDate,
        status,
        invoiceStatus,
        amount,
        total,
        paidAmount,
        subjectOwnerType,
        subjectOwnerCode,
        subscriptionCode,
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
  });

  final String schoolCode;
  final double amount;
  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? reason;
  final String? description;

  @override
  List<Object?> get props => [
        schoolCode,
        amount,
        ownerType,
        ownerCode,
        studentCode,
        reason,
        description,
      ];
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
