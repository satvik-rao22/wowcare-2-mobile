import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';


class ButtonStyles {
  static ButtonStyle elevatedButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double borderRadius = 8.0,
    FontWeight fontWeight = FontWeight.w500,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.themeColor,
      foregroundColor: foregroundColor ?? AppColors.cardColor,
      textStyle: TextStyle(fontWeight: fontWeight),
      padding: padding,
      shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
    );
  }
}