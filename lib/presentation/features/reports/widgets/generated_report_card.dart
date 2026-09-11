import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart'
    show GeneratedReportItem;
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class GeneratedReportCard extends StatefulWidget {
  const GeneratedReportCard({
    super.key,
    required this.item,
    this.onView,
    this.onDownload,
  });

  final GeneratedReportItem item;
  final VoidCallback? onView;
  final Future<void> Function(String?)? onDownload;

  @override
  State<GeneratedReportCard> createState() => _GeneratedReportCardState();
}

class _GeneratedReportCardState extends State<GeneratedReportCard> {
  /// §2.2 bucket B — expand/collapse and the per-card download spinner are
  /// UI micro-state local to this card.
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDownloading = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isExpanded.dispose();
    _isDownloading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: AppColors.transparentColor,
              child: InkWell(
                onTap: () => _isExpanded.value = !_isExpanded.value,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isExpanded,
                  builder: (context, expanded, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 64,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.fileName,
                                  style: AppTextStyles.reportsFieldValue(
                                    fontSize: isTablet ? 16 : 14,
                                  ).copyWith(height: 19 / 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (expanded) ...[
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.reportsCardDividerColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _DetailRow(
                                label: ReportsStrings.date,
                                value: _formatDate(widget.item.generatedAt),
                              ),
                              const SizedBox(height: AppSizes.xsPlus),
                              _DetailRow(
                                label: ReportsStrings.time,
                                value: _formatTime(widget.item.generatedAt),
                              ),
                              const SizedBox(height: AppSizes.md),
                              if (widget.onDownload != null)
                                ValueListenableBuilder<bool>(
                                  valueListenable: _isDownloading,
                                  builder: (context, downloading, _) => SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: downloading
                                              ? [
                                                  AppColors.reportsMutedColor,
                                                  AppColors
                                                      .reportsDisabledForegroundColor,
                                                ]
                                              : AppColors.primaryGradientColors,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: downloading
                                            ? null
                                            : () async {
                                                _isDownloading.value = true;
                                                try {
                                                  await widget.onDownload?.call(
                                                    widget.item.assetCode,
                                                  );
                                                } finally {
                                                  if (mounted) {
                                                    _isDownloading.value =
                                                        false;
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.transparentColor,
                                          shadowColor:
                                              AppColors.transparentColor,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: downloading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.cardColor),
                                                ),
                                              )
                                            : const Text(
                                                ReportsStrings.download,
                                                style: AppTextStyles
                                                    .reportsDownloadButtonLabel,
                                              ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                CustomButtonLayout(
                                  isForm: false,
                                  cancelButtonLabel: ReportsStrings.view,
                                  onPressedCancel: widget.onView,
                                  confirmButtonLabel: ReportsStrings.download,
                                  onPressedConfirm: () => widget.onDownload
                                      ?.call(widget.item.assetCode),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const _months = [
    ReportsStrings.jan,
    ReportsStrings.feb,
    ReportsStrings.mar,
    ReportsStrings.apr,
    ReportsStrings.may,
    ReportsStrings.jun,
    ReportsStrings.jul,
    ReportsStrings.aug,
    ReportsStrings.sep,
    ReportsStrings.oct,
    ReportsStrings.nov,
    ReportsStrings.dec,
  ];

  DateTime _toSchoolTime(DateTime dt) =>
      SchoolZoneDateTime.dateTimeFromInstantInSchool(
        dt,
        SchoolTimezoneResolver.lastKnownTimeZone,
      );

  String _formatDate(DateTime dt) {
    final schoolDt = _toSchoolTime(dt);
    final day = schoolDt.day.toString().padLeft(2, '0');
    return '${_months[schoolDt.month - 1]} $day, ${schoolDt.year}';
  }

  String _formatTime(DateTime dt) {
    final schoolDt = _toSchoolTime(dt);
    final hour12 = ((schoolDt.hour + 11) % 12) + 1;
    final minute = schoolDt.minute.toString().padLeft(2, '0');
    final ampm = schoolDt.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.reportsFieldLabel(
            fontSize: 13,
          ).copyWith(height: 16 / 13),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.reportsFieldValue(
              fontSize: 14,
            ).copyWith(height: 19 / 14),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
