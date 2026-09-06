part of 'bottle_activity_cubit.dart';

/// Immutable form state for [BottleActivityScreen]. Like the medication form,
/// but adds the loaded attachment rows (for the edit-patch merge) and the staff
/// label parsed from activity parameters. Write-only inputs (date/time/staff,
/// and the ounce amount, which lives in the picker widget) are not held here.
class BottleActivityState extends Equatable {
  const BottleActivityState({
    this.selectedStudents = const <String>[],
    this.selectedStudentsData = const <Map<String, dynamic>>[],
    this.activityTypeCode,
    this.staffName = '',
    this.staffType = '',
    this.staffCode,
    this.schoolCode,
    this.organizationCode,
    this.staffPresentLabelForEdit,
    this.requireAdminApproval = false,
    this.isSubmitting = false,
    this.isApprovingOrRejecting = false,
    this.isSavingBeforeApprove = false,
    this.loadingActivityDetail = false,
    this.liveActivity,
    this.scopedEditStudentIndices = const <int>{},
    this.detailAttachmentRows = const <Map<String, dynamic>>[],
  });

  final List<String> selectedStudents;
  final List<Map<String, dynamic>> selectedStudentsData;
  final String? activityTypeCode;
  final String staffName;
  final String staffType;
  final String? staffCode;
  final String? schoolCode;
  final String? organizationCode;

  /// Staff label parsed from activity parameters (API may set createdBy to
  /// "system"); falls back to the activity's staffPresent in the view.
  final String? staffPresentLabelForEdit;

  final bool requireAdminApproval;
  final bool isSubmitting;
  final bool isApprovingOrRejecting;
  final bool isSavingBeforeApprove;
  final bool loadingActivityDetail;
  final ActivityItem? liveActivity;
  final Set<int> scopedEditStudentIndices;
  final List<Map<String, dynamic>> detailAttachmentRows;

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

  BottleActivityState copyWith({
    List<String>? selectedStudents,
    List<Map<String, dynamic>>? selectedStudentsData,
    Object? activityTypeCode = _unset,
    String? staffName,
    String? staffType,
    Object? staffCode = _unset,
    Object? schoolCode = _unset,
    Object? organizationCode = _unset,
    Object? staffPresentLabelForEdit = _unset,
    bool? requireAdminApproval,
    bool? isSubmitting,
    bool? isApprovingOrRejecting,
    bool? isSavingBeforeApprove,
    bool? loadingActivityDetail,
    Object? liveActivity = _unset,
    Set<int>? scopedEditStudentIndices,
    List<Map<String, dynamic>>? detailAttachmentRows,
  }) {
    return BottleActivityState(
      selectedStudents: selectedStudents ?? this.selectedStudents,
      selectedStudentsData: selectedStudentsData ?? this.selectedStudentsData,
      activityTypeCode: identical(activityTypeCode, _unset)
          ? this.activityTypeCode
          : activityTypeCode as String?,
      staffName: staffName ?? this.staffName,
      staffType: staffType ?? this.staffType,
      staffCode:
          identical(staffCode, _unset) ? this.staffCode : staffCode as String?,
      schoolCode: identical(schoolCode, _unset)
          ? this.schoolCode
          : schoolCode as String?,
      organizationCode: identical(organizationCode, _unset)
          ? this.organizationCode
          : organizationCode as String?,
      staffPresentLabelForEdit: identical(staffPresentLabelForEdit, _unset)
          ? this.staffPresentLabelForEdit
          : staffPresentLabelForEdit as String?,
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
      detailAttachmentRows: detailAttachmentRows ?? this.detailAttachmentRows,
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
        staffPresentLabelForEdit,
        requireAdminApproval,
        isSubmitting,
        isApprovingOrRejecting,
        isSavingBeforeApprove,
        loadingActivityDetail,
        liveActivity,
        scopedEditStudentIndices,
        detailAttachmentRows,
      ];
}

const Object _unset = Object();
