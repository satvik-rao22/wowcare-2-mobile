import 'package:equatable/equatable.dart';

/// A per-family billing summary row from `GET /api/v1/invoices/family-summary`.
class FamilySummaryEntity extends Equatable {
  const FamilySummaryEntity({
    required this.ownerType,
    required this.ownerCode,
    required this.studentCodes,
    required this.familyName,
    required this.guardianName,
    required this.lastInvoiceAmount,
    required this.lastInvoiceDate,
    required this.lastInvoiceDueDate,
    required this.lastInvoiceStatus,
    required this.lastPaymentAmount,
    required this.lastPaymentDate,
    required this.lastPaymentMethod,
    required this.openBalance,
  });

  final String ownerType;
  final String ownerCode;
  final List<String> studentCodes;
  final String familyName;
  final String guardianName;
  final double lastInvoiceAmount;
  final DateTime? lastInvoiceDate;
  final DateTime? lastInvoiceDueDate;
  final String lastInvoiceStatus;
  final double lastPaymentAmount;
  final DateTime? lastPaymentDate;
  final String lastPaymentMethod;
  final double openBalance;

  /// True when this family has at least one invoice or payment on record.
  /// Web's family-summary list only shows families that have been billed at
  /// least once; mobile was showing every family regardless, so this is used
  /// to filter the list client-side to match.
  bool get hasTransactions => lastInvoiceDate != null || lastPaymentDate != null;

  @override
  List<Object?> get props => [
        ownerType,
        ownerCode,
        studentCodes,
        familyName,
        guardianName,
        lastInvoiceAmount,
        lastInvoiceDate,
        lastInvoiceDueDate,
        lastInvoiceStatus,
        lastPaymentAmount,
        lastPaymentDate,
        lastPaymentMethod,
        openBalance,
      ];
}
