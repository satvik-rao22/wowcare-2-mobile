import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

import '../../../../core/util/school_zone_datetime.dart';

/// Whether two [TimeOfDay]s represent the same hour:minute (null-safe).
bool sameTimeOfDay(TimeOfDay? a, TimeOfDay? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.hour == b.hour && a.minute == b.minute;
}

/// Parses a server/display time string into a [TimeOfDay], interpreting ISO
/// instants in [schoolIana]. Returns null for blank / "not yet signed in|out"
/// values or anything unparseable. Shared by the staff/student edit-attendance
/// forms, which prefill the time pickers from a daily-record string.
TimeOfDay? parseSchoolTimeOrNull(String? timeString, String schoolIana) {
  if (timeString == null) return null;
  final raw = timeString.trim();
  if (raw.isEmpty) return null;
  final lowerRaw = raw.toLowerCase();
  if (lowerRaw == 'not yet signed out' || lowerRaw == 'not yet signed in') {
    return null;
  }

  try {
    final iso = DateTime.tryParse(raw);
    if (iso != null) {
      return SchoolZoneDateTime.timeOfDayFromInstantInSchool(iso, schoolIana);
    }
  } catch (_) {}

  final byIndex = lowerRaw.indexOf(' by ');
  final withoutBy = byIndex > 0 ? raw.substring(0, byIndex).trim() : raw;
  final normalized = withoutBy.replaceAll('.', '').trim();

  final ampmMatch =
      RegExp(r'(\d{1,2}:\d{2}(?::\d{2})?\s*[AaPp][Mm])').firstMatch(normalized);
  if (ampmMatch != null) {
    final candidate = ampmMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
    try {
      final hasSeconds = RegExp(r':\d{2}\s*[AaPp][Mm]$').hasMatch(candidate);
      final parsed = hasSeconds
          ? DateFormat('h:mm:ss a').parse(candidate)
          : DateFormat.jm().parse(candidate);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {}
  }

  final hmsMatch =
      RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(normalized);
  if (hmsMatch != null) {
    final hour = int.tryParse(hmsMatch.group(1)!);
    final minute = int.tryParse(hmsMatch.group(2)!);
    if (hour != null &&
        minute != null &&
        hour >= 0 &&
        hour < 24 &&
        minute >= 0 &&
        minute < 60) {
      return TimeOfDay(hour: hour, minute: minute);
    }
  }

  return null;
}
