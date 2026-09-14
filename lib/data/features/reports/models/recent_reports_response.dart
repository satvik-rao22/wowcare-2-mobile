import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/recent_report_model.dart';

part 'recent_reports_response.g.dart';

/// The envelope around a recent-reports list.
///
/// Four endpoints return this list and the backend's envelope shape has never
/// been confirmed for all of them, so three observed shapes are accepted:
/// `{reports: [...]}`, `{data: [...]}` and `{data: {reports: [...]}}`. None of
/// them matching yields an empty list — a missing envelope is not an error.
///
/// [data] is `Object?` rather than a typed field precisely because it is a
/// list in one shape and a map in another.
@JsonSerializable(createToJson: false)
class RecentReportsResponse {
  const RecentReportsResponse({this.reports, this.data});

  factory RecentReportsResponse.fromJson(Map<String, dynamic> json) =>
      _$RecentReportsResponseFromJson(json);

  final List<dynamic>? reports;
  final Object? data;

  /// The reports this envelope carries, whichever shape it arrived in.
  List<RecentReportModel> toModels() {
    var list = reports;
    final nested = data;
    if (list == null && nested is List) {
      list = nested;
    } else if (list == null && nested is Map) {
      list = nested['reports'] as List?;
    }
    if (list == null) return const [];

    return list
        .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
