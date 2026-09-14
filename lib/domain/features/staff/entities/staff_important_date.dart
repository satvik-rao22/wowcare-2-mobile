import 'package:equatable/equatable.dart';

/// Typed model for a staff important-date entry, used in BOTH directions:
///
///  * as a REQUEST entry for `PATCH /api/v1/staff-dates/{staffCode}`
///    ([toPayload] reproduces the Map the views used to build), and
///  * as a RESPONSE / cached entry read back from `GET .../staff-dates`
///    ([StaffImportantDate.fromMap] mirrors the parse the datasource/cache did).
///
/// Replaces the raw `List<Map<String, String>>` that flowed through the
/// important-dates read/update path. [completedDate] and [status] are nullable
/// and conditionally omitted from [toPayload] exactly as the old Map literals
/// were, so the JSON on the wire — and the cached shape — stay byte-identical.
class StaffImportantDate extends Equatable {
  const StaffImportantDate({
    required this.importantDateType,
    required this.dueDate,
    this.completedDate,
    this.status,
  });

  final String importantDateType;
  final String dueDate; // ISO "yyyy-MM-dd"
  final String? completedDate; // ISO "yyyy-MM-dd"; omitted when null
  final String? status; // e.g. DUE / SCHEDULED / COMPLETED; omitted when empty

  /// Mirrors the tolerant parse the datasource/cache used: missing type/dueDate
  /// coerce to '', while completedDate/status stay null when absent.
  factory StaffImportantDate.fromMap(Map<String, dynamic> json) {
    return StaffImportantDate(
      importantDateType: (json['importantDateType'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      completedDate: json['completedDate']?.toString(),
      status: json['status']?.toString(),
    );
  }

  /// Reproduces the exact Map the old code built, key-for-key: completedDate is
  /// included whenever non-null; status is included only when non-null AND
  /// non-empty (matching the prior `if (status != null && status.isNotEmpty)`).
  Map<String, dynamic> toPayload() => {
    'importantDateType': importantDateType,
    'dueDate': dueDate,
    if (completedDate != null) 'completedDate': completedDate,
    if (status != null && status!.isNotEmpty) 'status': status,
  };

  @override
  List<Object?> get props => [importantDateType, dueDate, completedDate, status];
}
