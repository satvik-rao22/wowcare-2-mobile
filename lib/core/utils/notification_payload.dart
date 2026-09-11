/// Codec for the deep-link payload attached to a *local* notification (the one
/// the app shows itself for a foreground FCM message, via the geofence service).
///
/// Background/tray taps carry the full FCM `data` map (incl. org/school), but a
/// local notification only carries an opaque string payload. To keep cross-school
/// switching working for foreground-shown notifications — including the case
/// where the user kills the app and later taps that local notification — we
/// encode the resolved go_router location together with the target org/school as
/// reserved query params, and strip them back out on tap.
library;

const _kOrgParam = '__org';
const _kSchoolParam = '__sch';

/// Builds the local-notification payload: the [location] with [organizationCode]
/// /[schoolCode] appended as reserved params (only when both are present).
String encodeNotificationPayload({
  required String location,
  String? organizationCode,
  String? schoolCode,
}) {
  final org = (organizationCode ?? '').trim();
  final sch = (schoolCode ?? '').trim();
  if (org.isEmpty || sch.isEmpty) return location;
  final sep = location.contains('?') ? '&' : '?';
  return '$location$sep$_kOrgParam=${Uri.encodeComponent(org)}'
      '&$_kSchoolParam=${Uri.encodeComponent(sch)}';
}

/// The clean go_router location plus the target org/school (null when absent).
class DecodedNotificationPayload {
  const DecodedNotificationPayload(
    this.location,
    this.organizationCode,
    this.schoolCode,
  );
  final String location;
  final String? organizationCode;
  final String? schoolCode;
}

/// Inverse of [encodeNotificationPayload]: pulls the reserved org/school params
/// out, returning the location with all other query params preserved.
DecodedNotificationPayload decodeNotificationPayload(String payload) {
  final qIndex = payload.indexOf('?');
  if (qIndex < 0) return DecodedNotificationPayload(payload, null, null);
  final base = payload.substring(0, qIndex);
  final query = payload.substring(qIndex + 1);
  final kept = <String>[];
  String? org;
  String? school;
  for (final part in query.split('&')) {
    if (part.isEmpty) continue;
    final eq = part.indexOf('=');
    final key = eq < 0 ? part : part.substring(0, eq);
    final value = eq < 0 ? '' : part.substring(eq + 1);
    if (key == _kOrgParam) {
      org = Uri.decodeComponent(value);
    } else if (key == _kSchoolParam) {
      school = Uri.decodeComponent(value);
    } else {
      kept.add(part);
    }
  }
  final location = kept.isEmpty ? base : '$base?${kept.join('&')}';
  return DecodedNotificationPayload(location, org, school);
}
