import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

class ReportItem {
  const ReportItem({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

class ReportCard extends StatefulWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onView,
    this.onGenerate,
  });

  final ReportItem report;
  final VoidCallback? onView;
  final VoidCallback? onGenerate;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _isExpanded = false;

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
              border: Border.all(
                color: AppColors.cardBorderColor,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    setState(() => _isExpanded = !_isExpanded),
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
                                widget.report.name,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff573353),
                                height: 16 / 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.report.description,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff573353),
                                height: 19 / 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButtonLayout(
                              isForm: false,
                              cancelButtonLabel: 'View',
                              onPressedCancel: widget.onView,
                              confirmButtonLabel: 'Generate',
                              onPressedConfirm: widget.onGenerate,
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
}
