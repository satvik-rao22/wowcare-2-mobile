import 'package:equatable/equatable.dart';
import '../entities/report_type.dart';

/// Base interface for all report parameter classes.
///
/// Each concrete implementation handles mapping user selections to the
/// backend API payload format specific to that report type.
abstract class ReportParams extends Equatable {
  /// The report type this params instance represents.
  ReportType get reportType;

  /// Start date for the report period.
  DateTime get startDate;

  /// Export format for the report (PDF or XLSX).
  String get format;

  /// Convert this parameter instance to API request body format.
  ///
  /// Returns a Map<String, dynamic> with keys/values matching the
  /// backend API's expected JSON payload.
  Map<String, dynamic> toRequestBody();

  /// Build a unique cache identifier from these parameters.
  ///
  /// Used by CacheManager to determine cache validity and key generation.
  /// Different parameter combinations should produce different identifiers.
  String toCacheIdentifier();
}
