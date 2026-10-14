import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/policies/invoice_actions.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

class TransactionItem {
  TransactionItem({
    required this.id,
    this.transactionId,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.status,
    required this.description,
    required this.studentName,
    required this.classroom,
    this.paidAmount = 0,
    this.refundedAmount = 0,
    this.studentNames,
    this.familyCode,
    this.invoiceCode,
    this.studentId,
    this.studentCode,
    this.studentPhotoUuid,
    this.refTable,
    this.refTableId,
    this.balance,
    this.note,
    this.endDate,
    this.paymentMode,
    this.studentOpenBalance,
    this.gatewayPayment = false,
    this.fullyReduced = false,
  });

  final int id;

  /// Stable server transaction identity (the API row's `id`), used to
  /// de-duplicate rows across paginated load-more responses. Null when the
  /// row carries no server id.
  final String? transactionId;

  /// Backend invoice code (the real identifier). `id` is only a display/list
  /// key — invoices are addressed by [invoiceCode] in API calls.
  final String? invoiceCode;
  final String transactionType;
  final DateTime date;
  final double amount;

  /// Amount already paid against this invoice. A non-zero value hides the Cancel
  /// action, since a paid (or part-paid) invoice can no longer be cancelled.
  final double paidAmount;

  /// Amount already refunded against this invoice. When it equals [amount] the
  /// invoice is fully refunded, so the Issue Refund action is hidden.
  final double refundedAmount;

  /// Remaining amount that can still be refunded (never negative).
  double get maxRefundable {
    final double remaining = amount - refundedAmount;
    return remaining > 0 ? remaining : 0;
  }

  final String status;
  final String description;
  final String studentName;

  /// All family student names for family-level transactions (Credit / Refund /
  /// Payment), shown in the expanded "Student Name" row. Null for single-student
  /// rows (invoices), which fall back to [studentName].
  final String? studentNames;

  /// Owning family code — used to open the family Billing profile from a row.
  final String? familyCode;
  final String classroom;
  final int? studentId;

  /// Stable backend student code — used to look up the student's current
  /// classroom for display (invoices carry no room field of their own).
  final String? studentCode;
  final String? studentPhotoUuid;
  final String? refTable;
  final int? refTableId;
  final double? balance;
  final String? note;
  final String? endDate;
  final String? paymentMode;
  final double? studentOpenBalance;

  /// Whether this transaction was processed through the payment gateway
  /// (an "Online" card/ACH charge) rather than manually recorded (Cash,
  /// Cheque, Other) — drives whether "Online" is offered when refunding it.
  final bool gatewayPayment;

  /// Invoice rows: taken to zero by a discount/subsidy with nothing paid — shows
  /// as Paid, yet is still editable and cancellable (decided by the server).
  final bool fullyReduced;

  /// Whether this settled invoice keeps Edit and Cancel (see
  /// [isChangeableZeroInvoice]). An invoice a family paid stays locked.
  bool get isChangeableZero => isChangeableZeroInvoice(status, fullyReduced);

  /// Maps an invoice row from the list API onto the card model. [id] is the
  /// invoice's absolute position in the loaded list (a stable display key);
  /// the real identifier travels in [invoiceCode].
  factory TransactionItem.fromInvoice(
    InvoiceListItemEntity invoice, {
    required int id,
  }) {
    final firstItemDesc =
        invoice.items.isNotEmpty ? invoice.items.first.description : '';
    final ownerLabel = invoice.studentCode.isNotEmpty
        ? invoice.studentCode
        : invoice.subjectOwnerCode;
    final status =
        invoice.invoiceStatus.isNotEmpty ? invoice.invoiceStatus : invoice.status;

    return TransactionItem(
      id: id,
      invoiceCode: invoice.code,
      transactionType: 'Invoice',
      date: invoice.issueDate ?? invoice.createdDate ?? billingSchoolNow(),
      amount: invoice.total,
      status: status,
      description:
          firstItemDesc.isNotEmpty ? firstItemDesc : 'Invoice ${invoice.code}',
      studentName: ownerLabel.isNotEmpty ? ownerLabel : 'Unknown',
      classroom: '',
      studentCode: invoice.studentCode.isNotEmpty ? invoice.studentCode : null,
      refTable: 'Invoice',
      balance: invoice.balance,
      endDate: invoice.dueDate?.toIso8601String(),
      studentOpenBalance: invoice.balance,
      fullyReduced: invoice.fullyReduced,
    );
  }

  String get displayDescription => description.isEmpty ? '-' : description;
}

