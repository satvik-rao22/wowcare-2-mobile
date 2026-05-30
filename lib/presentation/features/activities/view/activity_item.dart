/// Shared feed / edit UI model for activity cards (daily + custom range tabs).
class ActivityItem {
  final String time;
  final String date;
  final String name;
  final String? description;
  final String? photoUrl;
  final String? videoUrl;
  final List<String> studentList;
  final String createdBy;
  final String? activityType;
  final List<String>? categoryType;
  final String? mealType;
  final String? mealQuantity;
  final String? amountConsumed;
  final String? bottleConsumptionStatus;
  final String? napStartTime;
  final bool? remainderOn;
  final String? napEndTime;
  final String? whatHappened;
  final bool? firstAidAdministered;
  final String? staffPresent;
  final String? staffPresentCode;
  final String? additionalNotes;
  final String? bathroomType;
  final String? bathroomSubType;
  final String? bathroomDiaperSize;
  final String? activityTypeCode;
  final String? activityCode;
  final String? studentCode;
  final String? classroomCode;
  final String? activityDateIso;
  final List<Map<String, dynamic>>? snapshotAttachments;
  final List<Map<String, String>>? studentActivityRefs;
  final String? approvalStatus;

  const ActivityItem({
    required this.time,
    required this.date,
    required this.name,
    this.description,
    this.photoUrl,
    this.videoUrl,
    required this.studentList,
    required this.createdBy,
    this.activityType,
    this.categoryType,
    this.mealType,
    this.mealQuantity,
    this.amountConsumed,
    this.bottleConsumptionStatus,
    this.napStartTime,
    this.remainderOn,
    this.napEndTime,
    this.whatHappened,
    this.firstAidAdministered,
    this.staffPresent,
    this.staffPresentCode,
    this.additionalNotes,
    this.bathroomType,
    this.bathroomSubType,
    this.bathroomDiaperSize,
    this.activityTypeCode,
    this.activityCode,
    this.studentCode,
    this.classroomCode,
    this.activityDateIso,
    this.snapshotAttachments,
    this.studentActivityRefs,
    this.approvalStatus,
  });

  /// Blank placeholder used when no activity exists yet (e.g. create mode),
  /// so `effectiveActivity`-style getters never force-unwrap a null.
  static const ActivityItem empty = ActivityItem(
    time: '',
    date: '',
    name: '',
    studentList: <String>[],
    createdBy: '',
  );
}
