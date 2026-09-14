/// The resolved instant for a picked activity date/time, alongside the
/// school-local "HH:mm:ss" string derived from that SAME instant.
///
/// Both fields come from a single `SchoolZoneDateTime.resolvePickedInstantUtc`
/// call (see `ActivityEditorCubit.resolveActivityDateTime`), so the top-level
/// `activityDate` ISO value and the `time` parameter value sent in the
/// payload can never disagree: if the picker is still at its untouched
/// default, both carry the real server-synced seconds; if the user changed
/// the date/time, both are truncated to `:00` seconds.
class ActivityResolvedTime {
  const ActivityResolvedTime({
    required this.utcInstant,
    required this.iso,
    required this.localTimeHms,
  });

  final DateTime utcInstant;
  final String iso;
  final String localTimeHms;
}
