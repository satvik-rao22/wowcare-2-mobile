import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

/// School-calendar time for the classroom domain.
///
/// The rules in `classroom_age_rules.dart` measure age against the **school's**
/// calendar day, not the device's — a child's birthday must tick over when the
/// school says it does, or two devices in different zones disagree about who is
/// out of range.
///
/// This exists so the domain layer has its own way to ask for school-today.
/// The rules previously imported
/// `presentation/features/attendance/view_model/attendance_school_time.dart`,
/// which put a cross-platform contract rule downstream of another feature's
/// view-model and out of reach of the domain layer's tests.
///
/// NOTE: this same "resolved school zone, else device-local" fallback is also
/// spelled out in `attendance_school_time.dart`, `scheduling_school_time.dart`
/// and `core/utils/billing_school_time.dart`. Four copies is three too many —
/// they should collapse onto one shared school clock. Kept as a per-feature
/// service here to match the existing convention rather than redesigning the
/// core time utilities as a side effect of this move.

/// True when no usable school zone has resolved yet, so callers fall back to
/// device-local rather than silently pretending the device is in UTC.
bool _schoolZoneUnresolved(String tz) =>
    tz.isEmpty ||
    tz.toUpperCase() == SchoolTimezoneResolver.fallbackTimeZone.toUpperCase();

/// Date-only "today" in the school calendar, using the most recently resolved
/// zone. Falls back to device-local today when no school zone has resolved yet,
/// so it is safe to call synchronously before the zone bootstrap settles.
DateTime classroomSchoolToday() {
  final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
  if (_schoolZoneUnresolved(tz)) {
    final n = ServerTimeService.instance.now();
    return DateTime(n.year, n.month, n.day);
  }
  return SchoolZoneDateTime.schoolCalendarTodayOnly(tz);
}
