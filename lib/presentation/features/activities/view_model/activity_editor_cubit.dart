import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/user_details_school_roles.dart';
import 'package:wowcare/presentation/features/activities/utils/resolve_logged_in_staff_code.dart';
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
import 'package:wowcare/domain/features/activity/usecases/reject_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/update_activity_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
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
    required GetStaffTodaySignInStatusUseCase getStaffTodaySignInStatusUseCase,
    required StorageService storageService,
    required UploadActivityAssetsUseCase uploadActivityAssetsUseCase,
    required GetActivityUploadAssetStatusesUseCase
        getActivityUploadAssetStatusesUseCase,
    required ApiClient apiClient,
    required StaffRepository staffRepository,
    required GetStaffPageUseCase getStaffPageUseCase,
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
        _getStaffTodaySignInStatusUseCase = getStaffTodaySignInStatusUseCase,
        _storage = storageService,
        _uploadActivityAssetsUseCase = uploadActivityAssetsUseCase,
        _getActivityUploadAssetStatusesUseCase =
            getActivityUploadAssetStatusesUseCase,
        _apiClient = apiClient,
        _staffRepository = staffRepository,
        _getStaffPageUseCase = getStaffPageUseCase,
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
  final GetStaffTodaySignInStatusUseCase _getStaffTodaySignInStatusUseCase;
  final StorageService _storage;
  final UploadActivityAssetsUseCase _uploadActivityAssetsUseCase;
  final GetActivityUploadAssetStatusesUseCase
      _getActivityUploadAssetStatusesUseCase;
  final ApiClient _apiClient;
  final StaffRepository _staffRepository;
  final GetStaffPageUseCase _getStaffPageUseCase;

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
    bool? napReminderEnabled,
    String? napReminderUserCode,
    String? napReminderRole,
    bool? requireAdminApproval,
    List<ActivityParameterValue> parameterValues = const [],
    List<ActivityAttachment> attachments = const [],
  }) =>
      _singleFlight(
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
  }) =>
      _singleFlight(
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
  }) =>
      _singleFlight(
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
    CancelToken? cancelToken,
  }) =>
      _uploadActivityAssetsUseCase(
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
        cancelToken: cancelToken,
      );

  /// One-shot status read — the photo/video form's background-poll strategy
  /// for assets still processing after upload.
  Future<Map<String, String>> getActivityUploadAssetStatuses({
    required String sessionCode,
    required List<String> assetCodes,
  }) =>
      _getActivityUploadAssetStatusesUseCase(
        sessionCode: sessionCode,
        assetCodes: assetCodes,
      );

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
      final status =
          await _getStaffTodaySignInStatusUseCase(staffCode: picked);
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
    final staffCode = await resolveLoggedInStaffCode();
    final apiDisplayName = await resolveLoggedInStaffDisplayNameFromApi(
      staffCode: staffCode,
    );
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
    final org =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (org.isEmpty || school.isEmpty) return null;

    if (_staffRepository is StaffRepositoryWithCache) {
      try {
        final cached =
            await (_staffRepository as StaffRepositoryWithCache)
                .loadCachedStaffPage(school, status: 'ACTIVE');
        if (cached != null && cached.items.isNotEmpty) return cached.items;
      } catch (_) {}
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
