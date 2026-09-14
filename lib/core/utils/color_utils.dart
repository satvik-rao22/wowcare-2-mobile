import 'package:flutter/material.dart';

class ColorUtils {
  static Color getColorFromName(String roomName) {
    final String lowerName = roomName.toLowerCase();

    if (lowerName.isEmpty) return Colors.white;

    if (lowerName.contains('blue')) return Colors.blue;
    if (lowerName.contains('green')) return Colors.green;
    if (lowerName.contains('purple')) return Colors.purple;
    if (lowerName.contains('yellow')) return Colors.amber;
    if (lowerName.contains('orange')) return Colors.orange;
    if (lowerName.contains('pink')) return Colors.pink;
    if (lowerName.contains('red')) return Colors.red;
    if (lowerName.contains('white')) return Colors.white;
    if (lowerName.contains('black')) return Colors.black;
    if (lowerName.contains('brown')) return Colors.brown;
    if (lowerName.contains('grey') || lowerName.contains('gray')) {
      return Colors.grey;
    }

    final int hash = roomName.hashCode;
    final List<Color> fallbackColors = [
      Colors.blueGrey,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.indigo,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.teal,
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
