import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/core/util/date_utils.dart';

/// Demo statement data model for UI-only display
class DemoStatement {
  final String id;
  final String statementType;
  final DateTime statementDate;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final String studentName;
  final String? photoUuid;

  const DemoStatement({
    required this.id,
    required this.statementType,
    required this.statementDate,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.studentName,
    this.photoUuid,
  });
}

/// Statement card widget matching legacy statement card structure
class ParentStatementCard extends StatefulWidget {
  final DemoStatement statement;

  const ParentStatementCard({
    super.key,
    required this.statement,
  });

  @override
  State<ParentStatementCard> createState() => _ParentStatementCardState();
}

class _ParentStatementCardState extends State<ParentStatementCard> {
  bool _isViewing = false;
  bool _isDownloading = false;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateUtilsNew.formatToReadableDate(date);
  }

  Future<void> _viewPdfInApp() async {
    if (_isViewing) return;

    setState(() => _isViewing = true);

    try {
      // TODO: Implement PDF viewing
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('View PDF (placeholder)'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isViewing = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // TODO: Implement PDF download
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download PDF (placeholder)'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.classroomNotesTabColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppText.value(
                      'Statement',
                      style: AppTextStyles.value.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppText.value(
                    'Type: ${widget.statement.statementType}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText.value(
                    'Generated on: ${_formatDate(widget.statement.statementDate)}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText.value(
                    'Period: ${_formatDate(widget.statement.periodStartDate)} – ${_formatDate(widget.statement.periodEndDate)}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Divider(
            color: AppColors.dividerColor,
            thickness: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppText.label(
                'Student name',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              AppText.value(
                widget.statement.studentName,
                style: AppTextStyles.value.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppText.label(
                'Statement type',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              AppText.value(
                widget.statement.statementType,
                style: AppTextStyles.value.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppText.label(
                'Statement Period',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              AppText.value(
                '${_formatDate(widget.statement.periodStartDate)} – ${_formatDate(widget.statement.periodEndDate)}',
                style: AppTextStyles.value.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isViewing ? null : _viewPdfInApp,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.themeColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isViewing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.themeColor,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText.value(
                          'View',
                          style: AppTextStyles.value.copyWith(
                            color: AppColors.themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : _downloadPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText.value(
                          'Download',
                          style: AppTextStyles.value.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

