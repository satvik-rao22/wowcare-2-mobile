import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wowcare/modules/attendance_v2/core/utils/av2_time_zone.dart';

/// UTC ⇄ school-local wall-clock.
///
/// `DateTime.parse(iso).toLocal()` is deliberately not used: it resolves to the
/// *device* zone, which shows the wrong hour whenever an admin sits in a
/// different timezone from the school they administer.
abstract final class RegTimeZone {
  const RegTimeZone._();

  static bool _inited = false;

  static void _ensureInit() {
    if (_inited) return;
    tz_data.initializeTimeZones();
    _inited = true;
  }

  static String resolveZone(String? zoneName) =>
      Av2TimeZone.resolveZone(zoneName);

  static String toUtcIso(DateTime local, String zoneName) =>
      Av2TimeZone.toUtcIso(local, resolveZone(zoneName));

  /// Returns a plain [DateTime] whose fields are the school clock at that
  /// instant, which is what pickers and formatters need.
  static DateTime? schoolLocal(String? utcIso, String zoneName) {
    final raw = (utcIso ?? '').trim();
    if (raw.isEmpty) return null;
    final instant = DateTime.tryParse(raw);
    if (instant == null) return null;

    _ensureInit();
    tz.Location location;
    try {
      location = tz.getLocation(resolveZone(zoneName));
    } catch (_) {
      location = tz.getLocation('UTC');
    }
    final local = tz.TZDateTime.from(instant.toUtc(), location);
    // Milliseconds kept: createdAt and updatedAt can land in the same second,
    // and truncating would make an edited request look untouched.
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
    );
  }

  /// `attendanceDate` is a calendar date, so no conversion applies.
  static DateTime? dateOnly(String? yyyyMmDd) {
    final raw = (yyyyMmDd ?? '').trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String dateToWire(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
