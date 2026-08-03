import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/presentation/features/billing/utils/billing_school_time.dart';

class TransactionItem {
  TransactionItem({
    required this.id,
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
  });

  final int id;

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

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    final List<dynamic> students =
        (map['students'] as List<dynamic>? ?? <dynamic>[]);
    final Map<String, dynamic>? firstStudent =
        students.isNotEmpty ? students.first as Map<String, dynamic> : null;

    return TransactionItem(
      id: map['id'] as int,
      transactionType: (map['transactionType'] ?? '').toString(),
      date: DateTime.tryParse((map['date'] ?? '').toString()) ??
          billingSchoolNow(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: (map['processStatus'] ?? map['status'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      studentName: (firstStudent?['fullName'] ?? 'Unknown').toString(),
      classroom: (firstStudent?['roomName'] ?? '').toString(),
      studentId: firstStudent?['id'] as int?,
      studentPhotoUuid: firstStudent?['photoUuid'] as String?,
      refTable: map['refTable'] as String?,
      refTableId: map['refTableId'] as int?,
      balance: (map['balance'] as num?)?.toDouble(),
      note: map['note'] as String?,
      endDate: map['endDate'] as String?,
      paymentMode: map['paymentMode'] as String?,
      studentOpenBalance:
          (firstStudent?['balance'] as num?)?.toDouble(),
    );
  }

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
    );
  }

  String get displayDescription => description.isEmpty ? '-' : description;
}

