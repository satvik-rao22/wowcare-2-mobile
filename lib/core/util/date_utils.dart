import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart'; // backend provider not available

class DateUtilsNew {
  /// Formats a [DateTime] object into the format "MMM dd, yyyy".
  static String formatToReadableDate(DateTime date) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  /// Formats a [DateTime] object into the format "EEE, MMM dd".
  static String formatToShortReadableDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEE, MMM dd');
    return formatter.format(date);
  }

  static bool isTimeWithinRange(String timeToCheck) {
    // Dummy fallback times since backend/provider is not available
    // Original: String startTime = AuthProvider.userSchool.startTime;
    // Original: String endTime = AuthProvider.userSchool.endTime;
    String startTime = '08:00:00 AM';
    String endTime = '06:00:00 PM';
    // Parse all times to DateTime objects for comparison
    // Assuming time format is "HH:MM:SS AM/PM"
    DateTime now = DateTime.now();

    debugPrint('startTime $startTime');
    debugPrint('endTime $endTime');
    debugPrint('timeToCheck $timeToCheck');

    // Create base date to attach times to
    DateTime baseDate = DateTime(now.year, now.month, now.day);

    // Parse the time strings into DateTime objects
    DateTime checkTime = DateFormat('hh:mm:ss a').parse(timeToCheck);
    DateTime start = DateFormat('hh:mm:ss a').parse(startTime);
    DateTime end = DateFormat('hh:mm:ss a').parse(endTime);

    // Add the base date
    checkTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      checkTime.hour,
      checkTime.minute,
      checkTime.second,
    );
    start = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      start.hour,
      start.minute,
      start.second,
    );
    end = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      end.hour,
      end.minute,
      end.second,
    );

    // Handle overnight shifts if end time is before start time
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    // Check if time is within range
    return (checkTime.isAfter(start) || checkTime.isAtSameMomentAs(start)) &&
        (checkTime.isBefore(end) || checkTime.isAtSameMomentAs(end));
  }

  static String formatDateTime(String dateString) {
    // Parse the date string to a DateTime object
    DateTime dateTime = DateTime.parse(dateString);

    // Format the DateTime object to the desired date and time format
    String formattedDate = DateFormat('dd-MMM-yyyy').format(dateTime);
    String formattedTime = DateFormat(
      'hh:mm a',
    ).format(dateTime); // 12-hour format

    // Combine date and time
    // return '$formattedDate   $formattedTime';

    return '$formattedTime';
  }

  /// Formats a [DateTime] object into the format "MM/DD/YYYY".
  static String formatToReadableDateOnly(DateTime date) {
    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    return formatter.format(date);
  }

  static DateTime? parseReadableDate(String text) {}
}
