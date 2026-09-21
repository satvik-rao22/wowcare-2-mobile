import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/av2_config.dart';

/// Converts an admin's wall-clock pick (school-local) into a UTC ISO instant
/// for the edit PATCH, using the school's IANA timezone — independent of the
/// admin's device timezone.
class Av2TimeZone {
  const Av2TimeZone._();

  static bool _inited = false;

  static void _ensureInit() {
    if (_inited) return;
    tz_data.initializeTimeZones();
    _inited = true;
  }

  /// Resolves a usable IANA zone name. Falls back to the configured default
  /// when the backend sends an unusable value (empty / "Z" / "UTC").
  static String resolveZone(String? tzName) {
    final t = (tzName ?? '').trim();
    if (t.isEmpty || t == 'Z' || t.toUpperCase() == 'UTC' || !t.contains('/')) {
      return Av2Config.fallbackTimeZone;
    }
    return t;
  }

  /// [local] carries the picked wall-clock fields (its y/m/d/h/m are read as
  /// school-local). Returns e.g. "2026-06-23T12:05:00.000Z".
  static String toUtcIso(DateTime local, String zoneName) {
    _ensureInit();
    tz.Location loc;
    try {
      loc = tz.getLocation(zoneName);
    } catch (_) {
      loc = tz.getLocation('UTC');
    }
    final t = tz.TZDateTime(
      loc,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    return t.toUtc().toIso8601String();
  }
}
