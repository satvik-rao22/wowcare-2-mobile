import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/activity/entities/activity_detail.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/entities/activity_type_details.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_shared_activities_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/guardian_parent_signature_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/reject_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/update_activity_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';

/// Shared ViewModel (Cubit) for the activity create/edit/approve/reject forms.
///
/// It is the single seam through which the activity form screens reach the data
/// layer: every screen calls these methods instead of resolving the use-cases
/// itself (audit rule "Views call Cubits, not UseCases/DataSources"). The
/// methods are faithful pass-throughs to the use-cases, so behaviour is
/// unchanged; the forms keep their own field/UI state. MVVM golden rule: no
/// View/UI dependency here.
class ActivityEditorCubit extends Cubit<ActivityEditorState> {
  ActivityEditorCubit({
    required GetClassroomActivitySettingsUseCase getClassroomActivitySettingsUseCase,
    required GetActivityTypeDetailsUseCase getActivityTypeDetailsUseCase,
    required CreateActivityUseCase createActivityUseCase,
    required GetActivityUseCase getActivityUseCase,
    required UpdateActivityUseCase updateActivityUseCase,
    required ApproveActivityUseCase approveActivityUseCase,
    required RejectActivityUseCase rejectActivityUseCase,
    required CreateSharedActivitiesUseCase createSharedActivitiesUseCase,
    required GuardianParentSignatureUseCase guardianParentSignatureUseCase,
    required GetGuardianNameCodeMapForSchoolUseCase
        getGuardianNameCodeMapForSchoolUseCase,
  })  : _getClassroomActivitySettingsUseCase = getClassroomActivitySettingsUseCase,
        _getActivityTypeDetailsUseCase = getActivityTypeDetailsUseCase,
        _createActivityUseCase = createActivityUseCase,
        _getActivityUseCase = getActivityUseCase,
        _updateActivityUseCase = updateActivityUseCase,
        _approveActivityUseCase = approveActivityUseCase,
        _rejectActivityUseCase = rejectActivityUseCase,
        _createSharedActivitiesUseCase = createSharedActivitiesUseCase,
        _guardianParentSignatureUseCase = guardianParentSignatureUseCase,
        _getGuardianNameCodeMapForSchoolUseCase =
            getGuardianNameCodeMapForSchoolUseCase,
        super(const ActivityEditorState());

  final GetClassroomActivitySettingsUseCase _getClassroomActivitySettingsUseCase;
  final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  final CreateActivityUseCase _createActivityUseCase;
  final GetActivityUseCase _getActivityUseCase;
  final UpdateActivityUseCase _updateActivityUseCase;
  final ApproveActivityUseCase _approveActivityUseCase;
  final RejectActivityUseCase _rejectActivityUseCase;
  final CreateSharedActivitiesUseCase _createSharedActivitiesUseCase;
  final GuardianParentSignatureUseCase _guardianParentSignatureUseCase;
  final GetGuardianNameCodeMapForSchoolUseCase
      _getGuardianNameCodeMapForSchoolUseCase;

  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
    bool refresh = false,
  }) =>
      _getClassroomActivitySettingsUseCase(
        classroomCode: classroomCode,
        refresh: refresh,
      );

  Future<ActivityTypeDetails> getActivityTypeDetails({required String code}) =>
      _getActivityTypeDetailsUseCase(code: code);

  Future<ActivityDetail> getActivity({required String code}) =>
      _getActivityUseCase(code: code);

  Future<String> createActivity({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? napStart,
    bool? napEnd,
    bool? requireAdminApproval,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) =>
      _createActivityUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDate,
        description: description,
        napStart: napStart,
        napEnd: napEnd,
        requireAdminApproval: requireAdminApproval,
        parameterValues: parameterValues,
        attachments: attachments,
      );

  Future<String> updateActivity({
    required String code,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) =>
      _updateActivityUseCase(
        code: code,
        studentCodes: studentCodes,
        applyToStudentCodes: applyToStudentCodes,
        staffCode: staffCode,
        activityDate: activityDate,
        description: description,
        parameterValues: parameterValues,
        attachments: attachments,
      );

  Future<String> approveActivity({required String code}) =>
      _approveActivityUseCase(code: code);

  Future<String> rejectActivity({required String code}) =>
      _rejectActivityUseCase(code: code);

  /// Photo/video creates multiple per-student activities in one call.
  Future<List<Map<String, dynamic>>> createSharedActivities({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? requireAdminApproval,
    required List<Map<String, dynamic>> attachments,
    List<Map<String, dynamic>> parameterValues = const [],
  }) =>
      _createSharedActivitiesUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDate,
        description: description,
        requireAdminApproval: requireAdminApproval,
        attachments: attachments,
        parameterValues: parameterValues,
      );

  /// Records a guardian/parent signature on an incident activity parameter.
  Future<String> guardianParentSignature({
    required String code,
    required String parameterCode,
    required String guardianCode,
    String? signatureValue,
  }) =>
      _guardianParentSignatureUseCase(
        code: code,
        parameterCode: parameterCode,
        guardianCode: guardianCode,
        signatureValue: signatureValue,
      );

  /// Guardian name → code map for the school (used by the incident form's
  /// guardian-signature picker).
  Future<Map<String, String>> getGuardianNameCodeMapForSchool({
    required String schoolCode,
  }) =>
      _getGuardianNameCodeMapForSchoolUseCase(schoolCode: schoolCode);
}

/// Stateless marker state — this cubit is a data facade; the forms keep their
/// own field/UI state.
class ActivityEditorState extends Equatable {
  const ActivityEditorState();

  @override
  List<Object?> get props => const <Object?>[];
}
