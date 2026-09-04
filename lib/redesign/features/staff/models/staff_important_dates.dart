import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// The five dates a center keeps on a staff record (6c Dates).
///
/// Mirrors what `important_dates_cubit.dart` reads and writes through
/// `/api/v1/staff-dates`, which returns them as label and value pairs. They
/// are named fields here so a screen cannot mislabel one.
@immutable
class StaffImportantDates extends Equatable {
  const StaffImportantDates({
    this.hireDate,
    this.cdaExamDate,
    this.backgroundCheckDate,
    this.firstAidExpiry,
    this.physicalCheckupDate,
  });

  final DateTime? hireDate;
  final DateTime? cdaExamDate;
  final DateTime? backgroundCheckDate;

  /// First aid / CPR expiration. The one date that can lapse.
  final DateTime? firstAidExpiry;

  final DateTime? physicalCheckupDate;

  bool isFirstAidExpired(DateTime today) =>
      firstAidExpiry != null && firstAidExpiry!.isBefore(today);

  @override
  List<Object?> get props => [
    hireDate,
    cdaExamDate,
    backgroundCheckDate,
    firstAidExpiry,
    physicalCheckupDate,
  ];
}
