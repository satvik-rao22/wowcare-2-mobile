import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recent_report_model.g.dart';

/// One entry in the recent-reports list, as the backend sends it.
///
/// Serialisation is generated (§8). Two wire quirks are preserved as
/// annotations rather than inline expressions:
///   * `includeIfNull: false` — `toJson` omits `assetCode`/`fileName` entirely
///     rather than emitting explicit nulls;
///   * `@JsonKey(defaultValue: '')` — a missing or null required field reads
///     back as the empty string, which is what the list rendering already
///     expects. Changing that to a throw would drop rows the UI shows today.
@JsonSerializable(includeIfNull: false)
class RecentReportModel extends Equatable {
  const RecentReportModel({
    required this.reportId,
    required this.reportType,
    required this.generatedAt,
    this.assetCode,
    this.fileName,
  });

  factory RecentReportModel.fromJson(Map<String, dynamic> json) =>
      _$RecentReportModelFromJson(json);

  @JsonKey(defaultValue: '')
  final String reportId;
  @JsonKey(defaultValue: '')
  final String reportType;
  @JsonKey(defaultValue: '')
  final String generatedAt;
  final String? assetCode;
  final String? fileName;

  Map<String, dynamic> toJson() => _$RecentReportModelToJson(this);

  @override
  List<Object?> get props => [
    reportId,
    reportType,
    generatedAt,
    assetCode,
    fileName,
  ];
}
