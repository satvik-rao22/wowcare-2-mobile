import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_timezone.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('TaskTimezone.toUtcWire / fromUtcWire', () {
    test('converts a Boston wall-clock time to its UTC wire equivalent', () {
      // Jan 15 is EST (UTC-5): 9:00 AM Boston -> 14:00 UTC, same calendar day.
      final result = TaskTimezone.toUtcWire(
        date: DateTime(2026, 1, 15),
        time: const TimeOfDay(hour: 9, minute: 0),
        ianaName: 'America/New_York',
      );
      expect(result.$1, DateTime.utc(2026, 1, 15));
      expect(result.$2, '14:00');
    });

    test('rolls the UTC calendar date forward across midnight', () {
      // Jul 15 is EDT (UTC-4): 9:00 PM Boston -> 01:00 UTC the next day.
      final result = TaskTimezone.toUtcWire(
        date: DateTime(2026, 7, 15),
        time: const TimeOfDay(hour: 21, minute: 0),
        ianaName: 'America/New_York',
      );
      expect(result.$1, DateTime.utc(2026, 7, 16));
      expect(result.$2, '01:00');
    });

    test('round-trips through fromUtcWire back to the original wall clock', () {
      const iana = 'America/New_York';
      final toUtc = TaskTimezone.toUtcWire(
        date: DateTime(2026, 3, 2),
        time: const TimeOfDay(hour: 17, minute: 30),
        ianaName: iana,
      );
      final back = TaskTimezone.fromUtcWire(
        utcDate: toUtc.$1,
        hhmm: toUtc.$2,
        ianaName: iana,
      );
      expect(back.$1, DateTime(2026, 3, 2));
      expect(back.$2, const TimeOfDay(hour: 17, minute: 30));
    });
  });

  group('TaskTimezone fallback', () {
    test('lastKnownTimeZone substitutes Boston for the shared UTC fallback',
        () {
      expect(SchoolTimezoneResolver.lastKnownTimeZone.toUpperCase(), 'UTC');
      expect(TaskTimezone.lastKnownTimeZone, 'America/New_York');
    });
  });
}
