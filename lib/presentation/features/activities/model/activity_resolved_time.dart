/// The resolved instant for a picked activity date/time, alongside the
/// school-local "HH:mm:ss" string and "yyyy-MM-dd" date derived from that
/// SAME instant.
///
/// All three fields come from a single `SchoolZoneDateTime.resolvePickedInstantUtc`
/// call (see `ActivityEditorCubit.resolveActivityDateTime`), so the top-level
/// `activityDate` ISO value and the `Date`/`Time` parameter values sent in
/// the payload can never disagree — including across a school-zone midnight
/// boundary, where a raw (non-live-ticking) date picker field could
/// otherwise still show yesterday while this resolved instant has already
/// rolled to today.
class ActivityResolvedTime {
  const ActivityResolvedTime({
    required this.utcInstant,
    required this.iso,
    required this.localTimeHms,
    required this.localDateYmd,
  });

  final DateTime utcInstant;
  final String iso;
  final String localTimeHms;
  final String localDateYmd;
}
