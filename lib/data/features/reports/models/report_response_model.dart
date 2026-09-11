import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_generation_envelope.dart';

part 'report_response_model.g.dart';

/// A generated report, as the backend describes it.
///
/// Field mapping is generated (§8); `includeIfNull: false` preserves the wire
/// contract that `toJson` omits absent optional keys instead of sending
/// explicit nulls. What generation cannot express — unwrapping the response
/// envelope and rejecting a report that could never be downloaded — stays in
/// [ReportResponseModel.fromJson], which is transport logic rather than field
/// serialisation.
@JsonSerializable(includeIfNull: false)
class ReportResponseModel extends Equatable {
  const ReportResponseModel({
    required this.reportId,
    required this.reportType,
    required this.generatedAt,
    this.assetCode,
    this.fileName,
    this.message,
  });

  /// Parses the wrapped response format:
  /// `{success, message, data: {reportId, ...}, timestamp, error}`.
  ///
  /// Throws [FormatException] when the backend reports failure
  /// (`success: false`) or when a required field is missing, instead of
  /// silently defaulting to `''` — a missing `reportId`/`assetCode` means
  /// the report can never be downloaded, so surfacing that as a generation
  /// failure immediately is more useful than a UI that says "generated"
  /// for a report nobody can open.
  factory ReportResponseModel.fromJson(Map<String, dynamic> json) {
    final envelope = ReportGenerationEnvelope.fromJson(json);
    envelope.throwIfFailed();

    // No `data` object means the endpoint returned the report unwrapped.
    final reportData = envelope.data ?? json;

    // Cast all three before validating any: a wrong *type* is reported as a
    // TypeError even when an earlier field is also missing, which is what
    // the hand-written parser did.
    final reportId = reportData['reportId'] as String?;
    final reportType = reportData['reportType'] as String?;
    final generatedAt = reportData['generatedAt'] as String?;
    _requireField(reportId, 'reportId', reportData);
    _requireField(reportType, 'reportType', reportData);
    _requireField(generatedAt, 'generatedAt', reportData);

    // `message` belongs to the envelope, not to the report — a `data` object
    // carrying its own `message` must not win over the outer one.
    return _$ReportResponseModelFromJson({
      ...reportData,
      'message': envelope.message,
    });
  }

  static void _requireField(
    String? value,
    String name,
    Map<String, dynamic> reportData,
  ) {
    if (value == null || value.isEmpty) {
      throw FormatException(
        'Report response missing required field "$name": $reportData',
      );
    }
  }

  final String reportId;
  final String reportType;
  final String generatedAt;
  final String? assetCode;
  final String? fileName;
  final String? message;

  Map<String, dynamic> toJson() => _$ReportResponseModelToJson(this);

  @override
  List<Object?> get props => [
    reportId,
    reportType,
    generatedAt,
    assetCode,
    fileName,
    message,
  ];
}
