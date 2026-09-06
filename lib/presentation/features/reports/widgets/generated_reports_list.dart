import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_report_card.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

enum GeneratedReportFileType { xlsx, pdf }

class GeneratedReportItem {
  const GeneratedReportItem({
    required this.fileName,
    required this.generatedAt,
    required this.type,
    this.assetCode,
  });

  final String fileName;
  final DateTime generatedAt;
  final GeneratedReportFileType type;
  final String? assetCode;
}

class GeneratedReportsList extends StatelessWidget {
  const GeneratedReportsList({
    super.key,
    required this.items,
    this.onView,
    this.onDownload,
  });

  final List<GeneratedReportItem> items;
  final ValueChanged<GeneratedReportItem>? onView;
  final Future<void> Function(String?)? onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.xxs,
            0,
            AppSizes.xxs,
            AppSizes.sm,
          ),
          child: Text(
            ReportsStrings.recentlyGeneratedReports,
            style: AppTextStyles.reportsHeading(
              fontSize: 16,
            ).copyWith(height: 20 / 16),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
            child: Center(
              child: Text(
                ReportsStrings.noReportsGeneratedYetAlt,
                style: AppTextStyles.reportsFieldValue(fontSize: 14).copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          for (int i = 0; i < items.length; i++) ...[
            GeneratedReportCard(
              item: items[i],
              onView: onView == null ? null : () => onView!(items[i]),
              onDownload: onDownload == null
                  ? null
                  : (assetCode) => onDownload!(assetCode),
            ),
            if (i != items.length - 1) const SizedBox(height: AppSizes.xsPlus),
          ],
      ],
    );
  }
}
