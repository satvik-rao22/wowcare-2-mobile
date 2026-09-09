import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class ReportItem {
  const ReportItem({
    required this.type,
    required this.name,
    required this.description,
  });

  /// Stable identity of this report, used for navigation and for the request
  /// payload. Switch on this — never on [name].
  ///
  /// [name] and [description] are purely presentational: they are display
  /// copy, they are localisable, and two different reports may legitimately
  /// share a [name] (the Student and Staff tabs both offer an "Absent
  /// Report"). Keying control flow off display text made renaming a report
  /// silently break the form it opens.
  final ReportType type;

  final String name;
  final String description;
}

enum ReportExportFormat { pdf, excel }

class ReportCard extends StatefulWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onGenerate,
    this.formats = const <ReportExportFormat>[ReportExportFormat.excel],
  });

  final ReportItem report;

  /// Called when the user taps a Generate button. The chosen
  /// [ReportExportFormat] is passed so the caller can drive the export type.
  final ValueChanged<ReportExportFormat>? onGenerate;

  /// Which export formats to render as Generate buttons.
  /// Defaults to Excel only — Compliance reports pass [pdf, excel].
  final List<ReportExportFormat> formats;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  /// §2.2 bucket B — expand/collapse is UI micro-state.
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isExpanded.dispose();
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
                                  widget.report.name,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ReportsStrings.description,
                                style: AppTextStyles.reportsFieldLabel(
                                  fontSize: 13,
                                ).copyWith(height: 16 / 13),
                              ),
                              const SizedBox(height: AppSizes.xxs),
                              Text(
                                widget.report.description,
                                style: AppTextStyles.reportsFieldValue(
                                  fontSize: 14,
                                ).copyWith(height: 19 / 14),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Row(
                                children: [
                                  for (
                                    int j = 0;
                                    j < widget.formats.length;
                                    j++
                                  ) ...[
                                    Expanded(
                                      child: _GenerateButton(
                                        format: widget.formats[j],
                                        // When there are multiple buttons, the
                                        // last one is solid (primary) and the
                                        // rest are outlined (secondary).
                                        isPrimary:
                                            j == widget.formats.length - 1,
                                        onPressed: widget.onGenerate == null
                                            ? null
                                            : () => widget.onGenerate!(
                                                widget.formats[j],
                                              ),
                                      ),
                                    ),
                                    if (j != widget.formats.length - 1)
                                      const SizedBox(width: AppSizes.sm),
                                  ],
                                ],
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
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.format,
    required this.onPressed,
    this.isPrimary = true,
  });

  final ReportExportFormat format;
  final VoidCallback? onPressed;

  /// When true, button uses solid gradient fill with white text/icon.
  /// When false, button uses a gradient border + white fill with primary
  /// color text/icon (matches [CustomCancelButton]).
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    if (!isPrimary) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isEnabled ? AppColors.buildPrimaryGradient() : null,
          color: isEnabled ? null : AppColors.reportsDisabledSurfaceColor,
        ),
        padding: const EdgeInsets.all(1),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              isEnabled
                  ? ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.buildPrimaryGradient().createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: _ReportFormatIcon(
                        format: format,
                        color: AppColors.cardColor,
                        size: 18,
                      ),
                    )
                  : _ReportFormatIcon(
                      format: format,
                      color: AppColors.reportsDisabledForegroundColor,
                      size: 18,
                    ),
              const SizedBox(width: AppSizes.xs),
              Text(
                ReportsStrings.generateAction,
                style: AppTextStyles.reportsHeading(fontSize: 15).copyWith(
                  color: isEnabled
                      ? AppColors.primaryColor
                      : AppColors.reportsDisabledForegroundColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isEnabled ? AppColors.buildPrimaryGradient() : null,
        color: isEnabled ? null : AppColors.reportsDisabledSurfaceColor,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.transparentColor,
          foregroundColor: isEnabled
              ? AppColors.cardColor
              : AppColors.reportsDisabledForegroundColor,
          disabledForegroundColor: AppColors.reportsDisabledForegroundColor,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReportFormatIcon(
              format: format,
              color: isEnabled
                  ? AppColors.cardColor
                  : AppColors.reportsDisabledForegroundColor,
              size: 18,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              ReportsStrings.generateAction,
              style: AppTextStyles.reportsHeading(fontSize: 15).copyWith(
                color: isEnabled
                    ? AppColors.cardColor
                    : AppColors.reportsDisabledForegroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PDF / Excel glyph for a generate button.
///
/// Was `Widget _buildIcon({...})` on the State (§6.4).
class _ReportFormatIcon extends StatelessWidget {
  const _ReportFormatIcon({
    required this.format,
    required this.color,
    required this.size,
  });

  final ReportExportFormat format;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (format == ReportExportFormat.pdf) {
      return Icon(Icons.picture_as_pdf_rounded, size: size, color: color);
    }
    return SvgPicture.asset(
      'assets/icons/excel_icon.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
