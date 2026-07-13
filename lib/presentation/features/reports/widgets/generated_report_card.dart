import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart'
    show GeneratedReportItem;
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

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
  bool _isExpanded = false;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Column(
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
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xff573353),
                                  height: 19 / 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isExpanded) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFE9ECEF),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DetailRow(
                              label: 'Date',
                              value: _formatDate(widget.item.generatedAt),
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: 'Time',
                              value: _formatTime(widget.item.generatedAt),
                            ),
                            const SizedBox(height: 16),
                            if (widget.onDownload != null)
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isDownloading
                                          ? [
                                              Colors.grey.shade400,
                                              Colors.grey.shade600,
                                            ]
                                          : AppColors.primaryGradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isDownloading
                                        ? null
                                        : () async {
                                            setState(
                                              () => _isDownloading = true,
                                            );
                                            try {
                                              await widget.onDownload?.call(
                                                widget.item.assetCode,
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => _isDownloading = false,
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: _isDownloading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Download',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              )
                            else
                              CustomButtonLayout(
                                isForm: false,
                                cancelButtonLabel: 'View',
                                onPressedCancel: widget.onView,
                                confirmButtonLabel: 'Download',
                                onPressedConfirm: () => widget.onDownload?.call(
                                  widget.item.assetCode,
                                ),
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
        );
      },
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
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
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff573353),
            height: 16 / 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff573353),
              height: 19 / 14,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
