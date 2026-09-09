import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wowcare/modules/attendance_v2/core/utils/av2_time_zone.dart';

/// Timezone conversion for the regularization payloads (spec §10.1).
///
/// The API speaks **UTC ISO-8601** in both directions and takes `timeZone` as
/// an input parameter so it can interpret wall-clock times. The UI, meanwhile,
/// only ever deals in **school-local wall-clock** — a time picker's
/// `.hour`/`.minute` must be the time the staff would read off a clock at the
/// school, not on the device.
///
/// So two conversions are needed:
///
/// * outgoing — school-local wall-clock → UTC ISO. Delegated to
///   [Av2TimeZone.toUtcIso] so there is exactly one implementation of that
///   rule in the app.
/// * incoming — UTC ISO → school-local wall-clock. **New here**, because
///   `attendance_v2`'s overtime endpoints return already-local `"HH:mm:ss"`
///   strings and never needed it.
///
/// `DateTime.parse(iso).toLocal()` is deliberately **not** used: it resolves
/// to the *device's* zone, which silently produces the wrong hour whenever an
/// admin is in a different timezone from the school they administer.
abstract final class RegTimeZone {
  const RegTimeZone._();

  static bool _inited = false;

  static void _ensureInit() {
    if (_inited) return;
    tz_data.initializeTimeZones();
    _inited = true;
  }

  /// Falls back to a usable IANA zone when the backend sends `""` / `"Z"` /
  /// `"UTC"`. Shared with `attendance_v2` so both modules agree.
  static String resolveZone(String? zoneName) =>
      Av2TimeZone.resolveZone(zoneName);

  /// School-local wall-clock → UTC ISO instant, for request payloads.
  static String toUtcIso(DateTime local, String zoneName) =>
      Av2TimeZone.toUtcIso(local, resolveZone(zoneName));

  /// UTC ISO instant → a plain [DateTime] carrying the **school-local
  /// wall-clock fields**, for pickers and formatters.
  ///
  /// The result is intentionally *not* a `TZDateTime` and carries no offset:
  /// its `.hour` / `.minute` are what the school clock reads at that instant,
  /// which is exactly what the UI needs. Returns `null` for a missing or
  /// unparseable value — every incoming time in the contract is nullable
  /// except `requestedSignOutTime`.
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
    // Sub-second precision is preserved: `createdAt` and `updatedAt` can land
    // in the same second, and truncating would make an edited request look
    // untouched (`RegularizationRequest.wasEdited`).
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

  /// Parses a school-local calendar date (`"2026-08-03"`), with no time
  /// component and therefore no conversion. `attendanceDate` is a date, not an
  /// instant (§10.1).
  static DateTime? dateOnly(String? yyyyMmDd) {
    final raw = (yyyyMmDd ?? '').trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Formats a school-local date as the API's `attendanceDate`.
  static String dateToWire(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
