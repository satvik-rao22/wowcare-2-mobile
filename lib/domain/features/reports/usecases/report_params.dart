import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';

/// Base interface for all report parameter classes.
///
/// Each concrete implementation handles mapping user selections to the
/// backend API payload format specific to that report type.
abstract class ReportParams extends Equatable {
  /// The report type this params instance represents.
  ReportType get reportType;

  /// Start date for the report period (optional for reports that don't use date ranges).
  DateTime? get startDate;

  /// Export format for the report (PDF or XLSX).
  String get format;

  /// The wire body is *not* built here. `ReportRequestPayload.fromParams`
  /// in the data layer turns these typed values into JSON, so no map ever
  /// crosses the domain boundary (§8).

  /// Build a unique cache identifier from these parameters.
  ///
  /// Used by CacheManager to determine cache validity and key generation.
  /// Different parameter combinations should produce different identifiers.
  String toCacheIdentifier();
}
