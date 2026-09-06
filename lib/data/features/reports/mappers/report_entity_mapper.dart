import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/data/features/reports/models/recent_report_model.dart';
import 'package:wowcare/data/features/reports/models/report_response_model.dart';
import 'package:wowcare/domain/features/reports/entities/report_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';

/// Model → entity conversion for the reports feature.
///
/// Kept out of the models themselves so the domain entities stay free of any
/// knowledge of the wire format (§8), matching `student/mappers` and
/// `staff/mappers`.
class ReportEntityMapper {
  const ReportEntityMapper._();

  /// Throws [FormatException] for an unrecognized `reportType` instead of
  /// silently mislabeling the report as Student Daily Attendance.
  static ReportEntity toEntity(ReportResponseModel model) {
    return ReportEntity(
      reportId: model.reportId,
      reportType: _reportType(model.reportType),
      generatedAt: _generatedAt(model.generatedAt),
      assetCode: model.assetCode,
      fileName: model.fileName,
    );
  }

  /// Throws [FormatException] for an unrecognized `reportType`. The caller
  /// (`ReportsRepositoryImpl.getRecentReports`) catches this per-item so one
  /// unparseable entry is skipped and logged instead of either crashing the
  /// whole list or silently mislabeling the report.
  static ReportMetadataEntity toMetadataEntity(RecentReportModel model) {
    return ReportMetadataEntity(
      reportId: model.reportId,
      reportType: _reportType(model.reportType),
      generatedAt: _generatedAt(model.generatedAt),
      assetCode: model.assetCode,
      fileName: model.fileName,
    );
  }

  static ReportType _reportType(String backendValue) {
    return ReportType.values.firstWhere(
      (e) => e.backendValue == backendValue,
      orElse: () => throw FormatException(
        'Unknown reportType in response: $backendValue',
      ),
    );
  }

  /// An unparseable timestamp falls back to now rather than dropping the row —
  /// the report exists either way, only its age is uncertain.
  static DateTime _generatedAt(String raw) =>
      DateTime.tryParse(raw) ?? AppTime.nowUtc();
}

/// Call-site sugar so `model.toEntity()` keeps reading the way it did.
extension ReportResponseModelMapper on ReportResponseModel {
  ReportEntity toEntity() => ReportEntityMapper.toEntity(this);
}

extension RecentReportModelMapper on RecentReportModel {
  ReportMetadataEntity toEntity() => ReportEntityMapper.toMetadataEntity(this);
}
