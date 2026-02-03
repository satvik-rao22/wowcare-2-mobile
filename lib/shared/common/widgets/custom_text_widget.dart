import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../app/theme/colors.dart';

class CustomTextWidget extends StatelessWidget {
  const CustomTextWidget({super.key, this.text, this.textStyle, this.fontSize, this.fontFamily, this.fontWeight, this.fontColor, this.letterSpacing, this.maxLines, this.overflow, this.softWrap, this.applyLetterSpacing = true, this.height, this.unlimitedLines = false});
  final String? text;
  final TextStyle? textStyle;
  final double? fontSize;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final Color? fontColor;
  final double? letterSpacing;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final bool applyLetterSpacing;
  final double? height;
  final bool unlimitedLines;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final effectiveLetterSpacing = applyLetterSpacing
        ? letterSpacing ?? -0.03 * (fontSize ?? responsive.titleFontSize)
        : null;
    return Text(
      text ?? '',
      style: textStyle ?? TextStyle(
        fontFamily: fontFamily ?? 'Manrope',
        fontSize: fontSize ?? responsive.titleFontSize,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: fontColor ?? AppColors.primaryColor,
        letterSpacing: effectiveLetterSpacing,
        height: height ?? null
      ),
      maxLines: unlimitedLines ? null : maxLines ?? 2,
      overflow: overflow ?? TextOverflow.ellipsis,
      softWrap: softWrap ?? true,
    );
  }
}
