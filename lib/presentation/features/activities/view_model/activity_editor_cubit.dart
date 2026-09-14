import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/presentation/features/activities/model/activity_resolved_time.dart';
import 'package:wowcare/presentation/features/activities/model/attendance_window_validation_result.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_selected_date_prefill.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/user_details_school_roles.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_staff_context.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/entities/activity_detail.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/entities/activity_shared_card_result.dart';
import 'package:wowcare/domain/features/activity/entities/activity_type_details.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_shared_activities_usecase.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_upload_asset_statuses_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/guardian_parent_signature_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/upload_activity_assets_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/wait_activity_assets_ready_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/reject_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/retrieve_lost_media_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/stage_media_for_upload_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/discard_staged_media_usecase.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';
import 'package:wowcare/domain/features/activity/entities/staged_media.dart';
import 'package:wowcare/domain/features/activity/entities/video_validation_result.dart';
import 'package:wowcare/domain/features/activity/usecases/validate_video_for_upload_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/update_activity_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/resolve_logged_in_staff_code_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_page_usecase.dart';
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
    required GetClassroomActivitySettingsUseCase
    getClassroomActivitySettingsUseCase,
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
    required GetStaffTodaySignInStatusUseCase getStaffTodaySignInStatusUseCase,
    required StorageService storageService,
    required UploadActivityAssetsUseCase uploadActivityAssetsUseCase,
    required GetActivityUploadAssetStatusesUseCase
    getActivityUploadAssetStatusesUseCase,
    required WaitActivityAssetsReadyUseCase waitActivityAssetsReadyUseCase,
    required RetrieveLostMediaUseCase retrieveLostMediaUseCase,
    required StageMediaForUploadUseCase stageMediaForUploadUseCase,
    required ValidateVideoForUploadUseCase validateVideoForUploadUseCase,
    required DiscardStagedMediaUseCase discardStagedMediaUseCase,
    required ApiClient apiClient,
    required StaffRepository staffRepository,
    required GetStaffPageUseCase getStaffPageUseCase,
    required GetStaffSignInStatusAtTimeUseCase
    getStaffSignInStatusAtTimeUseCase,
    required GetStudentSignInStatusAtTimeUseCase
    getStudentSignInStatusAtTimeUseCase,
    required GetStudentTodaySignInStatusMapUseCase
    getStudentTodaySignInStatusMapUseCase,
  }) : _getStaffSignInStatusAtTimeUseCase = getStaffSignInStatusAtTimeUseCase,
       _getStudentSignInStatusAtTimeUseCase =
           getStudentSignInStatusAtTimeUseCase,
       _getStudentTodaySignInStatusMapUseCase =
           getStudentTodaySignInStatusMapUseCase,
       _getClassroomActivitySettingsUseCase =
           getClassroomActivitySettingsUseCase,
       _waitActivityAssetsReadyUseCase = waitActivityAssetsReadyUseCase,
       _retrieveLostMediaUseCase = retrieveLostMediaUseCase,
       _stageMediaForUploadUseCase = stageMediaForUploadUseCase,
       _validateVideoForUploadUseCase = validateVideoForUploadUseCase,
       _discardStagedMediaUseCase = discardStagedMediaUseCase,
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
       _getStaffTodaySignInStatusUseCase = getStaffTodaySignInStatusUseCase,
       _storage = storageService,
       _uploadActivityAssetsUseCase = uploadActivityAssetsUseCase,
       _getActivityUploadAssetStatusesUseCase =
           getActivityUploadAssetStatusesUseCase,
       _apiClient = apiClient,
       _staffRepository = staffRepository,
       _getStaffPageUseCase = getStaffPageUseCase,
       super(const ActivityEditorState());

  final GetClassroomActivitySettingsUseCase
  _getClassroomActivitySettingsUseCase;
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
  final GetStaffTodaySignInStatusUseCase _getStaffTodaySignInStatusUseCase;
  final StorageService _storage;
  final UploadActivityAssetsUseCase _uploadActivityAssetsUseCase;
  final WaitActivityAssetsReadyUseCase _waitActivityAssetsReadyUseCase;
  final RetrieveLostMediaUseCase _retrieveLostMediaUseCase;
  final StageMediaForUploadUseCase _stageMediaForUploadUseCase;
  final ValidateVideoForUploadUseCase _validateVideoForUploadUseCase;
  final DiscardStagedMediaUseCase _discardStagedMediaUseCase;
  final GetStaffSignInStatusAtTimeUseCase _getStaffSignInStatusAtTimeUseCase;
  final GetStudentSignInStatusAtTimeUseCase
  _getStudentSignInStatusAtTimeUseCase;
  final GetStudentTodaySignInStatusMapUseCase
  _getStudentTodaySignInStatusMapUseCase;
  final GetActivityUploadAssetStatusesUseCase
  _getActivityUploadAssetStatusesUseCase;
  final ApiClient _apiClient;
  final StaffRepository _staffRepository;
  final GetStaffPageUseCase _getStaffPageUseCase;

  // Built from the already-injected StorageService/StaffRepository rather
  // than constructor-injected themselves — no DI registration needed, and
  // this is the only place either use case is constructed. Replaces the
  // `resolve_logged_in_staff_code.dart` free functions (Mandate 5/3): forms
  // now call `_editor.resolveStaffCode()`/`resolveStaffDisplayName()`
  // instead of resolving StorageService/StaffRepository themselves.
  late final ResolveLoggedInStaffCodeUseCase _resolveStaffCodeUseCase =
      ResolveLoggedInStaffCodeUseCase(_storage, _staffRepository);
  late final ResolveLoggedInStaffDisplayNameUseCase
  _resolveStaffDisplayNameUseCase = ResolveLoggedInStaffDisplayNameUseCase(
    _staffRepository,
    _resolveStaffCodeUseCase,
  );

  Future<String?> resolveStaffCode() => _resolveStaffCodeUseCase();

  Future<String> resolveStaffDisplayName({String? staffCode}) =>
      _resolveStaffDisplayNameUseCase(staffCode: staffCode);

  /// Keyed single-flight for the non-idempotent mutations. A second identical
  /// submission that arrives while the first is still in flight (double-tap,
  /// a re-fired callback, an upload-completion racing the submit) is coalesced
  /// onto the SAME future instead of issuing a second create/update — the
  /// data-layer guard the audit requires beyond the forms' own _isSubmitting
  /// flag. Each form screen submits through a single editor instance, so this
  /// per-instance map covers that screen's submissions.
  final Map<String, Future<dynamic>> _inFlightMutations =
      <String, Future<dynamic>>{};

  Future<T> _singleFlight<T>(String key, Future<T> Function() op) {
    final existing = _inFlightMutations[key];
    if (existing != null) return existing as Future<T>;
    final future = op();
    _inFlightMutations[key] = future;
    // Detach cleanup from the caller's future so an error flows ONLY through the
    // caller (not double-reported as unhandled).
    future.whenComplete(() {
      if (identical(_inFlightMutations[key], future)) {
        _inFlightMutations.remove(key);
      }
    }).ignore();
    return future;
  }

  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
    bool refresh = false,
  }) => _getClassroomActivitySettingsUseCase(
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
    bool? napReminderEnabled,
    String? napReminderUserCode,
    String? napReminderRole,
    bool? requireAdminApproval,
    List<ActivityParameterValue> parameterValues = const [],
    List<ActivityAttachment> attachments = const [],
  }) => _singleFlight(
    'create:$activityTypeCode:$classroomCode:${studentCodes.join(',')}:$activityDate',
    () => _createActivityUseCase(
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
      napReminderEnabled: napReminderEnabled,
      napReminderUserCode: napReminderUserCode,
      napReminderRole: napReminderRole,
      requireAdminApproval: requireAdminApproval,
      parameterValues: parameterValues,
      attachments: attachments,
    ),
  );

  Future<String> updateActivity({
    required String code,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    List<ActivityParameterValue> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) => _singleFlight(
    'update:$code',
    () => _updateActivityUseCase(
      code: code,
      studentCodes: studentCodes,
      applyToStudentCodes: applyToStudentCodes,
      staffCode: staffCode,
      activityDate: activityDate,
      description: description,
      parameterValues: parameterValues,
      attachments: attachments,
    ),
  );

  Future<String> approveActivity({required String code}) =>
      _approveActivityUseCase(code: code);

  Future<String> rejectActivity({required String code}) =>
      _rejectActivityUseCase(code: code);

  /// Photo/video creates multiple per-student activities in one call.
  Future<List<ActivitySharedCardResult>> createSharedActivities({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? requireAdminApproval,
    required List<ActivityAttachment> attachments,
    List<ActivityParameterValue> parameterValues = const [],
  }) => _singleFlight(
    'createShared:$activityTypeCode:$classroomCode:${studentCodes.join(',')}:$activityDate',
    () => _createSharedActivitiesUseCase(
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
    ),
  );

  /// Records a guardian/parent signature on an incident activity parameter.
  Future<String> guardianParentSignature({
    required String code,
    required String parameterCode,
    required String guardianCode,
    String? signatureValue,
  }) => _guardianParentSignatureUseCase(
    code: code,
    parameterCode: parameterCode,
    guardianCode: guardianCode,
    signatureValue: signatureValue,
  );

  /// Guardian name → code map for the school (used by the incident form's
  /// guardian-signature picker).
  Future<Map<String, String>> getGuardianNameCodeMapForSchool({
    required String schoolCode,
  }) => _getGuardianNameCodeMapForSchoolUseCase(schoolCode: schoolCode);

  /// Opens one upload session and runs presign → PUT → complete for every
  /// item — the photo/video form's create-flow media upload.
  Future<ActivityAssetUploadResult> uploadActivityAssets({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
    required String ownerType,
    required String ownerCode,
    required List<ActivityUploadItem> items,
    void Function(int itemIndex, int totalItems, int percent)? onItemProgress,
    void Function(int completedItems, int totalItems)? onItemComplete,
    void Function(String filePath, String assetCode, String sessionCode)?
    onAssetUploaded,
    CancelToken? cancelToken,
  }) => _uploadActivityAssetsUseCase(
    organizationCode: organizationCode,
    schoolCode: schoolCode,
    classroomCode: classroomCode,
    activityTypeCode: activityTypeCode,
    bindingMode: bindingMode,
    studentCodes: studentCodes,
    ownerType: ownerType,
    ownerCode: ownerCode,
    items: items,
    onItemProgress: onItemProgress,
    onItemComplete: onItemComplete,
    onAssetUploaded: onAssetUploaded,
    cancelToken: cancelToken,
  );

  /// Blocking readiness poll — the photo/video form's strategy for confirming
  /// uploaded assets before they can be linked to the activity.
  Future<void> waitAssetsReady({
    required String sessionCode,
    required List<String> assetCodes,
  }) => _waitActivityAssetsReadyUseCase(
    sessionCode: sessionCode,
    assetCodes: assetCodes,
  );

  /// Claims a camera capture that Android completed but could not deliver,
  /// because it destroyed the host activity while the camera app was open —
  /// the "recorded a video and the app restarted with nothing to show for it"
  /// case. Returns [RecoveredMedia.none] when there is nothing pending, which
  /// is the normal result on every run and the only result on iOS.
  ///
  /// DESTRUCTIVE: the platform hands each cached capture back exactly once, so
  /// this must have a single caller per screen (today: `MediaUploader`).
  /// Never throws — see [RetrieveLostMediaUseCase].
  Future<RecoveredMedia> retrieveLostMedia() => _retrieveLostMediaUseCase();

  /// Copies a freshly captured/picked file out of cache into persistent
  /// storage, so an upload cannot be killed by Android reclaiming the cache
  /// directory mid-flight. Everything downstream reads the returned path.
  ///
  /// Throws [MediaStagingException] — and only that — when the copy fails, so
  /// the caller has one thing to catch and can turn it into a message.
  Future<StagedMedia> stageMediaForUpload(String sourcePath) =>
      _stageMediaForUploadUseCase(sourcePath);

  /// Deletes a staged copy. Call ONLY once the server has confirmed the upload
  /// or the user has explicitly discarded the capture — earlier throws away the
  /// only copy of something that may still need retrying. Never throws.
  Future<void> discardStagedMedia(String stagedPath) =>
      _discardStagedMediaUseCase(stagedPath);

  /// Runs every pre-upload rule against the STAGED video and returns a typed
  /// verdict, so the caller can show the specific reason it failed.
  ///
  /// Must run before the checksum: the bytes validated here are the bytes that
  /// get hashed and uploaded.
  Future<VideoValidationResult> validateVideoForUpload(String path) =>
      _validateVideoForUploadUseCase(path);

  /// One-shot status read — the photo/video form's background-poll strategy
  /// for assets still processing after upload.
  Future<Map<String, String>> getActivityUploadAssetStatuses({
    required String sessionCode,
    required List<String> assetCodes,
  }) => _getActivityUploadAssetStatusesUseCase(
    sessionCode: sessionCode,
    assetCodes: assetCodes,
  );

  static const Set<String> _staffAtTimeValidationPersonas = <String>{
    'STAFF',
    'TEACHER',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
  };

  Future<bool> _shouldRunStaffAtTimeValidation() async {
    final staffType = (await _storage.getString(StorageKeys.staffType) ?? '')
        .trim()
        .toUpperCase();
    if (staffType.isNotEmpty) {
      return _staffAtTimeValidationPersonas.contains(staffType);
    }

    // ACTIVE persona (single value), not a scan of the account's full cached
    // roles list below — that list always contains every role the account
    // has across every school, so a dual-role user (e.g. GUARDIAN + STAFF in
    // a different school) would be misdetected as staff regardless of which
    // persona is actually active right now.
    final activeRole =
        (await _storage.getString(StorageKeys.activeSchoolRole) ?? '')
            .trim()
            .toUpperCase();
    if (activeRole.isNotEmpty) {
      return _staffAtTimeValidationPersonas.contains(activeRole);
    }

    final rolesRaw = (await _storage.getString(StorageKeys.roles) ?? '')
        .trim();
    if (rolesRaw.isEmpty) return false;
    try {
      final decoded = jsonDecode(rolesRaw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final roleCode = (item['role'] ?? item['code'] ?? '')
              .toString()
              .trim()
              .toUpperCase();
          if (_staffAtTimeValidationPersonas.contains(roleCode)) return true;
        }
        return false;
      }
    } catch (_) {
      final rawUpper = rolesRaw.toUpperCase();
      for (final role in _staffAtTimeValidationPersonas) {
        if (rawUpper.contains(role)) return true;
      }
    }
    return false;
  }

  static String _resolveClassroomCodeFromSelectedStudents(
    List<Map<String, dynamic>> students,
  ) {
    for (final student in students) {
      final dynamic classroomCodeDynamic =
          student['classroomCode'] ?? student['classroomcode'];
      final classroomCode = classroomCodeDynamic is String
          ? classroomCodeDynamic.trim()
          : '';
      if (classroomCode.isNotEmpty) return classroomCode;
    }
    return '';
  }

  /// A transferred student's classroom-scoped "at time" sign-in record can
  /// still be keyed to the classroom they were transferred OUT of, so the
  /// scoped check below can return "not signed in" for a student who is
  /// genuinely present. This window bounds a classroom-agnostic fallback
  /// (today's sign-in status, no classroom filter) to only kick in for
  /// effectively-"now" submissions, so a real backdated/future check still
  /// gets the stricter classroom-scoped answer.
  static const Duration _fallbackSignInCheckTolerance = Duration(minutes: 10);

  /// Pure data/logic — no `BuildContext`. Callers (the activity form
  /// screens) show [AttendanceWindowValidationResult.failureMessage] via
  /// their own snackbar when [AttendanceWindowValidationResult.isValid] is
  /// false. Replaces the old `activity_attendance_window_validator.dart`
  /// free function, which resolved `StorageService` and three attendance
  /// use-cases via `serviceLocator` directly from presentation code.
  Future<AttendanceWindowValidationResult>
  validateStudentsWithinAttendanceWindow({
    required List<Map<String, dynamic>> students,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
  }) async {
    if (students.isEmpty) return const AttendanceWindowValidationResult.valid();
    if (selectedDate == null || selectedTime == null) {
      return const AttendanceWindowValidationResult.valid();
    }
    final instantUtc = SchoolZoneDateTime.resolvePickedInstantUtc(
      ServerTimeService.instance.schoolTimeZone,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
    );
    // Always validate attendance against API, including "current minute"/
    // today. This guarantees latest sign-in state is checked on every submit
    // attempt.
    final classroomCode = _resolveClassroomCodeFromSelectedStudents(students);
    if (classroomCode.isEmpty) {
      return const AttendanceWindowValidationResult.valid();
    }

    final shouldValidateStaff = await _shouldRunStaffAtTimeValidation();
    final staffCode = (await resolveStaffCode() ?? '').trim();
    if (shouldValidateStaff && staffCode.isNotEmpty) {
      try {
        final staffStatus = await _getStaffSignInStatusAtTimeUseCase(
          staffCodes: <String>[staffCode],
          classroomCode: classroomCode,
          instantUtc: instantUtc,
        );
        final isStaffPresent = staffStatus[staffCode] == true;
        if (!isStaffPresent) {
          return const AttendanceWindowValidationResult.invalid(
            'The following staff must be signed in before creating the activity.',
          );
        }
      } catch (_) {
        return const AttendanceWindowValidationResult.invalid(
          'The following staff must be signed in before creating the activity.',
        );
      }
    }

    final studentCodes = students
        .map((s) => (s['studentCode'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);
    final studentNameByCode = <String, String>{
      for (final s in students)
        (s['studentCode'] ?? '').toString().trim():
            (s['name'] ?? 'Selected student').toString().trim(),
    };
    final ambiguousClassroomStudentCodes = <String>{
      for (final s in students)
        if (s['classroomCodeAmbiguousForDate'] == true)
          (s['studentCode'] ?? '').toString().trim(),
    };

    if (studentCodes.isNotEmpty) {
      try {
        final studentStatus = await _getStudentSignInStatusAtTimeUseCase(
          studentCodes: studentCodes,
          classroomCode: classroomCode,
          instantUtc: instantUtc,
        );
        var notSignedInCodes = <String>[
          for (final code in studentCodes)
            if (studentStatus[code] != true) code,
        ];

        // The classroom-scoped check above can false-positive for a student
        // who was transferred to another classroom but never signed out:
        // their active sign-in record may still be keyed to the OLD
        // classroom, so a query scoped to the (new) classroomCode finds
        // nothing. For effectively-"now" submissions, re-check those
        // specific students with a classroom-agnostic "today" status before
        // blocking them.
        //
        // This fallback only proves the student is signed in SOMEWHERE, not
        // in `classroomCode` specifically — safe only when `classroomCode`
        // was the student's sole classroom that day. When the student had
        // more than one classroom stint that day (a same-day transfer),
        // applying it would wrongly clear a student who is legitimately no
        // longer in the OLD classroom being posted to, defeating the very
        // check this validator exists for. Those students stay excluded
        // from the fallback and are left to the stricter scoped result.
        final fallbackEligibleCodes = notSignedInCodes
            .where((code) => !ambiguousClassroomStudentCodes.contains(code))
            .toList(growable: false);
        if (fallbackEligibleCodes.isNotEmpty &&
            instantUtc.difference(ServerTimeService.instance.nowUtc()).abs() <=
                _fallbackSignInCheckTolerance) {
          try {
            final fallbackStatus = await _getStudentTodaySignInStatusMapUseCase(
              studentCodes: fallbackEligibleCodes,
            );
            notSignedInCodes = notSignedInCodes
                .where(
                  (code) =>
                      !fallbackEligibleCodes.contains(code) ||
                      fallbackStatus[code]?.toUpperCase() != 'SIGNED_IN',
                )
                .toList(growable: false);
          } catch (e) {
            AppLogger.d(
              'validateStudentsWithinAttendanceWindow: today-status fallback failed, keeping scoped result: $e',
            );
          }
        }

        final notSignedInNames = <String>[
          for (final code in notSignedInCodes)
            (studentNameByCode[code] == null ||
                    studentNameByCode[code]!.isEmpty)
                ? 'Selected student'
                : studentNameByCode[code]!,
        ];
        if (notSignedInNames.isNotEmpty) {
          return AttendanceWindowValidationResult.invalid(
            'Student(s) must be signed in at the time of posting the activity in this classroom:\n${notSignedInNames.join(', ')}',
          );
        }
      } catch (_) {
        return const AttendanceWindowValidationResult.invalid(
          'Student(s) must be signed in at the time of posting the activity in this classroom.',
        );
      }
    }
    return const AttendanceWindowValidationResult.valid();
  }

  /// True when it's safe to submit — either this isn't an admin-on-behalf-of
  /// create at all, or the picked staff member is confirmed signed in today.
  /// Admins are never gated on their OWN sign-in, only on who they're
  /// attributing the activity to; a failed status check is best-effort and
  /// doesn't block the admin (matches the original inline behaviour this
  /// replaces across all 9 activity-type screens).
  Future<bool> verifyPickedStaffSignedIn({
    required bool isEdit,
    required bool isAdminDesignation,
    required String? pickedStaffCode,
    required String? ownStaffCode,
  }) async {
    if (isEdit || !isAdminDesignation) return true;
    final picked = (pickedStaffCode ?? '').trim();
    final own = (ownStaffCode ?? '').trim();
    if (picked.isEmpty || picked == own) return true;
    try {
      final status = await _getStaffTodaySignInStatusUseCase(staffCode: picked);
      return status?.toUpperCase() == 'SIGNED_IN';
    } catch (_) {
      return true;
    }
  }

  /// Logged-in staff/session context (name, code, school/org, active role) —
  /// identical for every activity-type screen, so it's fetched here once
  /// instead of each of the nine screens independently resolving it from
  /// `serviceLocator<StorageService>()` via a copy-pasted `_loadStaffContext`.
  ///
  /// Returns a value rather than emitting it as cubit state: this cubit is a
  /// stateless data facade (see [ActivityEditorState]) — the calling screen
  /// still owns its own field/UI state, same as everything else it fetches
  /// through this cubit.
  Future<StaffContext> loadStaffContext() async {
    final staffType = (await _storage.getString(StorageKeys.staffType) ?? '')
        .trim();
    final schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final staffCode = await resolveStaffCode();
    final apiDisplayName = await resolveStaffDisplayName(staffCode: staffCode);
    final userCode = (await _storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final activeRole = await resolveActiveBackendRole(_storage);

    return StaffContext(
      staffName: apiDisplayName.isNotEmpty ? apiDisplayName : 'Staff',
      staffType: staffType.toUpperCase(),
      staffCode: staffCode,
      staffPresentCode: (staffCode ?? '').trim().isEmpty
          ? null
          : staffCode!.trim(),
      schoolCode: schoolCode.isNotEmpty ? schoolCode : null,
      organizationCode: organizationCode.isNotEmpty ? organizationCode : null,
      currentUserCode: userCode.isNotEmpty ? userCode : null,
      currentUserRole: activeRole.trim().isNotEmpty
          ? activeRole.trim().toUpperCase()
          : null,
    );
  }

  /// School IANA timezone for the currently active school — used by the
  /// date/time fields to resolve a school-local default. Every activity-type
  /// screen using [DateWidget]/[TimeWidget] already has this cubit provided
  /// by the router before its widget tree builds, so those widgets call this
  /// instead of resolving `StorageService`/`ApiClient` themselves.
  Future<String> resolveSchoolTimezone() =>
      SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

  /// Warms [SchoolTimezoneResolver.lastKnownTimeZone] so the synchronous
  /// [activityDateTimeForDisplayFromIso] helper (in `activity_school_time.dart`)
  /// has a resolved zone available. Discards the result — callers that need
  /// the zone value itself should call [resolveSchoolTimezone] directly.
  Future<void> bootstrapSchoolTimezone() async {
    await resolveSchoolTimezone();
  }

  /// The UTC instant for a school-local wall-clock date/time picked on an
  /// activity form, as an ISO 8601 string.
  Future<String> activityUtcIsoFromSchoolWallClock({
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final schoolTimeZone = await resolveSchoolTimezone();
    return SchoolZoneDateTime.resolvePickedInstantUtc(
      schoolTimeZone,
      selectedDate: date,
      selectedTime: time,
    ).toIso8601String();
  }

  /// The resolved instant for a picked activity date/time, alongside the
  /// school-local "HH:mm:ss" string derived from that SAME instant — both
  /// come from one [SchoolZoneDateTime.resolvePickedInstantUtc] call, so the
  /// top-level `activityDate` ISO value and the `time` parameter value sent
  /// in the payload can never disagree.
  Future<ActivityResolvedTime> resolveActivityDateTime({
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final schoolTimeZone = await resolveSchoolTimezone();
    final utcInstant = SchoolZoneDateTime.resolvePickedInstantUtc(
      schoolTimeZone,
      selectedDate: date,
      selectedTime: time,
    );
    final localDateTime = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      utcInstant,
      schoolTimeZone,
    );
    String two(int v) => v.toString().padLeft(2, '0');
    return ActivityResolvedTime(
      utcInstant: utcInstant,
      iso: utcInstant.toIso8601String(),
      localTimeHms:
          '${two(localDateTime.hour)}:${two(localDateTime.minute)}:${two(localDateTime.second)}',
    );
  }

  /// Student maps from the classroom/Students tab omit `attendanceDate`; the
  /// Activities picker includes it. Backfills it with today's date in the
  /// school's own calendar, resolved after [bootstrapSchoolTimezone] so
  /// [attendanceDateYyyyMmDdSchoolToday] uses the right zone.
  Future<void> ensureAttendanceDateOnStudentMapsForSchoolToday(
    List<Map<String, dynamic>> maps,
  ) async {
    await bootstrapSchoolTimezone();
    final dateStr = attendanceDateYyyyMmDdSchoolToday();
    for (final m in maps) {
      if ((m['attendanceDate'] ?? '').toString().trim().isEmpty) {
        m['attendanceDate'] = dateStr;
      }
    }
  }

  /// The logged-in staff member's own code, straight off storage — used by
  /// [StaffPresentWidget] to check "did the admin pick themselves" (which is
  /// never gated on sign-in status). Deliberately narrower than
  /// [loadStaffContext]'s `staffCode` (which goes through
  /// [resolveLoggedInStaffCode]'s extra fallbacks) — this preserves the exact
  /// raw-storage-read behavior the widget had before this migration.
  Future<String> getOwnStaffCode() async =>
      (await _storage.getString(StorageKeys.staffCode) ?? '').trim();

  /// Today's sign-in status for a specific (usually admin-picked) staff code.
  Future<String?> getStaffTodaySignInStatus({required String staffCode}) =>
      _getStaffTodaySignInStatusUseCase(staffCode: staffCode);

  /// Active staff directory for the current org/school — cache-first via
  /// [StaffRepositoryWithCache] when available, falling back to a live page
  /// fetch. Returns `null` (distinct from an empty list) when org/school
  /// aren't resolved yet, so a caller can tell "not ready" apart from "fetched
  /// successfully, zero active staff". A fetch failure propagates so callers
  /// keep their own existing fallback behavior (e.g. [StaffPresentWidget]
  /// silently keeps showing just the logged-in staff member on error).
  Future<List<StaffMember>?> loadActiveStaffDirectory() async {
    final org = (await _storage.getString(StorageKeys.organizationCode) ?? '')
        .trim();
    final school = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (org.isEmpty || school.isEmpty) return null;

    if (_staffRepository is StaffRepositoryWithCache) {
      try {
        final cached = await (_staffRepository as StaffRepositoryWithCache)
            .loadCachedStaffPage(school, status: 'ACTIVE');
        if (cached != null && cached.items.isNotEmpty) return cached.items;
      } catch (e) {
        AppLogger.d('loadActiveStaffDirectory: cached-page read failed, falling back to network: $e');
      }
    }

    final page = await _getStaffPageUseCase(
      organizationCode: org,
      schoolCode: school,
      page: 0,
      size: 300,
      status: 'ACTIVE',
    );
    return page.items;
  }

  /// Storage key for the photo/video "pending upload processing poll"
  /// mechanism below — one in-flight poll at a time, disambiguated internally
  /// by the JSON payload's own `mediaType` field (not by key variation).
  static const String _pendingUploadPollStorageKey =
      'activity_media_pending_upload_poll_v1';

  /// Raw JSON blob for a pending photo/video upload-processing poll that was
  /// still in flight when the screen was last left (e.g. app backgrounded
  /// mid-upload) — `null` when there is none. Used by [PhotoVideoActivityScreen]
  /// to resume watching an upload session instead of losing track of it.
  Future<String?> getPendingUploadPoll() =>
      _storage.getString(_pendingUploadPollStorageKey);

  Future<void> savePendingUploadPoll(String jsonValue) =>
      _storage.saveString(_pendingUploadPollStorageKey, jsonValue);

  Future<void> clearPendingUploadPoll() =>
      _storage.remove(_pendingUploadPollStorageKey);
}

/// Stateless marker state — this cubit is a data facade; the forms keep their
/// own field/UI state.
class ActivityEditorState extends Equatable {
  const ActivityEditorState();

  @override
  List<Object?> get props => const <Object?>[];
}
