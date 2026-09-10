import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class ColorUtils {
  static Color getColorFromName(String roomName) {
    final String lowerName = roomName.toLowerCase();

    if (lowerName.isEmpty) return AppColors.whiteColor;

    if (lowerName.contains('blue')) return MaterialHues.blue;
    if (lowerName.contains('green')) return MaterialHues.green;
    if (lowerName.contains('purple')) return MaterialHues.purple;
    if (lowerName.contains('yellow')) return MaterialHues.amber;
    if (lowerName.contains('orange')) return MaterialHues.orange;
    if (lowerName.contains('pink')) return MaterialHues.pink;
    if (lowerName.contains('red')) return MaterialHues.red;
    if (lowerName.contains('white')) return AppColors.whiteColor;
    if (lowerName.contains('black')) return AppColors.blackColor;
    if (lowerName.contains('brown')) return MaterialHues.brown;
    if (lowerName.contains('grey') || lowerName.contains('gray')) {
      return MaterialHues.grey500;
    }

    final int hash = roomName.hashCode;
    final List<Color> fallbackColors = [
      MaterialHues.blueGrey,
      MaterialHues.brown,
      MaterialHues.cyan,
      MaterialHues.deepOrange,
      MaterialHues.deepPurple,
      MaterialHues.indigo,
      MaterialHues.lightBlue,
      MaterialHues.lightGreen,
      MaterialHues.teal,
    ];

    return fallbackColors[hash.abs() % fallbackColors.length];
  }

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
