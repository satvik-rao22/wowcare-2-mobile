part of 'medication_activity_cubit.dart';

/// Immutable form state for [MedicationActivityScreen]. Holds everything that
/// used to drive `setState` in the old `StatefulWidget`. Transient, write-only
/// inputs that must NOT trigger a rebuild (the date/time/staff-present pickers
/// own their display) live as private fields on [MedicationActivityCubit]
/// instead — see `activityDate`, `activityTime`, `staffPresentCode` there.
class MedicationActivityState extends Equatable {
  const MedicationActivityState({
    this.selectedStudents = const <String>[],
    this.selectedStudentsData = const <Map<String, dynamic>>[],
    this.activityTypeCode,
    this.staffName = '',
    this.staffType = '',
    this.staffCode,
    this.schoolCode,
    this.organizationCode,
    this.requireAdminApproval = false,
    this.isSubmitting = false,
    this.isApprovingOrRejecting = false,
    this.isSavingBeforeApprove = false,
    this.loadingActivityDetail = false,
    this.liveActivity,
    this.scopedEditStudentIndices = const <int>{},
  });

  final List<String> selectedStudents;
  final List<Map<String, dynamic>> selectedStudentsData;
  final String? activityTypeCode;
  final String staffName;
  final String staffType;
  final String? staffCode;
  final String? schoolCode;
  final String? organizationCode;
  final bool requireAdminApproval;
  final bool isSubmitting;
  final bool isApprovingOrRejecting;
  final bool isSavingBeforeApprove;
  final bool loadingActivityDetail;
  final ActivityItem? liveActivity;
  final Set<int> scopedEditStudentIndices;

  static const Set<String> _adminDesignations = {
    'SCHOOL_ADMIN',
    'ORGANIZATION_ADMIN',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'OWNER',
  };

  bool get isAdminDesignation =>
      _adminDesignations.contains(staffType.trim().toUpperCase());

  bool get showRequireAdminApprovalToggle => !isAdminDesignation;

  MedicationActivityState copyWith({
    List<String>? selectedStudents,
    List<Map<String, dynamic>>? selectedStudentsData,
    Object? activityTypeCode = _unset,
    String? staffName,
    String? staffType,
    Object? staffCode = _unset,
    Object? schoolCode = _unset,
    Object? organizationCode = _unset,
    bool? requireAdminApproval,
    bool? isSubmitting,
    bool? isApprovingOrRejecting,
    bool? isSavingBeforeApprove,
    bool? loadingActivityDetail,
    Object? liveActivity = _unset,
    Set<int>? scopedEditStudentIndices,
  }) {
    return MedicationActivityState(
      selectedStudents: selectedStudents ?? this.selectedStudents,
      selectedStudentsData: selectedStudentsData ?? this.selectedStudentsData,
      activityTypeCode: identical(activityTypeCode, _unset)
          ? this.activityTypeCode
          : activityTypeCode as String?,
      staffName: staffName ?? this.staffName,
      staffType: staffType ?? this.staffType,
      staffCode: identical(staffCode, _unset)
          ? this.staffCode
          : staffCode as String?,
      schoolCode: identical(schoolCode, _unset)
          ? this.schoolCode
          : schoolCode as String?,
      organizationCode: identical(organizationCode, _unset)
          ? this.organizationCode
          : organizationCode as String?,
      requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isApprovingOrRejecting:
          isApprovingOrRejecting ?? this.isApprovingOrRejecting,
      isSavingBeforeApprove:
          isSavingBeforeApprove ?? this.isSavingBeforeApprove,
      loadingActivityDetail:
          loadingActivityDetail ?? this.loadingActivityDetail,
      liveActivity: identical(liveActivity, _unset)
          ? this.liveActivity
          : liveActivity as ActivityItem?,
      scopedEditStudentIndices:
          scopedEditStudentIndices ?? this.scopedEditStudentIndices,
    );
  }

  @override
  List<Object?> get props => [
    selectedStudents,
    selectedStudentsData,
    activityTypeCode,
    staffName,
    staffType,
    staffCode,
    schoolCode,
    organizationCode,
    requireAdminApproval,
    isSubmitting,
    isApprovingOrRejecting,
    isSavingBeforeApprove,
    loadingActivityDetail,
    liveActivity,
    scopedEditStudentIndices,
  ];
}

const Object _unset = Object();
