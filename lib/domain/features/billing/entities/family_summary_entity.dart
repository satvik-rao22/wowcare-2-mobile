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
    this.studentCount = 0,
    this.studentName,
    this.studentPhotoAssetCode,
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

  /// How many students this family/owner has. The backend only populates
  /// [studentName]/[studentPhotoAssetCode] when this is exactly 1 — a
  /// family with siblings has no single student to name, so those stay null
  /// and [familyName] (e.g. "Koli Family") is the only sensible label.
  final int studentCount;

  /// The student's own name — only populated by the backend for a
  /// single-child family (`studentCount == 1`). A parent with no siblings
  /// should see their child's name here instead of the generic
  /// "<Surname> Family" label, matching the web list.
  final String? studentName;

  /// The student's photo asset code — same single-child-only availability
  /// as [studentName].
  final String? studentPhotoAssetCode;

  /// True when this family has at least one invoice or payment on record.
  /// Web's family-summary list only shows families that have been billed at
  /// least once; mobile was showing every family regardless, so this is used
  /// to filter the list client-side to match.
  bool get hasTransactions => lastInvoiceDate != null || lastPaymentDate != null;

  /// Display label for this row: the student's own name for a single-child
  /// family, the family name otherwise (or as a fallback if the backend
  /// didn't send a student name for some reason).
  String get displayName {
    final student = (studentName ?? '').trim();
    if (studentCount == 1 && student.isNotEmpty) return student;
    if (familyName.trim().isNotEmpty) return familyName;
    return student.isNotEmpty ? student : guardianName;
  }

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
        studentCount,
        studentName,
        studentPhotoAssetCode,
      ];
}
