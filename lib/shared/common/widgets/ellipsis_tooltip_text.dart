import 'package:flutter/material.dart';

/// Text with ellipsis; when content exceeds the laid-out width, a [Tooltip]
/// shows the full [text] (tap by default, or long press if [preferLongPress]).
class EllipsisTooltipText extends StatelessWidget {
  const EllipsisTooltipText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,

    /// Use when an ancestor handles tap (e.g. remove student) so tap still passes through.
    this.preferLongPress = false,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;
  final bool preferLongPress;

  static bool isTruncated({
    required String text,
    required TextStyle style,
    required int maxLines,
    required double maxWidth,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (maxWidth <= 0) return false;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    )..layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final truncated = isTruncated(
          text: text,
          style: style,
          maxLines: maxLines,
          maxWidth: constraints.maxWidth,
          textAlign: textAlign,
        );
        final textWidget = Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style,
          textAlign: textAlign,
        );
        if (!truncated) return textWidget;

        return Tooltip(
          message: text,
          triggerMode: preferLongPress
              ? TooltipTriggerMode.longPress
              : TooltipTriggerMode.tap,
          waitDuration: const Duration(milliseconds: 120),
          showDuration: const Duration(seconds: 6),
          child: textWidget,
        );
      },
    );
  }
}
