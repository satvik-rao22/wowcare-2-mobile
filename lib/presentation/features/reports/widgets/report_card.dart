import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/colors.dart';

class ReportItem {
  const ReportItem({
    required this.name,
    required this.description,
  });

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
                                  color: const Color(0xFF0A1C5D),
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
                        color: Color(0xFFE9EBF5),
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
                                color: Color(0xFF0A1C5D),
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
                                color: Color(0xFF0A1C5D),
                                height: 19 / 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                for (int j = 0;
                                    j < widget.formats.length;
                                    j++) ...[
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
                                              widget.formats[j]),
                                    ),
                                  ),
                                  if (j != widget.formats.length - 1)
                                    const SizedBox(width: 12),
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

  Widget _buildIcon({required Color color, required double size}) {
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

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    if (!isPrimary) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient:
              isEnabled ? AppColors.buildPrimaryGradient() : null,
          color: isEnabled ? null : Colors.grey[300],
        ),
        padding: const EdgeInsets.all(1),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          AppColors.buildPrimaryGradient()
                              .createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child:
                          _buildIcon(color: Colors.white, size: 18),
                    )
                  : _buildIcon(color: Colors.grey[600]!, size: 18),
              const SizedBox(width: 8),
              Text(
                'Generate',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? AppColors.primaryColor
                      : Colors.grey[600],
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
        color: isEnabled ? null : Colors.grey[300],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isEnabled ? Colors.white : Colors.grey[600],
          disabledForegroundColor: Colors.grey[600],
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(
              color: isEnabled ? Colors.white : Colors.grey[600]!,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Generate',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
