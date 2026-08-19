import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/nap_activity.dart';
import 'package:wowcare/presentation/features/activities/widgets/avtivity_media_preview.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

import '../../../../app/di/di.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/guardian_code_resolver.dart';
import '../../../../core/util/activity_feed_invalidation.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/staff_code_resolver.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/school_timezone_resolver.dart';
import '../../../../core/util/school_zone_datetime.dart';
import '../../../../domain/features/activity/entities/activity_detail.dart';
import '../../../../domain/features/activity/entities/activity_feed_row.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/usecases/get_active_activity_types_for_school_usecase.dart';
import '../cubit/activity_moderation_cubit.dart';
import '../../../../domain/features/activity/usecases/get_daily_activity_feed_usecase.dart';
import '../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_codes_for_activity_tag_filter_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../../../../shared/common/app/cubit/role_cubit.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/student_attendance_absent_form.dart'
    hide StudentAttendanceTime;
import '../../../../domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_student_absent_records_activity_usecase.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../util/activity_filter_metadata_cache.dart';
import '../widgets/activity_feed_student_avatar.dart';
import 'activity_filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';
import '../util/activity_parent_feed_merge.dart';
import '../utils/activity_staff_display.dart';
import '../utils/activity_patch_attachments.dart';
import 'activity_feed_card_permissions.dart';
import 'activity_item.dart';

export 'activity_item.dart';
export 'activity_feed_card_permissions.dart';
export '../utils/activity_patch_attachments.dart'
    show attachmentUsableDeliveryUrl, attachmentRowHasUsableMedia;

bool activityHasMediaOrProcessing(ActivityItem activity) {
  final photo = (activity.photoUrl ?? '').trim();
  final video = (activity.videoUrl ?? '').trim();
  if (photo.isNotEmpty || video.isNotEmpty) return true;
  final attachments =
      activity.snapshotAttachments ?? const <Map<String, dynamic>>[];
  for (final row in attachments) {
    final status = (row['status'] ?? '').toString().trim().toUpperCase();
    if (status == 'PROCESSING' || status == 'UPLOADED' || status == 'PENDING') {
      return true;
    }
    final anyUrl =
        (row['deliveryUrl'] ??
                row['thumbnailUrl'] ??
                row['artifactUrl'] ??
                row['originalDownloadUrl'] ??
                '')
            .toString()
            .trim();
    if (anyUrl.isNotEmpty) return true;
  }
  return false;
}

class ActivityDailyTab extends StatefulWidget {
  const ActivityDailyTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.studentProfile,
    this.isNotParent = true,
    this.allowActivityWrite = true,
    this.highlightCode,
    this.highlightDate,
    this.highlightClassroomCode,
    this.onRefreshStaffSignInStatus,
  });

  /// Activity code from a notification deep-link; the matching feed card is
  /// scrolled into view and briefly flashed.
  final String? highlightCode;

  /// Date of the deep-linked activity (yyyy-MM-dd) so the feed opens on that
  /// day rather than today — otherwise the highlighted card isn't in view.
  final DateTime? highlightDate;

  /// Classroom of the deep-linked activity. The feed loads ONE classroom at a
  /// time, so without selecting this room the target card isn't in the list and
  /// the highlight silently no-ops.
  final String? highlightClassroomCode;

  final bool fromStudentProfile;

  /// Display name when opened from student profile.
  final String? studentName;

  /// Optional map (e.g. `name`, `studentCode`) when opened from student profile.
  final Map<String, dynamic>? studentProfile;
  final bool isNotParent;

  /// Edit / delete / add; false when [DAILY_ACTIVITY] has `write: false`.
  final bool allowActivityWrite;

  /// Re-checks the staff persona's today sign-in status (drives the parent
  /// screen's Add-activity FAB gate). Invoked on manual pull-to-refresh so the
  /// FAB reflects a sign-in/out done elsewhere without needing an app restart.
  final Future<void> Function()? onRefreshStaffSignInStatus;

  static const String routeName = '/activityDailyTab';

  @override
  State<ActivityDailyTab> createState() => _ActivityDailyTabState();
}

class _ActivityDailyTabState extends State<ActivityDailyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Notification deep-link target activity; applied once (scroll + flash).
  final GlobalKey _highlightCardKey = GlobalKey();
  bool _highlightApplied = false;
  bool _isHighlightTarget(String? code) {
    final target = (widget.highlightCode ?? '').trim();
    final c = (code ?? '').trim();
    return target.isNotEmpty && c.toUpperCase() == target.toUpperCase();
  }

  //final TextEditingController _searchController = TextEditingController();
  late bool isNotParent;
  bool get _parentHome => !isNotParent && !widget.fromStudentProfile;

  DateTime? _selectedDate = AppTime.now();
  String _schoolIana = SchoolTimezoneResolver.fallbackTimeZone;
  String? _selectdClassroom;
  String? _selectedStudent;
  List<String> _selectedClassrooms = [];
  List<String> _selectedStudents = [];
  List<String> _availableStudents = [];
  List<String> _filterTags = [];
  List<String> _filterActivityTypes = [];
  List<String> _filterApprovalStatuses = [];
  String? _selectedActivityType;
  final List<String> activityType = [
    'Sign-in',
    'Sign-out',
    'Transfer',
    'Marked Absent',
  ];
  List<String> _classroomOptions = [];
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _classroomNameByCode = {};
  final Map<String, String> _studentCodeByName = {};
  final Map<String, List<String>> _classroomStudents = {};
  List<ActivityItem> _activities = [];
  static const int _feedPageSize = 10;
  final ScrollController _feedScrollController = ScrollController();
  bool _feedHasMore = false;
  bool _loadingMoreFeed = false;
  int _feedNextPage = 0;
  bool _loadingFeed = false;
  bool _isFeedRequestInFlight = false;
  String? _lastFeedRequestKey;
  DateTime? _lastFeedCompletedAt;
  bool _lastFeedCompletedWithError = false;
  String? _feedError;
  String? _schoolCode;

  /// Logged-in user's display name; used when feed [createdBy] is "system", etc.
  String _viewerStaffDisplayName = '';
  String _viewerStaffCode = '';
  final Map<String, String> _staffDisplayNameByCode = {};
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  Map<String, String> _tagNameToCode = {};
  final Set<String> _studentCodesForTagFilter = {};

  /// Guardian home: children we may show activities for.
  final Set<String> _parentAllowedStudentCodes = {};
  final Map<String, String> _parentStudentClassroomByCode = {};

  // Staff persona scoping
  List<String> _allowedClassroomCodes = const [];
  String? _primaryClassroomCode;
  bool _loadingParentContext = false;
  String? _lastGlobalSelectedStudentCode;

  late final GetDailyActivityFeedUseCase _getDailyActivityFeedUseCase;
  late final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  late final GetActiveActivityTypesForSchoolUseCase
  _getActiveActivityTypesForSchoolUseCase;
  late final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  late final GetTagNameCodeMapForSchoolUseCase
  _getTagNameCodeMapForSchoolUseCase;
  late final GetStudentCodesForActivityTagFilterUseCase
  _getStudentCodesForActivityTagFilterUseCase;
  late final GetStudentPageUseCase _getStudentPageUseCase;
  late final GetStudentAttendanceDailyUseCase _getStudentAttendanceDailyUseCase;
  late final GetStudentAbsentRecordsActivityUseCase
  _getStudentAbsentRecordsActivityUseCase;
  late final ActivityModerationCubit _moderationCubit;
  StreamSubscription<ActivityModerationState>? _moderationSub;
  late final StorageService _storageService;
  late final CacheManager _cacheManager;
  StreamSubscription<void>? _feedInvalidationSub;
  bool _isAdminPersona = false;

  final List<Color> _colorPalette = [
    const Color(0xFFB3E5FC),
    const Color(0xFFFFCCBC),
    const Color(0xFFC8E6C9),
    const Color(0xFFFFE0B2),
    //const Color(0xFFFFF9C4),
    const Color(0xFFE1BEE7),
    //const Color(0xFFCCFF90),
    const Color(0xFF80DEEA),
    const Color(0xFFD1C4E9),
    const Color(0xFFFFAB91),
  ];
  // final List<String> _allStudents = [
  //   'Raghave Gupta',
  //   'Rohan Gupta',
  //   'Ruhi Gupta',
  //   'Anya Mehta',
  //   'Kabir Mehta',
  //   'Sara Khan',
  // ];
  // Map activity label to the destination edit activity screen
  static final Map<String, Widget Function(ActivityItem)> editActivityRoutes = {
    'Nap Start': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Nap End': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Bathroom': (activity) =>
        BathroomActivityScreen(activityData: activity, isEdit: true),
    'Bottle': (activity) =>
        BottleActivityScreen(activityData: activity, isEdit: true),
    'Meal': (activity) =>
        MealActivityScreen(activityData: activity, isEdit: true),
    'Incident': (activity) =>
        IncidentActivityScreen(activityData: activity, isEdit: true),
    'Photo': (activity) => PhotoVideoActivityScreen(
      activityData: activity,
      isEdit: true,
      isPhoto: true,
    ),
    'Video': (activity) => PhotoVideoActivityScreen(
      activityData: activity,
      isEdit: true,
      isPhoto: false,
    ),
    'Medication': (activity) =>
        MedicationActivityScreen(activityData: activity, isEdit: true),
    'Notes': (activity) =>
        NotesActivityScreen(activityData: activity, isEdit: true),
    'Outdoor': (activity) =>
        OutdoorActivityScreen(activityData: activity, isEdit: true),
    'Learning': (activity) =>
        LearningActivityScreen(activityData: activity, isEdit: true),
  };

  /// View: same screens as edit, read-only.
  static final Map<String, Widget Function(ActivityItem)> activityRoutes = {
    'Nap Start': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true, readOnly: true),
    'Nap End': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true, readOnly: true),
    'Bathroom': (activity) => BathroomActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Bottle': (activity) => BottleActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Meal': (activity) => MealActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Incident': (activity) => IncidentActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Photo': (activity) => PhotoVideoActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
      isPhoto: true,
    ),
    'Video': (activity) => PhotoVideoActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
      isPhoto: false,
    ),
    'Medication': (activity) => MedicationActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Notes': (activity) => NotesActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Outdoor': (activity) => OutdoorActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
    'Learning': (activity) => LearningActivityScreen(
      activityData: activity,
      isEdit: true,
      readOnly: true,
    ),
  };

  static final Map<String, dynamic> activityIcons = {
    'Nap Start': MediaRes.napActivityIcon,
    'Nap End': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
    'Sign-in': MediaRes.dailyActivitySignInIcon,
    'Sign-out': MediaRes.dailyActivitySignOutIcon,
    'Transfer': MediaRes.dailyActivityTransferIcon,
    'Marked Absent': MediaRes.dailyActivityAbsentIcon,
    'Absent': MediaRes.dailyActivityAbsentIcon,
  };

  Future<void> _onRefresh() async {
    // Hard-reset de-dupe guards so manual refresh always re-fetches.
    _lastFeedRequestKey = null;
    _lastFeedCompletedAt = null;
    _lastFeedCompletedWithError = true;

    // Re-check the staff sign-in gate in parallel: pull-to-refresh should
    // also flip the Add-activity FAB after a sign-in/out done on another
    // screen, not just the feed contents.
    final refreshStaffSignInStatus = widget.onRefreshStaffSignInStatus;
    if (refreshStaffSignInStatus != null) {
      unawaited(refreshStaffSignInStatus());
    }

    // Force refresh of metadata + feed.
    // Also bust staff dropdown cache so edit screens refetch staff list.
    try {
      final org =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final school =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      if (org.isNotEmpty && school.isNotEmpty) {
        final staffKey = CacheManager.buildCacheKey(
          feature: 'staff',
          resource: 'list',
          identifier: '${org}_$school',
        );
        await _cacheManager.invalidateCache(staffKey);
      }
    } catch (_) {}
    if (_parentHome) {
      await _bootstrapParentHome();
      await _loadTagFilterOptions(forceRefresh: true);
      // Parent bootstrap already calls _loadDailyFeed(refresh: true).
      return;
    }
    await _reloadStudentsAndSettingsThenFeed(forceRefreshApis: true);
  }

  String _dateQueryParam(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String? _activityTypeCodeForLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    for (final s in _classroomActivitySettings) {
      if (_filterLabelMatchesSetting(label, s.activityTypeName)) {
        return s.activityTypeCode;
      }
    }
    return null;
  }

  /// Multi-select aware API payload for `activityTypeCode[]`.
  List<String>? _activityTypeCodesForApiFilter() {
    final codes = <String>{};
    if (_filterActivityTypes.isNotEmpty) {
      for (final label in _filterActivityTypes) {
        final code = _activityTypeCodeForLabel(label);
        if (code != null && code.trim().isNotEmpty) {
          codes.add(code.trim());
        }
      }
      return codes.isEmpty ? null : codes.toList();
    }
    final selectedCode = _activityTypeCodeForLabel(_selectedActivityType);
    if (selectedCode != null && selectedCode.trim().isNotEmpty) {
      return <String>[selectedCode.trim()];
    }
    return null;
  }

  List<String>? _approvalStatusesForApiFilter() {
    if (_filterApprovalStatuses.isEmpty) return null;
    const statusCodeByLabel = <String, String>{
      'pending admin approval': 'PENDING_ADMIN_APPROVAL',
      'approved': 'APPROVED',
      'rejected': 'REJECTED',
      'parent acknowledgement pending': 'PARENT_ACKNOWLEDGEMENT_PENDING',
      'parent acknowledgment pending': 'PARENT_ACKNOWLEDGEMENT_PENDING',
      'acknowledged': 'ACKNOWLEDGED',
    };
    const allowedEnums = <String>{
      'PENDING_ADMIN_APPROVAL',
      'APPROVED',
      'REJECTED',
      'PARENT_ACKNOWLEDGEMENT_PENDING',
      'ACKNOWLEDGED',
    };
    final out = <String>{};
    for (final label in _filterApprovalStatuses) {
      final normalizedLabel = label.trim().toLowerCase();
      final fromLabel = statusCodeByLabel[normalizedLabel];
      if (fromLabel != null && fromLabel.isNotEmpty) {
        out.add(fromLabel);
        continue;
      }
      final enumLike = label.trim().toUpperCase().replaceAll(' ', '_');
      if (allowedEnums.contains(enumLike)) {
        out.add(enumLike);
      }
    }
    return out.isEmpty ? null : out.toList();
  }

  Set<String> _selectedApprovalStatusCodesForUi() {
    return (_approvalStatusesForApiFilter() ?? const <String>[])
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  int _appliedFilterBadgeCount() {
    final hasActivityTypeFilter = _filterActivityTypes.isNotEmpty;
    final hasTagFilter = _filterTags.isNotEmpty;
    final hasStatusFilter = _filterApprovalStatuses.isNotEmpty;
    return (hasActivityTypeFilter ? 1 : 0) +
        (hasTagFilter ? 1 : 0) +
        (hasStatusFilter ? 1 : 0);
  }

  List<ActivityItem> _withClientFilters(List<ActivityItem> items) {
    var list = items;
    if (_filterActivityTypes.length > 1) {
      final codes = _filterActivityTypes
          .map(_activityTypeCodeForLabel)
          .whereType<String>()
          .toSet();
      final names = _filterActivityTypes
          .map((e) => e.trim().toLowerCase())
          .toSet();
      list = list.where((a) {
        final c = a.activityTypeCode?.trim();
        if (c != null && c.isNotEmpty && codes.contains(c)) return true;
        return names.contains(a.name.trim().toLowerCase());
      }).toList();
    }
    if (_filterTags.isNotEmpty) {
      list = list
          .where(
            (a) =>
                a.studentCode != null &&
                _studentCodesForTagFilter.contains(a.studentCode),
          )
          .toList();
    }
    if (_filterApprovalStatuses.isNotEmpty) {
      final selected = _selectedApprovalStatusCodesForUi();
      list = list.where((a) {
        final status = (a.approvalStatus ?? '').trim().toUpperCase();
        if (status.isEmpty) return false;
        return selected.contains(status);
      }).toList();
    }
    return list;
  }

  /// Tag-only subset of [_withClientFilters], for attendance-derived items
  /// (Sign-in/Sign-out/Marked Absent). Those rows carry no
  /// activityTypeCode/approvalStatus, so the other two filters in
  /// [_withClientFilters] don't apply to them — Activity Type filtering for
  /// them is already handled upstream at fetch time (see
  /// [_shouldIncludeAttendanceEntries]/[_selectedAttendanceEventFilter]),
  /// and approval status doesn't apply to attendance rows at all (see
  /// [_selectedAttendanceEventFilter]'s own doc). Without this, picking a
  /// Tag filter narrowed the regular activity feed to the tagged students
  /// but left every student's Sign-in/Sign-out/Marked Absent cards showing
  /// regardless of the tag.
  List<ActivityItem> _withTagFilterOnly(List<ActivityItem> items) {
    if (_filterTags.isEmpty) return items;
    return items
        .where(
          (a) =>
              a.studentCode != null &&
              _studentCodesForTagFilter.contains(a.studentCode),
        )
        .toList();
  }

  Future<void> _rebuildStudentCodesForTagFilter() async {
    _studentCodesForTagFilter.clear();
    if (_filterTags.isEmpty || !mounted) return;
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;

    final tagCodes = _filterTags
        .map((name) => _tagNameToCode[name]?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();
    if (tagCodes.isEmpty) return;

    try {
      if (_parentHome) {
        final classroomCodes = _parentStudentClassroomByCode.values
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        for (final cc in classroomCodes) {
          final students = await _getStudentCodesForActivityTagFilterUseCase(
            schoolCode: school,
            classroomCode: cc,
            tagCodes: tagCodes,
          );
          if (!mounted) return;
          _studentCodesForTagFilter.addAll(students);
        }
        return;
      }

      final classroomName = _selectdClassroom;
      if (classroomName == null ||
          !_classroomCodeByName.containsKey(classroomName)) {
        return;
      }
      final cc = _classroomCodeByName[classroomName]!;
      final students = await _getStudentCodesForActivityTagFilterUseCase(
        schoolCode: school,
        classroomCode: cc,
        tagCodes: tagCodes,
      );
      if (!mounted) return;
      _studentCodesForTagFilter.addAll(students);
    } catch (_) {
      if (mounted) _studentCodesForTagFilter.clear();
    }
  }

  bool _filterLabelMatchesSetting(String uiLabel, String settingName) {
    final u = uiLabel.toLowerCase().trim();
    final n = settingName.toLowerCase().trim();
    if (u.isEmpty || n.isEmpty) return false;
    if (u == n) return true;
    if (n.contains(u) || u.contains(n)) return true;
    final ua = u.split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
    final na = n.split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
    return ua.intersection(na).isNotEmpty;
  }

  Future<void> _bootstrap() async {
    final viewerName =
        (await _storageService.getString(StorageKeys.displayName) ?? '').trim();
    final viewerStaffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    final staffType =
        (await _storageService.getString(StorageKeys.staffType) ?? '')
            .trim()
            .toUpperCase();
    // Active-persona check (RoleCubit), not a scan of the account's full
    // cached roles list — that list always contains every role the account
    // has across every school, so a dual-role user (e.g. STAFF + SCHOOL_ADMIN
    // in a different school) would be misdetected as admin regardless of
    // which persona is actually active right now.
    final roleCubit = context.read<RoleCubit>();
    if (mounted) {
      setState(() {
        _viewerStaffDisplayName = viewerName;
        _viewerStaffCode = viewerStaffCode;
        _isAdminPersona =
            (roleCubit.isAdmin && !roleCubit.isStaff) ||
            staffType == 'SCHOOL_ADMIN' ||
            staffType == 'ORGANIZATION_ADMIN';
      });
    }

    final school =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (!mounted) return;
    if (school.isEmpty) {
      const msg = 'School is not selected.';
      setState(() {
        _feedError = msg;
        _classroomOptions = [];
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      return;
    }
    _schoolCode = school;

    if (_parentHome) {
      await _bootstrapParentHome();
      return;
    }

    await _loadStaffClassroomScope();

    final classroomCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'classrooms',
      identifier: school,
    );
    var hydratedClassroomsFromCache = false;
    try {
      final cached = await _cacheManager.loadCache(classroomCacheKey);
      if (cached != null && cached['classrooms'] is List) {
        final list = (cached['classrooms'] as List)
            .whereType<Map>()
            .map(
              (e) => <String, String>{
                'name': (e['name'] ?? '').toString(),
                'code': (e['code'] ?? '').toString(),
              },
            )
            .where((e) => e['name']!.isNotEmpty && e['code']!.isNotEmpty)
            .toList();
        if (list.isNotEmpty && mounted) {
          final scoped = _allowedClassroomCodes.isEmpty
              ? list
              : list
                    .where(
                      (c) => _allowedClassroomCodes.contains(
                        (c['code'] ?? '').trim(),
                      ),
                    )
                    .toList();
          _classroomCodeByName
            ..clear()
            ..addEntries(scoped.map((c) => MapEntry(c['name']!, c['code']!)));
          _classroomNameByCode
            ..clear()
            ..addEntries(scoped.map((c) => MapEntry(c['code']!, c['name']!)));
          setState(() {
            _classroomOptions = scoped.map((c) => c['name']!).toList()..sort();
            _feedError = null;
            if (_classroomOptions.isNotEmpty) {
              _applyDeepLinkClassroom();
              final keep =
                  _selectdClassroom != null &&
                  _classroomOptions.contains(_selectdClassroom);
              if (keep) {
                _selectdClassroom = _selectdClassroom;
              } else {
                final primaryCode = (_primaryClassroomCode ?? '').trim();
                final primaryName = primaryCode.isNotEmpty
                    ? _classroomNameByCode[primaryCode]
                    : null;
                // If the primary classroom is Office (filtered out of the
                // selectable list) or otherwise unavailable, fall back to the
                // top sorted classroom.
                _selectdClassroom =
                    (primaryName != null &&
                        _classroomOptions.contains(primaryName))
                    ? primaryName
                    : _classroomOptions.first;
              }
              // Keep multi-select UI in sync with default classroom.
              if (_selectdClassroom != null &&
                  _selectdClassroom!.trim().isNotEmpty) {
                _selectedClassrooms = <String>[_selectdClassroom!];
              }
            } else {
              _selectdClassroom = null;
              _selectedClassrooms = <String>[];
            }
          });
          hydratedClassroomsFromCache = _classroomOptions.isNotEmpty;
        }
      }
    } catch (_) {}

    // For unrestricted personas (admin), continue to API refresh so stale
    // staff-scoped cache cannot lock the dropdown.
    if (hydratedClassroomsFromCache &&
        mounted &&
        _allowedClassroomCodes.isNotEmpty) {
      await _loadDailyFeed(refresh: false);
      unawaited(
        _reloadStudentsAndSettings(forceRefreshApis: false).catchError((_) {}),
      );
      unawaited(_loadTagFilterOptions(forceRefresh: false).catchError((_) {}));
      return;
    }

    try {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: school,
        onlyTypeClassroom: true,
      );
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      var scoped = _allowedClassroomCodes.isEmpty
          ? classrooms
          : classrooms
                .where((c) => _allowedClassroomCodes.contains(c.code.trim()))
                .toList();
      if (scoped.isEmpty &&
          classrooms.isNotEmpty &&
          _allowedClassroomCodes.isNotEmpty) {
        // If staff-scope resolution failed/stale, avoid blocking classroom fetch.
        scoped = classrooms;
      }
      if (scoped.isEmpty) {
        if (!mounted) {
          _isFeedRequestInFlight = false;
          return;
        }
        setState(() {
          _classroomCodeByName.clear();
          _classroomNameByCode.clear();
          _classroomOptions = [];
          _selectdClassroom = null;
          _feedError = 'No classrooms found. Pull to refresh.';
        });
        _isFeedRequestInFlight = false;
        return;
      }
      _classroomCodeByName
        ..clear()
        ..addEntries(scoped.map((c) => MapEntry(c.name, c.code)));
      _classroomNameByCode
        ..clear()
        ..addEntries(scoped.map((c) => MapEntry(c.code, c.name)));
      setState(() {
        _classroomOptions = scoped.map((c) => c.name).toList()..sort();
        _feedError = null;
        if (_classroomOptions.isNotEmpty) {
          _applyDeepLinkClassroom();
          final keep =
              _selectdClassroom != null &&
              _classroomOptions.contains(_selectdClassroom);
          if (keep) {
            _selectdClassroom = _selectdClassroom;
          } else {
            final primaryCode = (_primaryClassroomCode ?? '').trim();
            final primaryName = primaryCode.isNotEmpty
                ? _classroomNameByCode[primaryCode]
                : null;
            // If the primary classroom is Office (filtered out of the
            // selectable list) or otherwise unavailable, fall back to the
            // top sorted classroom.
            _selectdClassroom =
                (primaryName != null && _classroomOptions.contains(primaryName))
                ? primaryName
                : _classroomOptions.first;
          }
          // Keep multi-select UI in sync with default classroom.
          if (_selectdClassroom != null &&
              _selectdClassroom!.trim().isNotEmpty) {
            _selectedClassrooms = <String>[_selectdClassroom!];
          }
        } else {
          _selectdClassroom = null;
          _selectedClassrooms = <String>[];
        }
      });
      await _cacheManager.saveCache(classroomCacheKey, {
        // Persist full school classrooms; apply staff scope only at runtime.
        'classrooms': classrooms
            .map((c) => {'name': c.name, 'code': c.code})
            .toList(),
      });
      await _loadDailyFeed(refresh: true);
      unawaited(_reloadStudentsAndSettings().catchError((_) {}));
      unawaited(_loadTagFilterOptions().catchError((_) {}));
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
    }
  }

  Future<void> _loadStaffClassroomScope() async {
    // Scope only applies to staff/teacher personas (not parent/guardian; not
    // admins). Checked against the ACTIVE persona (RoleCubit), not a scan of
    // the account's full cached roles list — a dual-role account (e.g.
    // STAFF + GUARDIAN in a different school) always has 'GUARDIAN' in that
    // list regardless of which persona is active right now.
    if (context.read<RoleCubit>().isParent) {
      _allowedClassroomCodes = const [];
      _primaryClassroomCode = null;
      return;
    }

    final staffType =
        (await _storageService.getString(StorageKeys.staffType) ?? '')
            .trim()
            .toUpperCase();
    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      _allowedClassroomCodes = const [];
      _primaryClassroomCode = null;
      return;
    }

    List<String> decodeCodes(String raw) {
      if (raw.trim().isEmpty) return <String>[];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return <String>[];
    }

    final cached =
        (await _storageService.getString(
                  StorageKeys.staffAllowedClassroomCodes,
                ) ??
                '')
            .trim();
    var allowed = decodeCodes(cached);

    try {
      final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      if (staffCode.isNotEmpty) {
        final repo = serviceLocator<StaffRepository>();
        final profile = await repo.getStaffProfile(
          staffCode: staffCode,
          forEditStaff: true,
        );
        final primary = profile.primaryClassroomCode.trim();
        final profileAllowed = profile.allowedClassroomCodes
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (profileAllowed.isNotEmpty) {
          allowed = profileAllowed;
          await _storageService.saveString(
            StorageKeys.staffAllowedClassroomCodes,
            jsonEncode(profileAllowed),
          );
        }

        _primaryClassroomCode = primary.isNotEmpty ? primary : null;
      }
    } catch (_) {
      // Non-blocking: fall back to cached allowed codes.
    }

    _allowedClassroomCodes = allowed;
  }

  Future<void> _bootstrapParentHome() async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;

    if (mounted) {
      setState(() {
        _loadingParentContext = true;
        _feedError = null;
      });
    }

    try {
      final guardianCode = await resolveGuardianCodeForLoggedInUser();
      if (guardianCode.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'Could not load guardian profile.';
            _parentAllowedStudentCodes.clear();
            _parentStudentClassroomByCode.clear();
            _loadingParentContext = false;
            _activities = [];
            _loadingFeed = false;
            _feedHasMore = false;
          });
        }
        return;
      }

      final page = await _getStudentPageUseCase(
        schoolCode: school,
        guardianCodes: [guardianCode],
        page: 0,
        size: 500,
      );
      if (!mounted) return;

      _parentAllowedStudentCodes.clear();
      _parentStudentClassroomByCode.clear();
      for (final s in page.items) {
        final code = s.code.trim();
        if (code.isEmpty) continue;
        final cc = s.classroom.trim();
        if (cc.isEmpty) continue;
        _parentAllowedStudentCodes.add(code);
        _parentStudentClassroomByCode[code] = cc;
      }

      // Parent UX: use the child currently selected in the global dropdown.
      final globalSelectedCode =
          (context.read<ParentChildCubit>().selectedChild?.code ?? '').trim();
      if (globalSelectedCode.isNotEmpty) {
        final selectedClassroom =
            _parentStudentClassroomByCode[globalSelectedCode];
        _parentAllowedStudentCodes
          ..clear()
          ..add(globalSelectedCode);
        _parentStudentClassroomByCode..clear();
        if (selectedClassroom != null && selectedClassroom.trim().isNotEmpty) {
          _parentStudentClassroomByCode[globalSelectedCode] = selectedClassroom
              .trim();
        }
        _lastGlobalSelectedStudentCode = globalSelectedCode;
      }

      if (_parentAllowedStudentCodes.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'No linked children with a classroom.';
            _loadingParentContext = false;
            _activities = [];
            _loadingFeed = false;
            _feedHasMore = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _loadingParentContext = false;
        });
      }
      await _loadDailyFeed(refresh: true);
    } catch (e) {
      if (!mounted) return;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
        _loadingParentContext = false;
        _parentAllowedStudentCodes.clear();
        _parentStudentClassroomByCode.clear();
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
    }
  }

  void _syncWithGlobalChildSelection() {
    if (!_parentHome) return;
    final globalSelectedCode =
        (context.read<ParentChildCubit>().selectedChild?.code ?? '').trim();
    if (globalSelectedCode.isEmpty) return;
    if (_lastGlobalSelectedStudentCode == globalSelectedCode) return;

    _lastGlobalSelectedStudentCode = globalSelectedCode;

    // If we don't have parent context yet (or classroom mapping for this child),
    // bootstrap first, then the feed load will be scoped to the selected child.
    if (_parentStudentClassroomByCode[globalSelectedCode] == null) {
      _bootstrapParentHome();
      return;
    }

    _parentAllowedStudentCodes
      ..clear()
      ..add(globalSelectedCode);

    _loadDailyFeed(refresh: true);
  }

  Future<void> _reloadStudentsAndSettings({
    bool forceRefreshApis = false,
  }) async {
    _studentCodeByName.clear();
    _classroomStudents.clear();
    _availableStudents = [];
    _classroomActivitySettings = [];

    final classroomName = _selectdClassroom;
    final school = _schoolCode;
    if (classroomName == null ||
        school == null ||
        school.isEmpty ||
        !_classroomCodeByName.containsKey(classroomName)) {
      if (mounted) {
        setState(() {
          _activities = [];
        });
      }
      return;
    }

    final code = _classroomCodeByName[classroomName]!;
    final studentsCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'students',
      identifier: code,
    );

    try {
      final settings =
          await ActivityFilterMetadataCache.loadSchoolActivityTypeSettingsForFilters(
            cacheManager: _cacheManager,
            useCase: _getActiveActivityTypesForSchoolUseCase,
            schoolCode: school,
            forceRefresh: forceRefreshApis,
          );
      if (!mounted) return;
      setState(() {
        _classroomActivitySettings = settings;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _classroomActivitySettings = [];
        });
      }
    }

    if (!forceRefreshApis) {
      try {
        final cachedStudents = await _cacheManager.loadCache(studentsCacheKey);
        if (cachedStudents != null &&
            cachedStudents['students'] is List &&
            mounted) {
          final list = (cachedStudents['students'] as List)
              .whereType<Map>()
              .map(
                (e) => <String, String>{
                  'fullName': (e['fullName'] ?? '').toString(),
                  'studentCode': (e['studentCode'] ?? '').toString(),
                },
              )
              .where(
                (e) =>
                    e['fullName']!.isNotEmpty && e['studentCode']!.isNotEmpty,
              )
              .toList();
          _studentCodeByName
            ..clear()
            ..addEntries(
              list.map((e) => MapEntry(e['fullName']!, e['studentCode']!)),
            );
          setState(() {
            _classroomStudents[classroomName] =
                list.map((e) => e['fullName']!).toList()..sort();
            _updateAvailableStudents();
          });
        }
      } catch (_) {}
    }

    try {
      final students = await _getStudentClassroomListUseCase(
        schoolCode: school,
        classroomCode: code,
        status: const ['ACTIVE'],
        refresh: forceRefreshApis,
      );
      if (!mounted) return;
      _studentCodeByName.addEntries(
        students.map((s) => MapEntry(s.fullName, s.studentCode)),
      );
      setState(() {
        _classroomStudents[classroomName] =
            students.map((s) => s.fullName).toList()..sort();
        _updateAvailableStudents();
      });
      await _cacheManager.saveCache(studentsCacheKey, {
        'students': students
            .map((s) => {'fullName': s.fullName, 'studentCode': s.studentCode})
            .toList(),
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableStudents = [];
        });
      }
    }
  }

  Future<void> _loadAllStudentsForAllowedClassrooms({
    bool forceRefreshApis = false,
  }) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty || _classroomOptions.isEmpty) return;

    final mergedByName = <String, String>{};
    final byClassroom = <String, List<String>>{};

    for (final classroomName in _classroomOptions) {
      final classroomCode = _classroomCodeByName[classroomName];
      if (classroomCode == null || classroomCode.trim().isEmpty) continue;
      try {
        final students = await _getStudentClassroomListUseCase(
          schoolCode: school,
          classroomCode: classroomCode,
          status: const ['ACTIVE'],
          refresh: forceRefreshApis,
        );
        final names = students.map((s) => s.fullName).toSet().toList()..sort();
        byClassroom[classroomName] = names;
        for (final s in students) {
          mergedByName[s.fullName] = s.studentCode;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _classroomStudents
        ..clear()
        ..addAll(byClassroom);
      _studentCodeByName
        ..clear()
        ..addAll(mergedByName);
      _availableStudents = mergedByName.keys.toSet().toList()..sort();
      _selectedStudents = _selectedStudents
          .where((name) => _availableStudents.contains(name))
          .toList();
      if (_selectedStudent != null &&
          !_availableStudents.contains(_selectedStudent)) {
        _selectedStudent = null;
      }
      _pinProfileStudent();
    });
  }

  Future<void> _loadStudentsForSelectedClassrooms(
    List<String> selectedClassroomNames, {
    bool forceRefreshApis = false,
  }) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty || selectedClassroomNames.isEmpty)
      return;

    final mergedByName = Map<String, String>.from(_studentCodeByName);
    final byClassroom = Map<String, List<String>>.from(_classroomStudents);

    for (final classroomName in selectedClassroomNames) {
      final classroomCode = _classroomCodeByName[classroomName];
      if (classroomCode == null || classroomCode.trim().isEmpty) continue;
      try {
        final students = await _getStudentClassroomListUseCase(
          schoolCode: school,
          classroomCode: classroomCode,
          status: const ['ACTIVE'],
          refresh: forceRefreshApis,
        );
        final names = students.map((s) => s.fullName).toSet().toList()..sort();
        byClassroom[classroomName] = names;
        for (final s in students) {
          mergedByName[s.fullName] = s.studentCode;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _classroomStudents
        ..clear()
        ..addAll(byClassroom);
      _studentCodeByName
        ..clear()
        ..addAll(mergedByName);
      _updateAvailableStudents();
    });
  }

  Future<void> _reloadStudentsAndSettingsThenFeed({
    bool forceRefreshApis = false,
  }) async {
    await _reloadStudentsAndSettings(forceRefreshApis: forceRefreshApis);
    if (forceRefreshApis) {
      await _loadTagFilterOptions(forceRefresh: true);
    }
    await _loadDailyFeed(refresh: true);
  }

  Future<void> _refreshDropdownsAfterClearAll() async {
    await _loadTagFilterOptions(forceRefresh: true);
    if (isNotParent) {
      await _loadAllStudentsForAllowedClassrooms(forceRefreshApis: true);
    }
  }

  List<ActivityItem> _mapDailyFeedPageToItems(ActivityFeedPage page) {
    final raw = page.content
        .map(
          (row) => activityItemFromFeedRow(
            row,
            // Guardian feed should not fallback to guardian display name as
            // "created by" when API returns system/staff-code placeholders.
            viewerDisplayName: _parentHome ? null : _viewerStaffDisplayName,
            schoolIana: _schoolIana,
            staffDisplayNameByCode: _staffDisplayNameByCode,
            activityTypeOptionCodeToLabel: activityFeedOptionLabelsForType(
              row.activityTypeCode,
            ),
          ),
        )
        .toList();
    return _withClientFilters(raw);
  }

  Future<void> _primeStaffDisplayNamesFromFeedRows(
    Iterable<ActivityFeedRow> rows,
  ) async {
    final missingCodes = <String>{};
    String? staffPresentCodeFromRow(ActivityFeedRow row) {
      for (final p in row.parameterValues) {
        final pName = (p['parameterName'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (pName != 'staff present') continue;
        final raw =
            (p['selectedOptionCode'] ??
                    p['valueText'] ??
                    p['valueNumber'] ??
                    '')
                .toString()
                .trim();
        if (raw.isNotEmpty) return raw;
      }
      return null;
    }

    for (final row in rows) {
      final codeCandidates = <String>{
        (row.staffCode ?? '').trim(),
        (staffPresentCodeFromRow(row) ?? '').trim(),
      };
      for (final code in codeCandidates) {
        if (code.isEmpty) continue;
        if (_staffDisplayNameByCode.containsKey(code)) continue;
        missingCodes.add(code);
      }
    }
    if (missingCodes.isEmpty) return;
    final repo = serviceLocator<StaffRepository>();
    await Future.wait(
      missingCodes.map((code) async {
        try {
          final profile = await repo.getStaffProfile(staffCode: code);
          final full = profile.fullName.trim();
          final composed = '${profile.firstName} ${profile.lastName}'.trim();
          final resolved = full.isNotEmpty ? full : composed;
          if (resolved.isNotEmpty) {
            _staffDisplayNameByCode[code] = resolved;
          }
        } catch (_) {}
      }),
    );
  }

  String? _selectedAttendanceEventFilter() {
    // Status filters apply to activity feed approvals only.
    // Attendance rows don't carry approval status, so exclude attendance API
    // when a status filter is active.
    if (_filterApprovalStatuses.isNotEmpty) return null;
    if (_filterActivityTypes.length == 1) {
      final v = _filterActivityTypes.first.trim();
      if (v == 'Sign-in' ||
          v == 'Sign-out' ||
          v == 'Transfer' ||
          v == 'Marked Absent') {
        return v;
      }
    }
    final v = _selectedActivityType?.trim();
    if (v == 'Sign-in' ||
        v == 'Sign-out' ||
        v == 'Transfer' ||
        v == 'Marked Absent') {
      return v;
    }
    return null;
  }

  bool _isAttendanceEventLabel(String value) {
    return value == 'Sign-in' ||
        value == 'Sign-out' ||
        value == 'Transfer' ||
        value == 'Marked Absent';
  }

  bool _isMarkedAbsentEvent(String? event) => event == 'Marked Absent';

  bool _shouldIncludeAttendanceEntries() {
    if (_filterActivityTypes.isNotEmpty) {
      return _filterActivityTypes
          .map((e) => e.trim())
          .any(_isAttendanceEventLabel);
    }
    final single = _selectedActivityType?.trim();
    if (single == null || single.isEmpty) return true;
    return _isAttendanceEventLabel(single);
  }

  List<String>? _selectedStudentCodesForAttendanceFilter() {
    if (widget.fromStudentProfile && widget.studentProfile != null) {
      final sc = widget.studentProfile!['studentCode'];
      if (sc is String && sc.trim().isNotEmpty) {
        return <String>[sc.trim()];
      }
    }
    final selectedNames = _selectedStudents.isNotEmpty
        ? _selectedStudents
        : ((_selectedStudent?.trim().isNotEmpty ?? false)
              ? <String>[_selectedStudent!.trim()]
              : const <String>[]);
    String codeForName(String name) {
      final exact = _studentCodeByName[name]?.trim() ?? '';
      if (exact.isNotEmpty) return exact;
      final needle = name.trim().toLowerCase();
      for (final entry in _studentCodeByName.entries) {
        if (entry.key.trim().toLowerCase() == needle) {
          final code = entry.value.trim();
          if (code.isNotEmpty) return code;
        }
      }
      return '';
    }

    final codes = selectedNames
        .map(codeForName)
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
    return codes.isEmpty ? null : codes;
  }

  List<String> _selectedClassroomCodesForFeed() {
    final selectedNames = _selectedClassrooms;
    final fromSelectedDropdown = selectedNames
        .map((name) => _classroomCodeByName[name]?.trim() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
    if (fromSelectedDropdown.isNotEmpty) return fromSelectedDropdown;

    final selectedSingle = (_selectdClassroom ?? '').trim();
    final singleCode = _classroomCodeByName[selectedSingle]?.trim() ?? '';
    if (singleCode.isNotEmpty) return <String>[singleCode];

    final selectedStudentNames = _selectedStudents.isNotEmpty
        ? _selectedStudents
        : ((_selectedStudent?.trim().isNotEmpty ?? false)
              ? <String>[_selectedStudent!.trim()]
              : const <String>[]);
    final fromSelectedStudents = _classroomStudents.entries
        .where(
          (entry) => selectedStudentNames.any(
            (studentName) => entry.value.contains(studentName),
          ),
        )
        .map((entry) => _classroomCodeByName[entry.key]?.trim() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
    if (fromSelectedStudents.isNotEmpty) return fromSelectedStudents;

    // Opened from a student profile: the profile passes the student's classroom
    // CODE directly. Use it as the final fallback so the feed resolves this
    // student's room even when the name→code maps / _classroomStudents haven't
    // populated yet (otherwise _loadDailyFeed early-returns an empty feed).
    if (widget.fromStudentProfile && widget.studentProfile != null) {
      final cc = widget.studentProfile!['classroomCode'];
      if (cc is String && cc.trim().isNotEmpty) {
        return <String>[cc.trim()];
      }
    }

    return const <String>[];
  }

  String _displayClassroomName({String? classroomCode, String? classroomName}) {
    final n = (classroomName ?? '').trim();
    if (n.isNotEmpty && !n.startsWith('CLS_')) return n;
    final c = (classroomCode ?? '').trim();
    if (c.isEmpty) return n;
    return _classroomNameByCode[c] ?? c;
  }

  DateTime? _attendanceClockToDateTime(StudentAttendanceTime? t, DateTime day) {
    if (t == null) return null;
    return DateTime(day.year, day.month, day.day, t.hour, t.minute, t.second);
  }

  DateTime? _absentClockToDateTime(dynamic t, DateTime day) {
    if (t == null) return null;
    final hour = (t.hour as int?) ?? 0;
    final minute = (t.minute as int?) ?? 0;
    final second = (t.second as int?) ?? 0;
    return DateTime(day.year, day.month, day.day, hour, minute, second);
  }

  DateTime? _tryParseDisplayDateTime(String dateRaw, String timeRaw) {
    final date = dateRaw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final time = timeRaw
        .trim()
        .replaceAll(RegExp(r'[\u00A0\u202F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (date.isEmpty || time.isEmpty) return null;

    DateTime day;
    try {
      day = DateFormat('MMMM d, yyyy').parseStrict(date);
    } catch (_) {
      return null;
    }

    final m = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][.]?[Mm][.]?)?$',
    ).firstMatch(time);
    if (m == null) return null;

    var hour = int.tryParse(m.group(1) ?? '') ?? 0;
    final minute = int.tryParse(m.group(2) ?? '') ?? 0;
    final second = int.tryParse(m.group(3) ?? '') ?? 0;
    final ampm = (m.group(4) ?? '').toUpperCase().replaceAll('.', '');

    if (ampm == 'AM') {
      if (hour == 12) hour = 0;
    } else if (ampm == 'PM') {
      if (hour < 12) hour += 12;
    }
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }
    return DateTime(day.year, day.month, day.day, hour, minute, second);
  }

  DateTime _activityItemSortDateTime(ActivityItem item) {
    final parsedDisplay = _tryParseDisplayDateTime(item.date, item.time);
    if (parsedDisplay != null) return parsedDisplay;

    final date = item.date.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (date.isNotEmpty) {
      try {
        return DateFormat('MMMM d, yyyy').parseStrict(date);
      } catch (_) {}
    }

    final iso = (item.activityDateIso ?? '').trim();
    if (iso.isNotEmpty) {
      try {
        return DateTime.parse(iso);
      } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _compareActivityItemsByTimeDesc(ActivityItem a, ActivityItem b) {
    final byTime = _activityItemSortDateTime(
      b,
    ).compareTo(_activityItemSortDateTime(a));
    if (byTime != 0) return byTime;
    return b.name.compareTo(a.name);
  }

  List<ActivityItem> _mapAttendanceDailyPageToItems(
    StudentAttendanceDailyPage page,
  ) {
    if (!_shouldIncludeAttendanceEntries()) return const <ActivityItem>[];
    final eventFilter = _selectedAttendanceEventFilter();
    final day = _selectedDate ?? AppTime.now();
    final selectedClassroomName = _selectdClassroom;
    final selectedClassroomCode = selectedClassroomName != null
        ? _classroomCodeByName[selectedClassroomName]
        : null;
    final out = <ActivityItem>[];
    for (final row in page.items) {
      final studentName = row.studentName.trim().isEmpty
          ? 'Student'
          : row.studentName.trim();
      final studentCode = row.studentCode?.trim();
      final baseClassName = _displayClassroomName(
        classroomCode: row.classroomCode,
        classroomName: row.classroomName,
      );
      if (row.isTransfer == true) {
        if (eventFilter == null || eventFilter == 'Transfer') {
          final at =
              _attendanceClockToDateTime(row.transferTime, day) ??
              _attendanceClockToDateTime(row.nextActionTime, day) ??
              day;
          final fromName = _displayClassroomName(
            classroomCode: row.fromClassroomCode,
            classroomName: row.fromClassroomName,
          );
          final toName = _displayClassroomName(
            classroomCode: row.toClassroomCode,
            classroomName: row.toClassroomName,
          );
          final fromCode = (row.fromClassroomCode ?? '').trim();
          final toCode = (row.toClassroomCode ?? '').trim();

          final selectedCode = (selectedClassroomCode ?? '').trim();
          final bool viewingFromClassroom =
              selectedCode.isNotEmpty &&
              fromCode.isNotEmpty &&
              selectedCode == fromCode;
          final bool viewingToClassroom =
              selectedCode.isNotEmpty &&
              toCode.isNotEmpty &&
              selectedCode == toCode;

          final String transferLine;
          if (viewingFromClassroom) {
            transferLine =
                'Transferred to ${toName.isEmpty ? 'classroom' : toName}';
          } else if (viewingToClassroom) {
            transferLine =
                'Transferred from ${fromName.isEmpty ? 'classroom' : fromName}';
          } else {
            transferLine =
                'Transferred from ${fromName.isEmpty ? 'classroom' : fromName} to ${toName.isEmpty ? 'classroom' : toName}';
          }

          out.add(
            ActivityItem(
              time: DateFormat.jm().format(at),
              date: DateFormat('MMMM d, yyyy').format(at),
              name: 'Transfer',
              description: transferLine,
              studentList: <String>[studentName],
              createdBy: (row.transferredBy ?? '').trim().isEmpty
                  ? _viewerStaffDisplayName
                  : row.transferredBy!.trim(),
              studentCode: studentCode?.isEmpty == true ? null : studentCode,
              classroomCode: viewingFromClassroom
                  ? (row.fromClassroomCode ?? row.classroomCode).trim()
                  : ((row.toClassroomCode ?? row.classroomCode).trim()),
              activityDateIso: at.toIso8601String(),
              studentActivityRefs: <Map<String, String>>[
                {
                  'name': studentName,
                  if (studentCode != null && studentCode.isNotEmpty)
                    'studentCode': studentCode,
                },
              ],
            ),
          );
        }
        // Important: backend may return the final sign-out time on the last
        // transfer row (`isTransfer: true`). Render sign-out from transfer rows too.
        if ((eventFilter == null || eventFilter == 'Sign-out') &&
            row.signedOutTime != null) {
          final at = _attendanceClockToDateTime(row.signedOutTime, day) ?? day;
          final effectiveClassName = _displayClassroomName(
            classroomCode:
                (row.toClassroomCode ?? row.classroomCode).trim().isEmpty
                ? row.classroomCode
                : row.toClassroomCode,
            classroomName:
                (row.toClassroomName ?? row.classroomName).trim().isEmpty
                ? row.classroomName
                : row.toClassroomName!,
          );
          out.add(
            ActivityItem(
              time: DateFormat.jm().format(at),
              date: DateFormat('MMMM d, yyyy').format(at),
              name: 'Sign-out',
              description:
                  'Signed-Out from ${effectiveClassName.isEmpty ? 'classroom' : effectiveClassName}',
              studentList: <String>[studentName],
              createdBy: (row.signedOutBy ?? '').trim().isEmpty
                  ? _viewerStaffDisplayName
                  : row.signedOutBy!.trim(),
              studentCode: studentCode?.isEmpty == true ? null : studentCode,
              classroomCode: (row.toClassroomCode ?? row.classroomCode).trim(),
              activityDateIso: at.toIso8601String(),
              studentActivityRefs: <Map<String, String>>[
                {
                  'name': studentName,
                  if (studentCode != null && studentCode.isNotEmpty)
                    'studentCode': studentCode,
                },
              ],
            ),
          );
        }
        continue;
      }

      if ((eventFilter == null || eventFilter == 'Sign-in') &&
          row.signedInTime != null) {
        final at = _attendanceClockToDateTime(row.signedInTime, day) ?? day;
        out.add(
          ActivityItem(
            time: DateFormat.jm().format(at),
            date: DateFormat('MMMM d, yyyy').format(at),
            name: 'Sign-in',
            description:
                'Signed-In to ${baseClassName.isEmpty ? 'classroom' : baseClassName}',
            studentList: <String>[studentName],
            createdBy: (row.signedInBy ?? '').trim().isEmpty
                ? _viewerStaffDisplayName
                : row.signedInBy!.trim(),
            studentCode: studentCode?.isEmpty == true ? null : studentCode,
            classroomCode: row.classroomCode.trim(),
            activityDateIso: at.toIso8601String(),
            studentActivityRefs: <Map<String, String>>[
              {
                'name': studentName,
                if (studentCode != null && studentCode.isNotEmpty)
                  'studentCode': studentCode,
              },
            ],
          ),
        );
      }

      if ((eventFilter == null || eventFilter == 'Sign-out') &&
          row.signedOutTime != null) {
        final at = _attendanceClockToDateTime(row.signedOutTime, day) ?? day;
        out.add(
          ActivityItem(
            time: DateFormat.jm().format(at),
            date: DateFormat('MMMM d, yyyy').format(at),
            name: 'Sign-out',
            description:
                'Signed-Out from ${baseClassName.isEmpty ? 'classroom' : baseClassName}',
            studentList: <String>[studentName],
            createdBy: (row.signedOutBy ?? '').trim().isEmpty
                ? _viewerStaffDisplayName
                : row.signedOutBy!.trim(),
            studentCode: studentCode?.isEmpty == true ? null : studentCode,
            classroomCode: row.classroomCode.trim(),
            activityDateIso: at.toIso8601String(),
            studentActivityRefs: <Map<String, String>>[
              {
                'name': studentName,
                if (studentCode != null && studentCode.isNotEmpty)
                  'studentCode': studentCode,
              },
            ],
          ),
        );
      }
    }
    out.sort(_compareActivityItemsByTimeDesc);
    return out;
  }

  List<ActivityItem> _mapAbsentRecordsPageToItems(
    StudentAttendanceAbsentFormPage page,
  ) {
    final out = <ActivityItem>[];
    for (final row in page.items) {
      DateTime recordDay;
      try {
        final src = row.absenceDate.trim();
        recordDay = src.isEmpty
            ? (_selectedDate ?? AppTime.now())
            : DateTime.parse(src);
      } catch (_) {
        recordDay = _selectedDate ?? AppTime.now();
      }
      final at =
          _absentClockToDateTime(row.markedAbsentTime, recordDay) ?? recordDay;
      final studentName = row.studentName.trim().isEmpty
          ? 'Student'
          : row.studentName.trim();
      final studentCode = row.studentCode.trim();
      final className = _displayClassroomName(
        classroomCode: row.classroomCode,
        classroomName: row.classroomName,
      );

      final reason = row.absenceNote?.trim();
      final description = (reason != null && reason.isNotEmpty)
          ? 'Marked absent from ${className.isEmpty ? 'classroom' : className} ($reason)'
          : 'Marked absent from ${className.isEmpty ? 'classroom' : className}';

      out.add(
        ActivityItem(
          time: DateFormat.jm().format(at),
          date: DateFormat('MMMM d, yyyy').format(at),
          name: 'Marked Absent',
          description: description,
          studentList: <String>[studentName],
          createdBy: (row.markedAbsentByName ?? '').trim().isEmpty
              ? _viewerStaffDisplayName
              : row.markedAbsentByName!.trim(),
          studentCode: studentCode.isEmpty ? null : studentCode,
          classroomCode: row.classroomCode.trim(),
          activityDateIso: at.toIso8601String(),
          studentActivityRefs: <Map<String, String>>[
            {
              'name': studentName,
              if (studentCode.isNotEmpty) 'studentCode': studentCode,
            },
          ],
        ),
      );
    }
    out.sort(_compareActivityItemsByTimeDesc);
    return out;
  }

  void _onFeedScroll() {
    _maybeLoadNextDailyFeedPage();
  }

  void _maybeLoadNextDailyFeedPage() {
    if (!_feedScrollController.hasClients) return;
    if (_loadingMoreFeed ||
        !_feedHasMore ||
        _loadingFeed ||
        _isFeedRequestInFlight) {
      return;
    }
    final position = _feedScrollController.position;
    if (position.maxScrollExtent <= 0) {
      _loadNextDailyFeedPage();
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextDailyFeedPage();
    }
  }

  Future<void> _loadNextDailyFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _loadingFeed) return;

    if (_parentHome) {
      return _loadNextParentHomeDailyFeedPage();
    }

    final classroomName = _selectdClassroom;
    final school = _schoolCode;
    final date = _selectedDate;
    if (classroomName == null ||
        school == null ||
        school.isEmpty ||
        date == null ||
        !_classroomCodeByName.containsKey(classroomName)) {
      return;
    }

    final classroomCode = _classroomCodeByName[classroomName]!;
    final dateStr = _dateQueryParam(date);
    final studentCodes = _selectedStudentCodesForAttendanceFilter();
    final selectedEvent = _selectedAttendanceEventFilter();
    final signInAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
        ? 'NOT_NULL'
        : null;
    final signOutAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
        ? 'NOT_NULL'
        : null;

    _loadingMoreFeed = true;
    if (mounted) setState(() {});

    try {
      final selectedStudentCode =
          (studentCodes != null && studentCodes.isNotEmpty)
          ? studentCodes.first
          : null;
      final classroomCodes = _selectedClassroomCodesForFeed();
      final typeCodes = _activityTypeCodesForApiFilter();
      final pageIndex = _feedNextPage;

      final includeAttendance =
          _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();
      final activityFeedPage = await _getDailyActivityFeedUseCase(
        classroomCode: classroomCode,
        date: dateStr,
        studentCode: selectedStudentCode,
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        activityTypeCodes: typeCodes,
        guardianPersona: _parentHome,
        page: pageIndex,
        size: _feedPageSize,
      );
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (includeAttendance) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _getStudentAbsentRecordsActivityUseCase(
            fromAbsenceDate: dateStr,
            toAbsenceDate: dateStr,
            classroomCodes: classroomCodes.isNotEmpty
                ? classroomCodes
                : <String>[classroomCode],
            studentCodes: studentCodes,
            page: pageIndex,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final ccForAttendance = classroomCodes.isNotEmpty
              ? classroomCodes
              : <String>[classroomCode];
          final dailyAbsent = await Future.wait([
            _getStudentAttendanceDailyUseCase(
              attendanceDate: dateStr,
              classroomCodes: ccForAttendance,
              studentCodes: studentCodes,
              signInAtFilter: null,
              signOutAtFilter: null,
              page: pageIndex,
              size: _feedPageSize,
            ),
            _getStudentAbsentRecordsActivityUseCase(
              fromAbsenceDate: dateStr,
              toAbsenceDate: dateStr,
              classroomCodes: ccForAttendance,
              studentCodes: studentCodes,
              page: pageIndex,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _getStudentAttendanceDailyUseCase(
            attendanceDate: dateStr,
            classroomCodes: classroomCodes.isNotEmpty
                ? classroomCodes
                : <String>[classroomCode],
            studentCodes: studentCodes,
            signInAtFilter: signInAtFilter,
            signOutAtFilter: signOutAtFilter,
            page: pageIndex,
            size: _feedPageSize,
          );
        }
      }
      await _primeStaffDisplayNamesFromFeedRows(activityFeedPage.content);
      await primeActivityFeedOptionLabelsFromRows(activityFeedPage.content);

      final items = <ActivityItem>[
        if (attendancePage != null)
          ..._withTagFilterOnly(_mapAttendanceDailyPageToItems(attendancePage)),
        if (absentPage != null)
          ..._withTagFilterOnly(_mapAbsentRecordsPageToItems(absentPage)),
        ..._mapDailyFeedPageToItems(activityFeedPage),
      ]..sort(_compareActivityItemsByTimeDesc);

      if (!mounted) return;
      setState(() {
        _activities.addAll(items);
        _activities = groupMultiStudentFeedItems(
          _activities,
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc);
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !activityFeedPage.last;
        _feedNextPage = _feedHasMore ? pageIndex + 1 : 0;
      });
    } catch (e) {
      if (mounted) {
        CoreUtils.logApiError(
          ApiErrorHandler.extractErrorMessage(e),
          showOnScreen: true,
          context: context,
        );
        setState(() => _feedHasMore = false);
      }
    } finally {
      _loadingMoreFeed = false;
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeLoadNextDailyFeedPage(),
        );
      }
    }
  }

  Future<void> _loadParentHomeDailyFeed({bool refresh = false}) async {
    final school = _schoolCode;
    final date = _selectedDate;
    if (school == null ||
        school.isEmpty ||
        date == null ||
        _parentAllowedStudentCodes.isEmpty) {
      if (mounted) {
        setState(() {
          _activities = [];
          _loadingFeed = false;
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }

    final codes = _parentAllowedStudentCodes.toList()..sort();
    final dateStr = _dateQueryParam(date);
    final typeCodes = _activityTypeCodesForApiFilter();
    final approvalStatuses = _approvalStatusesForApiFilter();
    final selectedEvent = _selectedAttendanceEventFilter();
    final signInAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
        ? 'NOT_NULL'
        : null;
    final signOutAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
        ? 'NOT_NULL'
        : null;
    final requestKey = [
      'parentDaily',
      school,
      codes.join(','),
      dateStr,
      selectedEvent ?? '',
      (typeCodes ?? const <String>[]).join(','),
      _filterActivityTypes.join(','),
      _filterTags.join(','),
      _filterApprovalStatuses.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      // Already-loaded feed: skip the refetch, but still honour a pending
      // deep-link scroll (the rows are on screen; only the trigger was missing).
      if (_isFeedRequestInFlight) return;
      if (!_lastFeedCompletedWithError) {
        _scheduleHighlightScroll();
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          AppTime.nowUtc().difference(completedAt) <
              const Duration(seconds: 3)) {
        _scheduleHighlightScroll();
        return;
      }
    }

    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    if (mounted) {
      setState(() {
        _loadingFeed = true;
        _feedError = null;
        _feedHasMore = true;
        _loadingMoreFeed = false;
      });
    }

    try {
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (_filterApprovalStatuses.isEmpty &&
          _shouldIncludeAttendanceEntries()) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _getStudentAbsentRecordsActivityUseCase(
            fromAbsenceDate: dateStr,
            toAbsenceDate: dateStr,
            studentCodes: codes,
            page: 0,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final dailyAbsent = await Future.wait([
            _getStudentAttendanceDailyUseCase(
              attendanceDate: dateStr,
              studentCodes: codes,
              signInAtFilter: null,
              signOutAtFilter: null,
              page: 0,
              size: _feedPageSize,
            ),
            _getStudentAbsentRecordsActivityUseCase(
              fromAbsenceDate: dateStr,
              toAbsenceDate: dateStr,
              studentCodes: codes,
              page: 0,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _getStudentAttendanceDailyUseCase(
            attendanceDate: dateStr,
            studentCodes: codes,
            signInAtFilter: signInAtFilter,
            signOutAtFilter: signOutAtFilter,
            page: 0,
            size: _feedPageSize,
          );
        }
      }
      final pages = await Future.wait(
        _parentAllowedStudentCodes.map((sc) async {
          final cc = _parentStudentClassroomByCode[sc]?.trim() ?? '';
          if (cc.isEmpty) {
            return const ActivityFeedPage(
              content: [],
              totalElements: 0,
              totalPages: 0,
              pageNumber: 0,
              last: true,
            );
          }
          return _getDailyActivityFeedUseCase(
            classroomCode: cc,
            date: dateStr,
            studentCode: sc,
            activityTypeCodes: typeCodes,
            approvalStatuses: approvalStatuses,
            guardianPersona: true,
            page: 0,
            size: _feedPageSize,
          );
        }),
      );

      final merged = mergeActivityFeedPages(pages);
      await _primeStaffDisplayNamesFromFeedRows(merged.content);
      await primeActivityFeedOptionLabelsFromRows(merged.content);
      final items = <ActivityItem>[
        if (attendancePage != null)
          ..._withTagFilterOnly(_mapAttendanceDailyPageToItems(attendancePage)),
        if (absentPage != null)
          ..._withTagFilterOnly(_mapAbsentRecordsPageToItems(absentPage)),
        ..._mapDailyFeedPageToItems(merged),
      ]..sort(_compareActivityItemsByTimeDesc);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        _activities = groupMultiStudentFeedItems(
          items,
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc);
        _loadingFeed = false;
        _feedError = null;
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !merged.last;
        _feedNextPage = merged.last ? 0 : merged.pageNumber + 1;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = false;
      _scheduleHighlightScroll();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadNextDailyFeedPage(),
      );
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _loadingFeed = false;
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = true;
    }
  }

  Future<void> _loadNextParentHomeDailyFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _loadingFeed) return;

    final school = _schoolCode;
    final date = _selectedDate;
    if (school == null ||
        school.isEmpty ||
        date == null ||
        _parentAllowedStudentCodes.isEmpty) {
      return;
    }

    final dateStr = _dateQueryParam(date);
    final typeCodes = _activityTypeCodesForApiFilter();
    final approvalStatuses = _approvalStatusesForApiFilter();
    final pageIndex = _feedNextPage;
    final selectedEvent = _selectedAttendanceEventFilter();
    final signInAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
        ? 'NOT_NULL'
        : null;
    final signOutAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
        ? 'NOT_NULL'
        : null;

    _loadingMoreFeed = true;
    if (mounted) setState(() {});

    try {
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (_filterApprovalStatuses.isEmpty &&
          _shouldIncludeAttendanceEntries()) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _getStudentAbsentRecordsActivityUseCase(
            fromAbsenceDate: dateStr,
            toAbsenceDate: dateStr,
            studentCodes: _parentAllowedStudentCodes.toList(),
            page: pageIndex,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final dailyAbsent = await Future.wait([
            _getStudentAttendanceDailyUseCase(
              attendanceDate: dateStr,
              studentCodes: _parentAllowedStudentCodes.toList(),
              signInAtFilter: null,
              signOutAtFilter: null,
              page: pageIndex,
              size: _feedPageSize,
            ),
            _getStudentAbsentRecordsActivityUseCase(
              fromAbsenceDate: dateStr,
              toAbsenceDate: dateStr,
              studentCodes: _parentAllowedStudentCodes.toList(),
              page: pageIndex,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _getStudentAttendanceDailyUseCase(
            attendanceDate: dateStr,
            studentCodes: _parentAllowedStudentCodes.toList(),
            signInAtFilter: signInAtFilter,
            signOutAtFilter: signOutAtFilter,
            page: pageIndex,
            size: _feedPageSize,
          );
        }
      }
      final pages = await Future.wait(
        _parentAllowedStudentCodes.map((sc) async {
          final cc = _parentStudentClassroomByCode[sc]?.trim() ?? '';
          if (cc.isEmpty) {
            return ActivityFeedPage(
              content: const [],
              totalElements: 0,
              totalPages: 0,
              pageNumber: pageIndex,
              last: true,
            );
          }
          return _getDailyActivityFeedUseCase(
            classroomCode: cc,
            date: dateStr,
            studentCode: sc,
            activityTypeCodes: typeCodes,
            approvalStatuses: approvalStatuses,
            guardianPersona: true,
            page: pageIndex,
            size: _feedPageSize,
          );
        }),
      );

      final merged = mergeActivityFeedPages(pages);
      await _primeStaffDisplayNamesFromFeedRows(merged.content);
      await primeActivityFeedOptionLabelsFromRows(merged.content);
      final items = <ActivityItem>[
        if (attendancePage != null)
          ..._withTagFilterOnly(_mapAttendanceDailyPageToItems(attendancePage)),
        if (absentPage != null)
          ..._withTagFilterOnly(_mapAbsentRecordsPageToItems(absentPage)),
        ..._mapDailyFeedPageToItems(merged),
      ]..sort(_compareActivityItemsByTimeDesc);

      if (!mounted) return;
      setState(() {
        _activities.addAll(items);
        _activities = groupMultiStudentFeedItems(
          _activities,
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc);
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !merged.last;
        _feedNextPage = merged.last ? 0 : merged.pageNumber + 1;
      });
    } catch (e) {
      if (mounted) {
        CoreUtils.logApiError(
          ApiErrorHandler.extractErrorMessage(e),
          showOnScreen: true,
          context: context,
        );
        setState(() => _feedHasMore = false);
      }
    } finally {
      _loadingMoreFeed = false;
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeLoadNextDailyFeedPage(),
        );
      }
    }
  }

  Future<void> _loadDailyFeed({bool refresh = false}) async {
    if (_parentHome) {
      return _loadParentHomeDailyFeed(refresh: refresh);
    }

    final school = _schoolCode;
    final date = _selectedDate;
    final classroomCodes = _selectedClassroomCodesForFeed();
    final classroomCode = classroomCodes.isNotEmpty
        ? classroomCodes.first
        : null;
    if (school == null ||
        school.isEmpty ||
        date == null ||
        classroomCode == null) {
      if (mounted) {
        setState(() {
          _activities = [];
          _loadingFeed = false;
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }

    final dateStr = _dateQueryParam(date);

    final studentCodes = _selectedStudentCodesForAttendanceFilter();
    final selectedEvent = _selectedAttendanceEventFilter();
    final signInAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
        ? 'NOT_NULL'
        : null;
    final signOutAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
        ? 'NOT_NULL'
        : null;
    final requestKey = [
      classroomCode,
      dateStr,
      (studentCodes ?? const <String>[]).join(','),
      selectedEvent ?? '',
      _filterActivityTypes.join(','),
      _filterTags.join(','),
      _filterApprovalStatuses.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      if (_isFeedRequestInFlight) {
        // Same request is already running; skip duplicate calls.
        return;
      }
      if (!_lastFeedCompletedWithError) {
        // Last identical request already completed successfully
        // (including empty-result success). No need to refetch — but the rows
        // ARE already loaded, so a pending deep-link still needs its scroll.
        // Returning here previously skipped it entirely, which is why a cached
        // feed highlighted without ever scrolling.
        _scheduleHighlightScroll();
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          AppTime.nowUtc().difference(completedAt) <
              const Duration(seconds: 3)) {
        // Throttle repeated failed requests for same filters.
        _scheduleHighlightScroll();
        return;
      }
    }

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    if (mounted) {
      setState(() {
        _loadingFeed = true;
        _feedError = null;
        _feedHasMore = true;
        _loadingMoreFeed = false;
      });
    }

    try {
      final selectedStudentCode =
          (studentCodes != null && studentCodes.isNotEmpty)
          ? studentCodes.first
          : null;
      final typeCodes = _activityTypeCodesForApiFilter();
      final approvalStatuses = _approvalStatusesForApiFilter();

      final includeAttendance =
          _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();
      final activityFeedPage = await _getDailyActivityFeedUseCase(
        classroomCode: classroomCode,
        date: dateStr,
        studentCode: selectedStudentCode,
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        activityTypeCodes: typeCodes,
        approvalStatuses: approvalStatuses,
        guardianPersona: _parentHome,
        page: 0,
        size: _feedPageSize,
      );
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (includeAttendance) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _getStudentAbsentRecordsActivityUseCase(
            fromAbsenceDate: dateStr,
            toAbsenceDate: dateStr,
            classroomCodes: classroomCodes,
            studentCodes: studentCodes,
            page: 0,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final dailyAbsent = await Future.wait([
            _getStudentAttendanceDailyUseCase(
              attendanceDate: dateStr,
              classroomCodes: classroomCodes,
              studentCodes: studentCodes,
              signInAtFilter: null,
              signOutAtFilter: null,
              page: 0,
              size: _feedPageSize,
            ),
            _getStudentAbsentRecordsActivityUseCase(
              fromAbsenceDate: dateStr,
              toAbsenceDate: dateStr,
              classroomCodes: classroomCodes,
              studentCodes: studentCodes,
              page: 0,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _getStudentAttendanceDailyUseCase(
            attendanceDate: dateStr,
            classroomCodes: classroomCodes,
            studentCodes: studentCodes,
            signInAtFilter: signInAtFilter,
            signOutAtFilter: signOutAtFilter,
            page: 0,
            size: _feedPageSize,
          );
        }
      }
      await _primeStaffDisplayNamesFromFeedRows(activityFeedPage.content);
      await primeActivityFeedOptionLabelsFromRows(activityFeedPage.content);

      final items = <ActivityItem>[
        if (attendancePage != null)
          ..._withTagFilterOnly(_mapAttendanceDailyPageToItems(attendancePage)),
        if (absentPage != null)
          ..._withTagFilterOnly(_mapAbsentRecordsPageToItems(absentPage)),
        ..._mapDailyFeedPageToItems(activityFeedPage),
      ]..sort(_compareActivityItemsByTimeDesc);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        _activities = groupMultiStudentFeedItems(
          items,
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc);
        _loadingFeed = false;
        _feedError = null;
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !activityFeedPage.last;
        _feedNextPage = _feedHasMore ? 1 : 0;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = false;
      _scheduleHighlightScroll();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadNextDailyFeedPage(),
      );
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _loadingFeed = false;
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Deep-linked activity: open its date from the first load (avoids a
    // today-then-jump flash before the timezone resolves).
    if (widget.highlightDate != null) {
      _selectedDate = widget.highlightDate;
    }
    _getDailyActivityFeedUseCase =
        serviceLocator<GetDailyActivityFeedUseCase>();
    _getActiveClassroomsUseCase = serviceLocator<GetActiveClassroomsUseCase>();
    _getActiveActivityTypesForSchoolUseCase =
        serviceLocator<GetActiveActivityTypesForSchoolUseCase>();
    _getStudentClassroomListUseCase =
        serviceLocator<GetStudentClassroomListUseCase>();
    _getTagNameCodeMapForSchoolUseCase =
        serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    _getStudentCodesForActivityTagFilterUseCase =
        serviceLocator<GetStudentCodesForActivityTagFilterUseCase>();
    _getStudentPageUseCase = serviceLocator<GetStudentPageUseCase>();
    _getStudentAttendanceDailyUseCase =
        serviceLocator<GetStudentAttendanceDailyUseCase>();
    _getStudentAbsentRecordsActivityUseCase =
        serviceLocator<GetStudentAbsentRecordsActivityUseCase>();
    _moderationCubit = serviceLocator<ActivityModerationCubit>();
    _moderationSub = _moderationCubit.stream.listen(_onModerationState);
    _storageService = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storageService);

    isNotParent = widget.isNotParent;
    _seedProfileContext();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapSchoolZone();
      // Opened from a student profile: we already have the classroom + student
      // codes, so kick off the feed right away instead of waiting for the full
      // classroom/student bootstrap. The dropdown option lists fill in behind
      // it. _loadDailyFeed de-dupes by request key, so the later bootstrap call
      // with the same classroom won't refetch.
      if (widget.fromStudentProfile && widget.studentProfile != null) {
        final school =
            (await _storageService.getString(StorageKeys.schoolCode) ?? '')
                .trim();
        if (school.isNotEmpty && mounted) {
          _schoolCode = school;
          unawaited(_loadDailyFeed(refresh: true));
        }
      }
      await _bootstrap();
    });
    _feedScrollController.addListener(_onFeedScroll);
    _feedInvalidationSub = ActivityFeedInvalidation.onInvalidated.listen((_) {
      if (mounted) {
        _loadDailyFeed(refresh: true);
      }
    });
  }

  /// Handles a NEW notification deep-link arriving into an already-live tab.
  ///
  /// This tab is `AutomaticKeepAliveClientMixin` and sits in an indexed-stack
  /// shell branch, so once Activities has been visited the State is reused:
  /// [initState] never runs again, every one-shot latch is still set from the
  /// previous visit, and no feed reload is triggered. The card still flashed
  /// (that reads `widget.highlightCode` live during paint) but nothing ever
  /// asked for a scroll — the "cached / already open" case.
  ///
  /// Resetting the latches and reloading on the target's day + room restores
  /// the same path a cold open takes.
  @override
  void didUpdateWidget(covariant ActivityDailyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        widget.highlightCode != oldWidget.highlightCode ||
        widget.highlightDate != oldWidget.highlightDate ||
        widget.highlightClassroomCode != oldWidget.highlightClassroomCode;
    if (!changed) return;
    if ((widget.highlightCode ?? '').trim().isEmpty) return;

    setState(() {
      _highlightApplied = false;
      _highlightScrollScheduled = false;
      _deepLinkClassroomApplied = false;
      if (widget.highlightDate != null) _selectedDate = widget.highlightDate;
      _applyDeepLinkClassroom();
    });
    // refresh: true bypasses the de-dupe, so the load always completes and
    // fires the scroll even when the same day/room was already showing.
    _loadDailyFeed(refresh: true);
  }

  Future<void> _bootstrapSchoolZone() async {
    try {
      final z = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: serviceLocator<ApiClient>(),
      );
      if (!mounted) return;
      setState(() {
        _schoolIana = z;
        // A deep-linked activity's date wins so its card is on the open day.
        _selectedDate =
            widget.highlightDate ??
            SchoolZoneDateTime.schoolCalendarTodayOnly(z);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _feedInvalidationSub?.cancel();
    _moderationSub?.cancel();
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    _moderationCubit.close();
    super.dispose();
  }

  /// Reacts to moderation results emitted by [ActivityModerationCubit].
  void _onModerationState(ActivityModerationState state) {
    if (!mounted) return;
    if (state is ActivityModerationSuccess) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: state.message,
        isSuccess: true,
      );
      // Approve/reject change the feed; delete does not refresh (matches prior).
      if (state.action != ActivityModerationAction.delete) {
        _loadDailyFeed(refresh: true);
      }
    } else if (state is ActivityModerationFailure) {
      CoreUtils.logApiError(
        state.message,
        showOnScreen: true,
        context: context,
      );
    }
  }

  void _updateAvailableStudents() {
    if (_selectedClassrooms.isNotEmpty) {
      final selectedClassroomNames = _selectedClassrooms;
      final mergedStudents =
          selectedClassroomNames
              .expand((name) => _classroomStudents[name] ?? const <String>[])
              .toSet()
              .toList()
            ..sort();
      _availableStudents = mergedStudents;
      if (_selectedStudent != null &&
          !_availableStudents.contains(_selectedStudent)) {
        _selectedStudent = null;
      }
      _selectedStudents = _selectedStudents
          .where((name) => _availableStudents.contains(name))
          .toList();
    } else {
      _availableStudents =
          _classroomStudents.values
              .expand((students) => students)
              .toSet()
              .toList()
            ..sort();
      _selectedStudents = _selectedStudents
          .where((name) => _availableStudents.contains(name))
          .toList();
      _selectedStudent = null;
    }
    _pinProfileStudent();
  }

  /// Seeds the classroom + student the screen was opened for (from a student
  /// profile) into the dropdown state up-front — using the name/code already
  /// carried in [ActivityFeedScreen.studentName] — so both dropdowns display
  /// their selection on the first frame instead of appearing empty while the
  /// classroom and student lists load in the background. The feed is filtered by
  /// the student's code separately, so this is purely to preload the UI.
  void _seedProfileContext() {
    if (!widget.fromStudentProfile) return;
    final cls = (widget.studentProfile?['classroom'] as String?)?.trim() ?? '';
    final clsCode =
        (widget.studentProfile?['classroomCode'] as String?)?.trim() ?? '';
    if (cls.isNotEmpty && !cls.startsWith('CLS_')) {
      if (clsCode.isNotEmpty) {
        _classroomCodeByName[cls] = clsCode;
        _classroomNameByCode[clsCode] = cls;
      }
      if (!_classroomOptions.contains(cls)) {
        _classroomOptions = <String>[..._classroomOptions, cls]..sort();
      }
      _selectdClassroom = cls;
      _selectedClassrooms = <String>[cls];
    }
    final name = widget.studentName?.trim() ?? '';
    if (name.isNotEmpty) {
      _selectedStudent = name;
      _selectedStudents = <String>[name];
    }
    _pinProfileStudent();
  }

  bool _highlightScrollScheduled = false;

  /// Scrolls the deep-linked card into view.
  ///
  /// Driven by the DATA (the target's index in [_activities]), never by the
  /// item builder. `ListView.builder` builds lazily, so a target further down
  /// the list is never built while off-screen — its `itemBuilder` doesn't run,
  /// and `Scrollable.ensureVisible` has no element to scroll to. That's why the
  /// card only ever flashed once the user scrolled to it by hand.
  ///
  /// Converges in two phases: jump proportionally to bring the target into the
  /// build window, then fine-tune with `ensureVisible` once it exists, plus a
  /// settle pass for rows that grow when attachment thumbnails resolve.
  void _scheduleHighlightScroll() {
    if (_highlightApplied || _highlightScrollScheduled) return;
    if ((widget.highlightCode ?? '').trim().isEmpty) return;
    final index = _activities.indexWhere(
      (a) => _isHighlightTarget(a.activityCode),
    );
    if (index < 0) return; // not in this page yet — retried on the next load
    _highlightScrollScheduled = true;

    var passes = 0;
    void step() {
      if (!mounted) return;
      if (passes++ > 25) {
        _highlightScrollScheduled = false; // let a later load try again
        return;
      }
      if (!_feedScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), step);
        return;
      }

      final ctx = _highlightCardKey.currentContext;
      if (ctx != null) {
        // Built: fine-tune to the exact position.
        _highlightApplied = true;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.1,
          curve: Curves.easeOut,
        );
        // One settle pass after layout stabilises.
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          final c = _highlightCardKey.currentContext;
          if (c != null) {
            Scrollable.ensureVisible(
              c,
              duration: const Duration(milliseconds: 200),
              alignment: 0.1,
              curve: Curves.easeOut,
            );
          }
        });
        return;
      }

      // Not built yet: jump proportionally so it enters the build window.
      final pos = _feedScrollController.position;
      final total = _activities.length;
      final target = total <= 1
          ? 0.0
          : pos.maxScrollExtent * (index / (total - 1)).clamp(0.0, 1.0);
      if ((target - pos.pixels).abs() > 1) {
        _feedScrollController.jumpTo(target.clamp(0.0, pos.maxScrollExtent));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => step());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => step());
  }

  /// Selects the classroom of a notification-deep-linked activity, so the feed
  /// loads the room that actually contains the card being highlighted rather
  /// than the viewer's default room.
  ///
  /// Called from [_bootstrap] once `_classroomNameByCode` is populated and
  /// BEFORE the default-classroom `keep` check, so the resolved name survives as
  /// the selection. No-op when there's no deep link or the code isn't in the
  /// viewer's (possibly staff-scoped) classroom list.
  void _applyDeepLinkClassroom() {
    final code = (widget.highlightClassroomCode ?? '').trim();
    if (code.isEmpty) return;
    if (_deepLinkClassroomApplied) return;
    final name = (_classroomNameByCode[code] ?? '').trim();
    if (name.isEmpty || !_classroomOptions.contains(name)) return;
    _deepLinkClassroomApplied = true;
    _selectdClassroom = name;
    _selectedClassrooms = <String>[name];
  }

  /// Applied once, so a later refresh can't yank the user off a room they
  /// switched to after arriving via the deep link.
  bool _deepLinkClassroomApplied = false;

  /// Keeps the profile student present in the options + selection when launched
  /// from a student profile. Both this widget's pruning and
  /// [CustomMultiSelectDropdown] drop selections absent from the options list,
  /// so without this the pre-selected student silently disappears once the real
  /// student list loads.
  void _pinProfileStudent() {
    if (!widget.fromStudentProfile) return;
    final name = widget.studentName?.trim() ?? '';
    if (name.isEmpty) return;
    if (!_availableStudents.contains(name)) {
      _availableStudents = <String>[..._availableStudents, name]..sort();
    }
    if (!_selectedStudents.contains(name)) {
      _selectedStudents = <String>[..._selectedStudents, name];
    }
    _selectedStudent ??= name;
  }

  Future<void> _openActivityFilter() async {
    final school = _schoolCode;
    final classroomName = _selectdClassroom;
    if (school == null ||
        school.isEmpty ||
        classroomName == null ||
        !_classroomCodeByName.containsKey(classroomName)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select a classroom first',
        isWarning: true,
      );
      return;
    }
    final classroomCode = _classroomCodeByName[classroomName]!;
    final result = await Navigator.push<Map<String, List<String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityFilterScreen(
          schoolCode: school,
          classroomCode: classroomCode,
          initialFilters: {
            'Tags': List<String>.from(_filterTags),
            'Activity Type': List<String>.from(_filterActivityTypes),
            'Status': List<String>.from(_filterApprovalStatuses),
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _filterTags = List<String>.from(result['Tags'] ?? const []);
      _filterActivityTypes = List<String>.from(
        result['Activity Type'] ?? const [],
      );
      _filterApprovalStatuses = List<String>.from(result['Status'] ?? const []);
    });
    await _loadDailyFeed(refresh: true);
  }

  Future<void> _deleteActivityFromSheet(
    BuildContext sheetContext,
    ActivityItem activity,
  ) async {
    final code = activity.activityCode?.trim();
    if (code == null || code.isEmpty) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot delete: missing activity reference.',
        isError: true,
      );
      return;
    }
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    _moderationCubit.delete(code);
  }

  Future<void> _approveActivityFromMenu(ActivityItem activity) async {
    final code = activity.activityCode?.trim();
    if (code == null || code.isEmpty) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot approve: missing activity reference.',
        isError: true,
      );
      return;
    }
    _moderationCubit.approve(code);
  }

  Future<void> _rejectActivityFromMenu(ActivityItem activity) async {
    final code = activity.activityCode?.trim();
    if (code == null || code.isEmpty) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot reject: missing activity reference.',
        isError: true,
      );
      return;
    }
    _moderationCubit.reject(code);
  }

  Future<void> _showApprovalActionBottomSheet({
    required ActivityItem activity,
    required bool isApprove,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DeleteConfirmationBottomSheet(
          name: activity.name,
          type: isApprove ? 'activity_approve' : 'activity_reject',
          onDelete: () async {
            if (isApprove) {
              await _approveActivityFromMenu(activity);
            } else {
              await _rejectActivityFromMenu(activity);
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          onCancel: () {
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  Future<void> _loadTagFilterOptions({bool forceRefresh = false}) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;
    try {
      final map = await ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _getTagNameCodeMapForSchoolUseCase,
        schoolCode: school,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _tagNameToCode = Map<String, String>.from(map);
        _tagFilterOptions = map.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _filterTags.removeWhere((t) => !_tagFilterOptions.contains(t));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _tagFilterOptions = []);
        CoreUtils.logApiError(
          ApiErrorHandler.extractErrorMessage(e),
          showOnScreen: true,
          context: context,
        );
      }
    }
  }

  /// Same card styling as the empty state; shows [PrimaryCircularLoader] on white.
  Widget _dailyFeedLoadingSheet(
    BuildContext context, {
    bool expandToParentHeight = false,
  }) {
    final sheet = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: const PrimaryCircularLoader(size: 40, strokeWidth: 3.5),
    );

    return Padding(
      padding: ResponsiveSizing.contentPadding(context),
      child: expandToParentHeight ? SizedBox.expand(child: sheet) : sheet,
    );
  }

  /// Minimum viewport height + [AlwaysScrollableScrollPhysics] so pull-to-refresh
  /// works when the feed is empty or loading (portrait [Column] layout).
  Widget _portraitOverscrollFeedWrapper({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _feedScrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Listen to global child dropdown. When ParentChildCubit notifies,
    // this widget rebuilds and we can refresh the feed for the selected child.
    if (_parentHome) {
      context.watch<ParentChildCubit>().selectedChild?.code;
    }
    if (_parentHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncWithGlobalChildSelection();
      });
    }
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _feedScrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: ResponsiveSizing.contentPadding(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: widget.fromStudentProfile && !isNotParent
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: AbsorbPointer(
                                    child: _buildCustomDropdown(
                                      'Select Student',
                                      widget.studentName != null
                                          ? [widget.studentName!]
                                          : <String>[],
                                      widget.studentName,
                                      (v) => setState(() {
                                        _selectedStudent = v;
                                      }),
                                      height: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: _datePickerFilter(
                                    selectedDate: _selectedDate,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _selectedDate = date;
                                      });
                                      _loadDailyFeed();
                                    },
                                  ),
                                ),
                              ],
                            )
                          : isNotParent
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCustomMultiDropdown(
                                        'Select Classroom',
                                        _classroomOptions,
                                        _selectedClassrooms,
                                        (values) async {
                                          if (values.isEmpty) {
                                            setState(() {
                                              _selectdClassroom = null;
                                              _selectedClassrooms = <String>[];
                                              _selectedStudent = null;
                                              _selectedStudents = [];
                                              _filterActivityTypes.clear();
                                              _filterTags.clear();
                                              _filterApprovalStatuses.clear();
                                              _updateAvailableStudents();
                                            });
                                            await _refreshDropdownsAfterClearAll();
                                            await _loadDailyFeed(refresh: true);
                                            return;
                                          }

                                          setState(() {
                                            _selectedClassrooms = values;
                                            _selectdClassroom = values.first;
                                            _updateAvailableStudents();
                                          });
                                          if (values.length > 1 &&
                                              isNotParent) {
                                            await _loadStudentsForSelectedClassrooms(
                                              values,
                                            );
                                            await _loadDailyFeed(refresh: true);
                                          } else {
                                            await _reloadStudentsAndSettingsThenFeed();
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      // child: _buildCustomDropdown(
                                      //   'Select Student',
                                      //   _allStudents,
                                      //   _selectedStudent,
                                      //   (v) => setState(() {
                                      //     _selectedStudent = v;
                                      //   }),
                                      // ),
                                      child: _buildCustomMultiDropdown(
                                        'Select Student',
                                        _availableStudents,
                                        _selectedStudents,
                                        (values) {
                                          setState(() {
                                            _selectedStudents = values;
                                            _selectedStudent = values.isNotEmpty
                                                ? values.first
                                                : null;
                                          });
                                          _loadDailyFeed();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: _openActivityFilter,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: SvgPicture.asset(
                                                MediaRes.filterIcon,
                                                height: 20,
                                              ),
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final badgeCount =
                                                    _appliedFilterBadgeCount();
                                                if (badgeCount == 0) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Positioned(
                                                  right: 2,
                                                  top: 2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFE01B5D),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      badgeCount > 99
                                                          ? '99+'
                                                          : '$badgeCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _datePickerFilter(
                                        selectedDate: _selectedDate,
                                        onDateSelected: (date) {
                                          setState(() {
                                            _selectedDate = date;
                                          });
                                          _loadDailyFeed();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CustomClearAllChip(
                                      onTap: () async {
                                        setState(() {
                                          final now = AppTime.now();
                                          _selectedDate = DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                          );
                                          _selectdClassroom = null;
                                          _selectedClassrooms = <String>[];
                                          _selectedStudent = null;
                                          _selectedStudents = [];
                                          _filterActivityTypes.clear();
                                          _filterTags.clear();
                                          _filterApprovalStatuses.clear();
                                        });
                                        await _refreshDropdownsAfterClearAll();
                                        await _loadDailyFeed(refresh: true);
                                      },
                                      label: 'Clear All',
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : SizedBox(
                              height: 40,
                              child: _datePickerFilter(
                                selectedDate: _selectedDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                  _loadDailyFeed();
                                },
                              ),
                            ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: _parentHome ? 0 : 12),
                ),
                if ((_loadingFeed || _loadingParentContext) &&
                    _activities.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: SizedBox.expand(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 48,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: const PrimaryCircularLoader(
                            size: 40,
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!_loadingFeed &&
                    !_loadingParentContext &&
                    _activities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: AppText.title(
                            _feedError ?? 'No Activities found',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // if (activities.isNotEmpty)
                //   SliverPadding(
                //     padding: EdgeInsets.all(16),
                //     sliver: SliverList(
                //       delegate: SliverChildBuilderDelegate(
                //             (context, index) => Container(
                //           height: 100,
                //           margin: EdgeInsets.only(bottom: 16),
                //           color: Colors.blue[100 * (index % 9 + 1)],
                //           child: Center(child: Text('Test Item $index')),
                //         ),
                //         childCount: _activities.length,
                //       ),
                //     ),
                //   ),
                if (_activities.isNotEmpty)
                  SliverPadding(
                    padding: ResponsiveSizing.activityFeedListPadding(context),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _activities.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: PrimaryCircularLoader(
                                size: 28,
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        }
                        final activity = _activities[index];
                        final students = activity.studentList;
                        final Color activityColor =
                            _colorPalette[index % _colorPalette.length];
                        final bool isHighlightTarget = _isHighlightTarget(
                          activity.activityCode,
                        );
                        if (isHighlightTarget) _scheduleHighlightScroll();

                        return HighlightableCard(
                          key: isHighlightTarget ? _highlightCardKey : null,
                          code: activity.activityCode,
                          highlightCode: widget.highlightCode,
                          borderRadius: 12,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          //color: activity.color,
                                          color: activityColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 4,
                                        height: 2,
                                        //color: activity.color,
                                        color: activityColor,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 100,
                                    height: 4,
                                    //color: activity.color,
                                    color: activityColor,
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      //color: activity.color,
                                      color: activityColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    height: 20,
                                    child: AppText.small(
                                      activity.time,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 7),
                                  Container(
                                    width: 4,
                                    height: 220,
                                    //color: activity.color,
                                    color: activityColor,
                                  ),

                                  const SizedBox(width: 16),

                                  // Activity Card
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 0,
                                      ),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 15),
                                          InkWell(
                                            onTap: () async {
                                              final hasStatusBadge =
                                                  activityApprovalStatusBadgeLabel(
                                                    activity.approvalStatus,
                                                  ) !=
                                                  null;
                                              final canOpenEdit =
                                                  hasStatusBadge &&
                                                  isNotParent &&
                                                  widget.allowActivityWrite &&
                                                  canEditActivityItem(
                                                    activity,
                                                    isAdminPersona:
                                                        _isAdminPersona,
                                                    viewerStaffCode:
                                                        _viewerStaffCode,
                                                  );
                                              final destinationBuilder =
                                                  canOpenEdit
                                                  ? editActivityRoutes[activity
                                                        .name]
                                                  : activityRoutes[activity
                                                        .name];
                                              if (destinationBuilder != null) {
                                                final nextScreen =
                                                    destinationBuilder(
                                                      activity,
                                                    );
                                                await Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => nextScreen,
                                                  ),
                                                );
                                                if (mounted) {
                                                  await _loadDailyFeed(
                                                    refresh: true,
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                minHeight: 180,
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: activityColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: activityColor
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: SizedBox(
                                                      width: 140,
                                                      height: 120,
                                                      child:
                                                          activityHasMediaOrProcessing(
                                                            activity,
                                                          )
                                                          ? ActivityMediaPreview(
                                                              activity:
                                                                  activity,
                                                              activityColor:
                                                                  activityColor,
                                                            )
                                                          // ? Image.network(
                                                          //     activity.photoUrl!,
                                                          //     fit: BoxFit.cover,
                                                          //     loadingBuilder:
                                                          //         (
                                                          //           context,
                                                          //           child,
                                                          //           loadingProgress,
                                                          //         ) {
                                                          //           if (loadingProgress ==
                                                          //               null)
                                                          //             return child;
                                                          //           return Container(
                                                          //             color: Colors
                                                          //                 .transparent,
                                                          //             child: const Center(
                                                          //               child: CircularProgressIndicator(
                                                          //                 strokeWidth:
                                                          //                     2,
                                                          //               ),
                                                          //             ),
                                                          //           );
                                                          //         },
                                                          //     errorBuilder:
                                                          //         (
                                                          //           context,
                                                          //           error,
                                                          //           stackTrace,
                                                          //         ) {
                                                          //           return Container(
                                                          //             width: 122,
                                                          //             height: 76,
                                                          //             color: activity
                                                          //                 .color
                                                          //                 .withValues(alpha:
                                                          //                   0.25,
                                                          //                 ),
                                                          //             child: Center(
                                                          //               child: Image.asset(
                                                          //                 activityIcons[activity
                                                          //                     .name],
                                                          //                 //'assets/icons/activity-nap-icon.png',
                                                          //                 fit: BoxFit
                                                          //                     .fill,
                                                          //               ),
                                                          //             ),
                                                          //           );
                                                          //         },
                                                          //   )
                                                          : Container(
                                                              width: 122,
                                                              height: 76,
                                                              color:
                                                                  Colors.white,
                                                              // color: activityColor
                                                              //     .withValues(alpha:0.25),
                                                              child: Center(
                                                                child: Builder(
                                                                  builder: (_) {
                                                                    final iconPath =
                                                                        (activityIcons[activity.name] ??
                                                                                MediaRes.notesActivityIcon)
                                                                            .toString();
                                                                    if (iconPath
                                                                        .toLowerCase()
                                                                        .endsWith(
                                                                          '.svg',
                                                                        )) {
                                                                      return SvgPicture.asset(
                                                                        iconPath,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      );
                                                                    }
                                                                    return Image.asset(
                                                                      iconPath,
                                                                      fit: BoxFit
                                                                          .fill,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Align(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            6,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: activityColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.5,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    activity
                                                                        .name,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: const TextStyle(
                                                                      color: AppColors
                                                                          .primaryColor,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (!isAttendanceCardActivityItem(
                                                              activity,
                                                            ))
                                                              PopupMenuButton<
                                                                String
                                                              >(
                                                                icon: const Icon(
                                                                  Icons
                                                                      .more_horiz,
                                                                  size: 20,
                                                                ),
                                                                onSelected:
                                                                    null,
                                                                itemBuilder: (context) => [
                                                                  PopupMenuItem<
                                                                    String
                                                                  >(
                                                                    value:
                                                                        'view',
                                                                    child: PopupItem(
                                                                      title:
                                                                          'View',
                                                                      icon: Icon(
                                                                        Icons
                                                                            .visibility_outlined,
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                    onTap: () async {
                                                                      final destinationBuilder =
                                                                          activityRoutes[activity
                                                                              .name];
                                                                      if (destinationBuilder !=
                                                                          null) {
                                                                        final nextScreen =
                                                                            destinationBuilder(
                                                                              activity,
                                                                            );
                                                                        await Navigator.of(
                                                                          context,
                                                                        ).push(
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                nextScreen,
                                                                          ),
                                                                        );
                                                                        if (mounted) {
                                                                          await _loadDailyFeed(
                                                                            refresh:
                                                                                true,
                                                                          );
                                                                        }
                                                                      }
                                                                    },
                                                                  ),
                                                                  if (isNotParent &&
                                                                      widget
                                                                          .allowActivityWrite &&
                                                                      canEditActivityItem(
                                                                        activity,
                                                                        isAdminPersona:
                                                                            _isAdminPersona,
                                                                        viewerStaffCode:
                                                                            _viewerStaffCode,
                                                                      ))
                                                                    PopupMenuItem<
                                                                      String
                                                                    >(
                                                                      value:
                                                                          'edit',
                                                                      child: PopupItem(
                                                                        title:
                                                                            'Edit',
                                                                        icon: Icon(
                                                                          Icons
                                                                              .edit,
                                                                          color:
                                                                              AppColors.themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        final destinationBuilder =
                                                                            editActivityRoutes[activity.name];
                                                                        if (destinationBuilder !=
                                                                            null) {
                                                                          final nextScreen = destinationBuilder(
                                                                            activity,
                                                                          );
                                                                          await Navigator.of(
                                                                            context,
                                                                          ).push(
                                                                            MaterialPageRoute(
                                                                              builder:
                                                                                  (
                                                                                    _,
                                                                                  ) => nextScreen,
                                                                            ),
                                                                          );
                                                                          if (mounted) {
                                                                            await _loadDailyFeed(
                                                                              refresh: true,
                                                                            );
                                                                          }
                                                                        }
                                                                      },
                                                                    ),
                                                                  if (canAdminApproveOrRejectActivityItem(
                                                                        activity,
                                                                        isAdminPersona:
                                                                            _isAdminPersona,
                                                                      ) &&
                                                                      !isIncidentActivityItem(
                                                                        activity,
                                                                      )) ...[
                                                                    PopupMenuItem<
                                                                      String
                                                                    >(
                                                                      value:
                                                                          'approve',
                                                                      child: PopupItem(
                                                                        title:
                                                                            'Approve',
                                                                        icon: Icon(
                                                                          Icons
                                                                              .check_circle_outline,
                                                                          color:
                                                                              AppColors.themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        await _showApprovalActionBottomSheet(
                                                                          activity:
                                                                              activity,
                                                                          isApprove:
                                                                              true,
                                                                        );
                                                                      },
                                                                    ),
                                                                    PopupMenuItem<
                                                                      String
                                                                    >(
                                                                      value:
                                                                          'reject',
                                                                      child: PopupItem(
                                                                        title:
                                                                            'Reject',
                                                                        icon: Icon(
                                                                          Icons
                                                                              .cancel_outlined,
                                                                          color:
                                                                              AppColors.themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        await _showApprovalActionBottomSheet(
                                                                          activity:
                                                                              activity,
                                                                          isApprove:
                                                                              false,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                  if (isNotParent &&
                                                                      widget
                                                                          .allowActivityWrite &&
                                                                      canDeleteActivityItem(
                                                                        activity,
                                                                        isAdminPersona:
                                                                            _isAdminPersona,
                                                                      ))
                                                                    PopupMenuItem<
                                                                      String
                                                                    >(
                                                                      value:
                                                                          'delete',
                                                                      child: PopupItem(
                                                                        title:
                                                                            'Delete',
                                                                        icon: Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              AppColors.themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () {
                                                                        showModalBottomSheet(
                                                                          context:
                                                                              context,
                                                                          isScrollControlled:
                                                                              true,
                                                                          backgroundColor:
                                                                              Colors.transparent,
                                                                          builder: (ctx) {
                                                                            return DeleteConfirmationBottomSheet(
                                                                              name: activity.name,
                                                                              type: 'Activity',
                                                                              onDelete: () => _deleteActivityFromSheet(
                                                                                ctx,
                                                                                activity,
                                                                              ),
                                                                              onCancel: () {
                                                                                Navigator.of(
                                                                                  ctx,
                                                                                ).pop();
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),

                                                        activityFeedStudentAvatarStack(
                                                          students,
                                                          studentCodes:
                                                              feedStudentCodesForNames(
                                                                activity,
                                                              ),
                                                          onOpenStudentList: () =>
                                                              showActivityStudentListSheet(
                                                                context,
                                                                students,
                                                                studentCodes:
                                                                    feedStudentCodesForNames(
                                                                      activity,
                                                                    ),
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),

                                                        Text(
                                                          activityFeedCardBodyLine(
                                                            activity,
                                                          ),
                                                          style: AppTextStyles
                                                              .body
                                                              .copyWith(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                height: 1.0,
                                                              ),
                                                          strutStyle: StrutStyle(
                                                            fontFamily:
                                                                Fonts.manrope,
                                                            fontSize: 14,
                                                            height: 1.0,
                                                            leading: 0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            forceStrutHeight:
                                                                true,
                                                          ),
                                                          textHeightBehavior:
                                                              const TextHeightBehavior(
                                                                applyHeightToFirstAscent:
                                                                    false,
                                                                applyHeightToLastDescent:
                                                                    false,
                                                              ),
                                                          maxLines:
                                                              activityFeedCardBodyMaxLines(
                                                                activity,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        AppText.small(
                                                          'Created By - ${activity.createdBy}',
                                                          style: AppTextStyles
                                                              .small
                                                              .copyWith(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }, childCount: _activities.length + (_loadingMoreFeed ? 1 : 0)),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
            ),
          );
          // return SingleChildScrollView(
          //   child: Column(
          //     children: [
          //       Padding(
          //         padding: ResponsiveSizing.contentPadding(context),
          //         child: Container(
          //           padding: const EdgeInsets.all(12),
          //           decoration: BoxDecoration(
          //             border: Border.all(color: AppColors.cardBorderColor),
          //             borderRadius: BorderRadius.circular(12),
          //             color: AppColors.cardColor,
          //           ),
          //           child: widget.fromStudentProfile
          //               ? Column(
          //             crossAxisAlignment: CrossAxisAlignment.stretch,
          //             children: [
          //               SizedBox(
          //                 height: 40,
          //                 child: AbsorbPointer(
          //                   child: _buildCustomDropdown(
          //                     'Select Student',
          //                     [?widget.studentName],
          //                     widget.studentName,
          //                         (v) => setState(() {
          //                       _selectedStudent = v;
          //                     }),
          //                     height: 40,
          //                   ),
          //                 ),
          //               ),
          //               const SizedBox(height: 8),
          //               SizedBox(
          //                 height: 40,
          //                 child: _datePickerFilter(
          //                   selectedDate: _selectedDate,
          //                   onDateSelected: (date) {
          //                     setState(() {
          //                       _selectedDate = date;
          //                     });
          //                   },
          //                 ),
          //               ),
          //             ],
          //           )
          //               : isNotParent
          //               ? Column(
          //             children: [
          //               Row(
          //                 children: [
          //                   Expanded(
          //                     child: _buildCustomDropdown(
          //                       'Select Classroom',
          //                       _classroomOptions,
          //                       _selectdClassroom,
          //                           (v) => setState(() {
          //                         _selectdClassroom = v;
          //                         _updateAvailableStudents();
          //                       }),
          //                     ),
          //                   ),
          //                   const SizedBox(width: 8),
          //                   Expanded(
          //                     // child: _buildCustomDropdown(
          //                     //   'Select Student',
          //                     //   _allStudents,
          //                     //   _selectedStudent,
          //                     //   (v) => setState(() {
          //                     //     _selectedStudent = v;
          //                     //   }),
          //                     // ),
          //                     child: _buildCustomDropdown(
          //                       _selectdClassroom == null
          //                           ? 'Select Classroom First'
          //                           : 'Select Student',
          //                       _availableStudents,
          //                       _selectedStudent,
          //                           (value) {
          //                         if (_selectdClassroom != null) {
          //                           setState(() {
          //                             _selectedStudent = value;
          //                           });
          //                         }
          //                       },
          //                     ),
          //                   ),
          //                   const SizedBox(width: 8),
          //                   Material(
          //                     color: Colors.transparent,
          //                     child: InkWell(
          //                       borderRadius: BorderRadius.circular(100),
          //                       onTap: () async {
          //                         final result = await Navigator.push(
          //                           context,
          //                           MaterialPageRoute(
          //                             builder: (_) => FilterScreen(
          //                               sections: [
          //                                 FilerSection(
          //                                   label: 'Tags',
          //                                   hintText: 'Select tags',
          //                                   items: [
          //                                     '5 Days',
          //                                     'Full Day',
          //                                     'Photo Permission',
          //                                     'Vegetarian',
          //                                     'First Aid',
          //                                     'Allergy',
          //                                     'Pickup Authorized',
          //                                     'Medication',
          //                                     'Half Day',
          //                                     'Boy',
          //                                     'Girl',
          //                                   ],
          //                                   initialSelected: _filterTags,
          //                                   isMultiSelectDropDown: false,
          //                                 ),
          //                                 FilerSection(
          //                                   label: 'Activity Type',
          //                                   hintText: 'Select Activity',
          //                                   items: [
          //                                     'Nap Start',
          //                                     'Nap End',
          //                                     'Bathroom',
          //                                     'Bottle',
          //                                     'Meal',
          //                                     'Incident',
          //                                     'Photo',
          //                                     'Outdoor',
          //                                     'Medication',
          //                                     'Notes',
          //                                     'Learning',
          //                                     'Sign-in',
          //                                     'Sign-out',
          //                                     'Absent',
          //                                   ],
          //                                   initialSelected: _filterActivityTypes,
          //                                   isMultiSelectDropDown: false,
          //                                 ),
          //                               ],
          //                               onApply: (filters) {
          //                                 setState(() {
          //                                   _filterTags = filters['Tags']!;
          //                                   _filterActivityTypes =
          //                                   filters['Activity Type']!;
          //                                 });
          //                                 //AppLogger.d(_filterTags);
          //                                 //AppLogger.d(_filterActivityTypes);
          //                               },
          //                             ),
          //                           ),
          //                         );
          //                         if (!mounted) return;
          //                         if (result is Map) {
          //                           // TODO: apply filters to list
          //                           setState(() {});
          //                         }
          //                       },
          //                       child: Padding(
          //                         padding: const EdgeInsets.all(8),
          //                         child: SvgPicture.asset(
          //                           MediaRes.filterIcon,
          //                           height: 20,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 16),
          //               Row(
          //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                 children: [
          //                   Expanded(
          //                     child: _datePickerFilter(
          //                       selectedDate: _selectedDate,
          //                       onDateSelected: (date) {
          //                         setState(() {
          //                           _selectedDate = date;
          //                         });
          //                       },
          //                     ),
          //                   ),
          //                   const SizedBox(width: 8),
          //                   CustomClearAllChip(
          //                     onTap: () {
          //                       setState(() {
          //                         _selectdClassroom = _classroomOptions[0];
          //                         _selectedStudent = null;
          //                         _filterActivityTypes.clear();
          //                         _filterTags.clear();
          //                       });
          //                       //AppLogger.d(_filterTags);
          //                     },
          //                     label: 'Clear All',
          //                   ),
          //                 ],
          //               ),
          //             ],
          //           )
          //               : Row(
          //             children: [
          //               Expanded(
          //                 child: SizedBox(
          //                   height: 40,
          //                   child: _datePickerFilter(
          //                     selectedDate: _selectedDate,
          //                     onDateSelected: (date) {
          //                       setState(() {
          //                         _selectedDate = date;
          //                       });
          //                     },
          //                   ),
          //                 ),
          //               ),
          //               const SizedBox(width: 8),
          //               Expanded(
          //                 child: SizedBox(
          //                   height: 40,
          //                   child: _buildCustomDropdown(
          //                     'Activity Type',
          //                     activityType,
          //                     _selectedActivityType,
          //                         (v) => setState(() {
          //                       _selectedActivityType = v;
          //                     }),
          //                     height: 40,
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //
          //       const SizedBox(height: 12),
          //
          //       if (activities.length == 0)
          //         Padding(
          //           padding: ResponsiveSizing.contentPadding(context),
          //           child: Container(
          //             padding: const EdgeInsets.all(12),
          //             decoration: BoxDecoration(
          //               border: Border.all(color: AppColors.cardBorderColor),
          //               borderRadius: BorderRadius.circular(12),
          //               color: AppColors.cardColor,
          //             ),
          //             child: Center(
          //               child: Text(
          //                 'No Activities found',
          //                 style: TextStyle(
          //                   color: Colors.black,
          //                   fontFamily: 'Manrope',
          //                   fontSize: 16,
          //                   fontWeight: FontWeight.w500,
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ),
          //
          //       if (activities.length != 0)
          //         Padding(
          //           padding: ResponsiveSizing.contentPadding(context),
          //           child: Column(
          //             children: [
          //               const SizedBox(height: 10),
          //               ListView.builder(
          //                 padding: const EdgeInsets.only(right: 16),
          //                 itemCount: activities.length,
          //                 itemBuilder: (context, index) {
          //                   final activity = _activities[index];
          //                   final students = activity.studentList;
          //                   final Color activityColor =
          //                   _colorPalette[index % _colorPalette.length];
          //
          //                   return Column(
          //                     children: [
          //                       Row(
          //                         children: [
          //                           Column(
          //                             children: [
          //                               Container(
          //                                 width: 18,
          //                                 height: 18,
          //                                 decoration: BoxDecoration(
          //                                   //color: activity.color,
          //                                   color: activityColor,
          //                                   shape: BoxShape.circle,
          //                                 ),
          //                               ),
          //                               Container(
          //                                 width: 4,
          //                                 height: 2,
          //                                 //color: activity.color,
          //                                 color: activityColor,
          //                               ),
          //                             ],
          //                           ),
          //                           Container(
          //                             width: 100,
          //                             height: 4,
          //                             //color: activity.color,
          //                             color: activityColor,
          //                           ),
          //                           Container(
          //                             width: 18,
          //                             height: 18,
          //                             decoration: BoxDecoration(
          //                               //color: activity.color,
          //                               color: activityColor,
          //                               shape: BoxShape.circle,
          //                             ),
          //                           ),
          //                           const SizedBox(width: 20),
          //                           SizedBox(
          //                             height: 20,
          //                             child: Text(
          //                               activity.time,
          //                               style: TextStyle(
          //                                 fontSize: 14,
          //                                 color: AppColors.primaryColor,
          //                                 fontWeight: FontWeight.w500,
          //                               ),
          //                             ),
          //                           ),
          //                         ],
          //                       ),
          //                       Row(
          //                         crossAxisAlignment: CrossAxisAlignment.start,
          //                         children: [
          //                           const SizedBox(width: 7),
          //                           Container(
          //                             width: 4,
          //                             height: 220,
          //                             //color: activity.color,
          //                             color: activityColor,
          //                           ),
          //
          //                           const SizedBox(width: 16),
          //
          //                           // Activity Card
          //                           Column(
          //                             children: [
          //                               const SizedBox(height: 15),
          //                               InkWell(
          //                                 onTap: () {
          //                                   final destinationBuilder =
          //                                   activityRoutes[activity
          //                                       .name];
          //                                   if (destinationBuilder !=
          //                                       null) {
          //                                     final nextScreen =
          //                                     destinationBuilder(
          //                                       activity,
          //                                     );
          //                                     Navigator.of(
          //                                       context,
          //                                     ).push(
          //                                       MaterialPageRoute(
          //                                         builder: (_) =>
          //                                         nextScreen,
          //                                       ),
          //                                     );
          //                                   }
          //                                 },
          //                                 child: Container(
          //                                   height: 180,
          //                                   margin: const EdgeInsets.only(
          //                                     bottom: 24,
          //                                   ),
          //                                   padding: const EdgeInsets.all(12),
          //                                   decoration: BoxDecoration(
          //                                     color: activityColor.withValues(alpha:
          //                                       0.15,
          //                                     ),
          //                                     borderRadius: BorderRadius.circular(
          //                                       16,
          //                                     ),
          //                                     border: Border.all(
          //                                       color: activityColor.withValues(alpha:
          //                                         0.4,
          //                                       ),
          //                                     ),
          //                                   ),
          //                                   child: Row(
          //                                     // crossAxisAlignment:
          //                                     //     CrossAxisAlignment.center,
          //                                     children: [
          //                                       ClipRRect(
          //                                         borderRadius:
          //                                         BorderRadius.circular(12),
          //                                         child: SizedBox(
          //                                           width: 140,
          //                                           height: 120,
          //                                           child:
          //                                           activity.photoUrl != null ||
          //                                               activity.videoUrl !=
          //                                                   null
          //                                               ? ActivityMediaPreview(
          //                                             activity: activity,
          //                                             activityColor:
          //                                             activityColor,
          //                                           )
          //                                           // ? Image.network(
          //                                           //     activity.photoUrl!,
          //                                           //     fit: BoxFit.cover,
          //                                           //     loadingBuilder:
          //                                           //         (
          //                                           //           context,
          //                                           //           child,
          //                                           //           loadingProgress,
          //                                           //         ) {
          //                                           //           if (loadingProgress ==
          //                                           //               null)
          //                                           //             return child;
          //                                           //           return Container(
          //                                           //             color: Colors
          //                                           //                 .transparent,
          //                                           //             child: const Center(
          //                                           //               child: CircularProgressIndicator(
          //                                           //                 strokeWidth:
          //                                           //                     2,
          //                                           //               ),
          //                                           //             ),
          //                                           //           );
          //                                           //         },
          //                                           //     errorBuilder:
          //                                           //         (
          //                                           //           context,
          //                                           //           error,
          //                                           //           stackTrace,
          //                                           //         ) {
          //                                           //           return Container(
          //                                           //             width: 122,
          //                                           //             height: 76,
          //                                           //             color: activity
          //                                           //                 .color
          //                                           //                 .withValues(alpha:
          //                                           //                   0.25,
          //                                           //                 ),
          //                                           //             child: Center(
          //                                           //               child: Image.asset(
          //                                           //                 activityIcons[activity
          //                                           //                     .name],
          //                                           //                 //'assets/icons/activity-nap-icon.png',
          //                                           //                 fit: BoxFit
          //                                           //                     .fill,
          //                                           //               ),
          //                                           //             ),
          //                                           //           );
          //                                           //         },
          //                                           //   )
          //                                               : Container(
          //                                             width: 122,
          //                                             height: 76,
          //                                             color: Colors.white,
          //                                             // color: activityColor
          //                                             //     .withValues(alpha:0.25),
          //                                             child: Center(
          //                                               child: Image.asset(
          //                                                 activityIcons[activity
          //                                                     .name],
          //                                                 //'assets/icons/activity-nap-icon.png',
          //                                                 fit: BoxFit.fill,
          //                                               ),
          //                                             ),
          //                                           ),
          //                                         ),
          //                                       ),
          //                                       const SizedBox(width: 12),
          //                                       Expanded(
          //                                         child: Column(
          //                                           crossAxisAlignment:
          //                                           CrossAxisAlignment.start,
          //                                           mainAxisAlignment:
          //                                           MainAxisAlignment
          //                                               .spaceEvenly,
          //                                           children: [
          //                                             Row(
          //                                               mainAxisAlignment:
          //                                               MainAxisAlignment
          //                                                   .spaceBetween,
          //                                               children: [
          //                                                 Container(
          //                                                   padding:
          //                                                   const EdgeInsets.symmetric(
          //                                                     horizontal: 12,
          //                                                     vertical: 6,
          //                                                   ),
          //                                                   decoration: BoxDecoration(
          //                                                     color: activityColor,
          //                                                     borderRadius:
          //                                                     BorderRadius.circular(
          //                                                       20,
          //                                                     ),
          //                                                   ),
          //                                                   child: Text(
          //                                                     activity.name,
          //                                                     style:
          //                                                     const TextStyle(
          //                                                       color: Colors
          //                                                           .white,
          //                                                       fontSize: 11,
          //                                                       fontWeight:
          //                                                       FontWeight
          //                                                           .bold,
          //                                                     ),
          //                                                   ),
          //                                                 ),
          //                                                 PopupMenuButton<String>(
          //                                                   icon: const Icon(
          //                                                     Icons.more_horiz,
          //                                                     size: 20,
          //                                                   ),
          //                                                   onSelected: null,
          //                                                   itemBuilder: (context) => [
          //                                                     PopupMenuItem<String>(
          //                                                       value: 'view',
          //                                                       child: PopupItem(
          //                                                         title: 'View',
          //                                                         icon: Icon(
          //                                                           Icons
          //                                                               .visibility_outlined,
          //                                                           color: AppColors
          //                                                               .themeColor,
          //                                                         ),
          //                                                       ),
          //                                                       onTap: () {
          //                                                         final destinationBuilder =
          //                                                         activityRoutes[activity
          //                                                             .name];
          //                                                         if (destinationBuilder !=
          //                                                             null) {
          //                                                           final nextScreen =
          //                                                           destinationBuilder(
          //                                                             activity,
          //                                                           );
          //                                                           Navigator.of(
          //                                                             context,
          //                                                           ).push(
          //                                                             MaterialPageRoute(
          //                                                               builder: (_) =>
          //                                                               nextScreen,
          //                                                             ),
          //                                                           );
          //                                                         }
          //                                                       },
          //                                                     ),
          //                                                     PopupMenuItem<String>(
          //                                                       value: 'edit',
          //                                                       child: PopupItem(
          //                                                         title: 'Edit',
          //                                                         icon: Icon(
          //                                                           Icons.edit,
          //                                                           color: AppColors
          //                                                               .themeColor,
          //                                                         ),
          //                                                       ),
          //                                                       onTap: () {
          //                                                         final destinationBuilder =
          //                                                         editActivityRoutes[activity
          //                                                             .name];
          //                                                         if (destinationBuilder !=
          //                                                             null) {
          //                                                           final nextScreen =
          //                                                           destinationBuilder(
          //                                                             activity,
          //                                                           );
          //                                                           Navigator.of(
          //                                                             context,
          //                                                           ).push(
          //                                                             MaterialPageRoute(
          //                                                               builder: (_) =>
          //                                                               nextScreen,
          //                                                             ),
          //                                                           );
          //                                                         }
          //                                                       },
          //                                                     ),
          //                                                     PopupMenuItem<String>(
          //                                                       value: 'delete',
          //                                                       child: PopupItem(
          //                                                         title: 'Delete',
          //                                                         icon: Icon(
          //                                                           Icons.delete,
          //                                                           color: AppColors
          //                                                               .themeColor,
          //                                                         ),
          //                                                       ),
          //                                                     ),
          //                                                   ],
          //                                                 ),
          //                                               ],
          //                                             ),
          //                                             const SizedBox(height: 10),
          //
          //                                             SizedBox(
          //                                               height: 32,
          //                                               child: Stack(
          //                                                 children: [
          //                                                   for (
          //                                                   int i = 0;
          //                                                   i < students.length &&
          //                                                       i < 4;
          //                                                   i++
          //                                                   )
          //                                                     Positioned(
          //                                                       left: i * 20,
          //                                                       child:
          //                                                       DocumentImageWidget(
          //                                                         fileUuid: '',
          //                                                         name:
          //                                                         students[i],
          //                                                         size: 28,
          //                                                         fontSize: 10,
          //                                                       ),
          //                                                     ),
          //
          //                                                   // Extra count tooltip
          //                                                   if (students.length > 4)
          //                                                     Positioned(
          //                                                       left:
          //                                                       4 *
          //                                                           20, // after 4 avatars
          //                                                       child: Tooltip(
          //                                                         message: students
          //                                                             .skip(4)
          //                                                             .join(', '),
          //                                                         child: DocumentImageWidget(
          //                                                           fileUuid: '',
          //                                                           name:
          //                                                           '+${students.length - 4}',
          //                                                           size: 28,
          //                                                           fontSize: 10,
          //                                                         ),
          //                                                       ),
          //                                                     ),
          //                                                 ],
          //                                               ),
          //                                             ),
          //                                             const SizedBox(height: 10),
          //
          //                                             Text(
          //                                               activity.description!,
          //
          //                                               style: TextStyle(
          //                                                 color: AppColors
          //                                                     .primaryColor,
          //                                                 fontSize: 14,
          //                                                 fontWeight:
          //                                                 FontWeight.w600,
          //                                               ),
          //                                               maxLines: 1,
          //                                               overflow:
          //                                               TextOverflow.ellipsis,
          //                                             ),
          //                                             const SizedBox(height: 10),
          //                                             Text(
          //                                               'Created By - ${activity.createdBy}',
          //
          //                                               style: TextStyle(
          //                                                 color: AppColors
          //                                                     .primaryColor,
          //                                                 fontSize: 12,
          //                                                 fontWeight:
          //                                                 FontWeight.w500,
          //                                               ),
          //                                               maxLines: 1,
          //                                               overflow:
          //                                               TextOverflow.ellipsis,
          //                                             ),
          //                                           ],
          //                                         ),
          //                                       ),
          //                                     ],
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         ],
          //                       ),
          //                     ],
          //                   );
          //                 },
          //               ),
          //             ],
          //           ),
          //         ),
          //     ],
          //   ),
          // );
        } else {
          return CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: widget.fromStudentProfile && !isNotParent
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 40,
                                child: AbsorbPointer(
                                  child: _buildCustomDropdown(
                                    'Select Student',
                                    widget.studentName != null
                                        ? [widget.studentName!]
                                        : <String>[],
                                    widget.studentName,
                                    (v) => setState(() {
                                      _selectedStudent = v;
                                    }),
                                    height: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: _datePickerFilter(
                                  selectedDate: _selectedDate,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _selectedDate = date;
                                    });
                                    _loadDailyFeed();
                                  },
                                ),
                              ),
                            ],
                          )
                        : isNotParent
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCustomMultiDropdown(
                                      'Select Classroom',
                                      _classroomOptions,
                                      _selectedClassrooms,
                                      (values) async {
                                        setState(() {
                                          _selectedClassrooms = values;
                                          _selectdClassroom = values.isNotEmpty
                                              ? values.first
                                              : null;
                                          _updateAvailableStudents();
                                        });
                                        if (values.isEmpty && isNotParent) {
                                          await _loadAllStudentsForAllowedClassrooms();
                                          await _loadDailyFeed(refresh: true);
                                        } else if (values.length > 1 &&
                                            isNotParent) {
                                          await _loadStudentsForSelectedClassrooms(
                                            values,
                                          );
                                          await _loadDailyFeed(refresh: true);
                                        } else {
                                          await _reloadStudentsAndSettingsThenFeed();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    // child: _buildCustomDropdown(
                                    //   'Select Student',
                                    //   _allStudents,
                                    //   _selectedStudent,
                                    //   (v) => setState(() {
                                    //     _selectedStudent = v;
                                    //   }),
                                    // ),
                                    child: _buildCustomMultiDropdown(
                                      'Select Student',
                                      _availableStudents,
                                      _selectedStudents,
                                      (values) {
                                        setState(() {
                                          _selectedStudents = values;
                                          _selectedStudent = values.isNotEmpty
                                              ? values.first
                                              : null;
                                        });
                                        _loadDailyFeed();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(100),
                                      onTap: _openActivityFilter,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: SvgPicture.asset(
                                              MediaRes.filterIcon,
                                              height: 20,
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final badgeCount =
                                                  _appliedFilterBadgeCount();
                                              if (badgeCount == 0) {
                                                return const SizedBox.shrink();
                                              }
                                              return Positioned(
                                                right: 2,
                                                top: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE01B5D),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    badgeCount > 99
                                                        ? '99+'
                                                        : '$badgeCount',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _datePickerFilter(
                                      selectedDate: _selectedDate,
                                      onDateSelected: (date) {
                                        setState(() {
                                          _selectedDate = date;
                                        });
                                        _loadDailyFeed();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CustomClearAllChip(
                                    onTap: () async {
                                      setState(() {
                                        final now = AppTime.now();
                                        _selectedDate = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );
                                        _selectdClassroom = null;
                                        _selectedClassrooms = <String>[];
                                        _selectedStudent = null;
                                        _selectedStudents = [];
                                        _filterActivityTypes.clear();
                                        _filterTags.clear();
                                        _filterApprovalStatuses.clear();
                                      });
                                      await _refreshDropdownsAfterClearAll();
                                      await _loadDailyFeed(refresh: true);
                                    },
                                    label: 'Clear All',
                                  ),
                                ],
                              ),
                            ],
                          )
                        : SizedBox(
                            height: 40,
                            child: _datePickerFilter(
                              selectedDate: _selectedDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                                _loadDailyFeed();
                              },
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                if ((_loadingFeed || _loadingParentContext) &&
                    _activities.isEmpty)
                  Expanded(
                    child: _portraitOverscrollFeedWrapper(
                      child: _dailyFeedLoadingSheet(context),
                    ),
                  ),

                if (!_loadingFeed &&
                    !_loadingParentContext &&
                    _activities.length == 0)
                  Expanded(
                    child: _portraitOverscrollFeedWrapper(
                      child: Padding(
                        padding: ResponsiveSizing.contentPadding(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: AppText.title(
                              _feedError ?? 'No Activities found',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title.copyWith(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_activities.length != 0)
                  Expanded(
                    child: Padding(
                      padding: ResponsiveSizing.activityFeedListPadding(
                        context,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _feedScrollController,
                              padding: EdgeInsets.zero,
                              itemCount:
                                  _activities.length +
                                  (_loadingMoreFeed ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _activities.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: PrimaryCircularLoader(
                                        size: 28,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  );
                                }
                                final activity = _activities[index];
                                final students = activity.studentList;
                                final Color activityColor =
                                    _colorPalette[index % _colorPalette.length];
                                final bool isHighlightTarget =
                                    _isHighlightTarget(activity.activityCode);
                                if (isHighlightTarget) {
                                  _scheduleHighlightScroll();
                                }

                                return HighlightableCard(
                                  key: isHighlightTarget
                                      ? _highlightCardKey
                                      : null,
                                  code: activity.activityCode,
                                  highlightCode: widget.highlightCode,
                                  borderRadius: 12,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  //color: activity.color,
                                                  color: activityColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Container(
                                                width: 4,
                                                height: 2,
                                                //color: activity.color,
                                                color: activityColor,
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: 100,
                                            height: 4,
                                            //color: activity.color,
                                            color: activityColor,
                                          ),
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              //color: activity.color,
                                              color: activityColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          SizedBox(
                                            height: 20,
                                            child: AppText.small(
                                              activity.time,
                                              style: AppTextStyles.small
                                                  .copyWith(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 7),
                                          Container(
                                            width: 4,
                                            height: 220,
                                            //color: activity.color,
                                            color: activityColor,
                                          ),

                                          const SizedBox(width: 16),

                                          // Activity Card
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 15),
                                                InkWell(
                                                  onTap: () async {
                                                    final hasStatusBadge =
                                                        activityApprovalStatusBadgeLabel(
                                                          activity
                                                              .approvalStatus,
                                                        ) !=
                                                        null;
                                                    final canOpenEdit =
                                                        hasStatusBadge &&
                                                        isNotParent &&
                                                        widget
                                                            .allowActivityWrite &&
                                                        canEditActivityItem(
                                                          activity,
                                                          isAdminPersona:
                                                              _isAdminPersona,
                                                          viewerStaffCode:
                                                              _viewerStaffCode,
                                                        );
                                                    final destinationBuilder =
                                                        canOpenEdit
                                                        ? editActivityRoutes[activity
                                                              .name]
                                                        : activityRoutes[activity
                                                              .name];
                                                    if (destinationBuilder !=
                                                        null) {
                                                      final nextScreen =
                                                          destinationBuilder(
                                                            activity,
                                                          );
                                                      await Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              nextScreen,
                                                        ),
                                                      );
                                                      if (mounted) {
                                                        await _loadDailyFeed(
                                                          refresh: true,
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          minHeight: 180,
                                                        ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 10,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: activityColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: Border.all(
                                                        color: activityColor
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          child: SizedBox(
                                                            width: 140,
                                                            height: 120,
                                                            child:
                                                                activityHasMediaOrProcessing(
                                                                  activity,
                                                                )
                                                                ? ActivityMediaPreview(
                                                                    activity:
                                                                        activity,
                                                                    activityColor:
                                                                        activityColor,
                                                                  )
                                                                // ? Image.network(
                                                                //     activity.photoUrl!,
                                                                //     fit: BoxFit.cover,
                                                                //     loadingBuilder:
                                                                //         (
                                                                //           context,
                                                                //           child,
                                                                //           loadingProgress,
                                                                //         ) {
                                                                //           if (loadingProgress ==
                                                                //               null)
                                                                //             return child;
                                                                //           return Container(
                                                                //             color: Colors
                                                                //                 .transparent,
                                                                //             child: const Center(
                                                                //               child: CircularProgressIndicator(
                                                                //                 strokeWidth:
                                                                //                     2,
                                                                //               ),
                                                                //             ),
                                                                //           );
                                                                //         },
                                                                //     errorBuilder:
                                                                //         (
                                                                //           context,
                                                                //           error,
                                                                //           stackTrace,
                                                                //         ) {
                                                                //           return Container(
                                                                //             width: 122,
                                                                //             height: 76,
                                                                //             color: activity
                                                                //                 .color
                                                                //                 .withValues(alpha:
                                                                //                   0.25,
                                                                //                 ),
                                                                //             child: Center(
                                                                //               child: Image.asset(
                                                                //                 activityIcons[activity
                                                                //                     .name],
                                                                //                 //'assets/icons/activity-nap-icon.png',
                                                                //                 fit: BoxFit
                                                                //                     .fill,
                                                                //               ),
                                                                //             ),
                                                                //           );
                                                                //         },
                                                                //   )
                                                                : Container(
                                                                    width: 122,
                                                                    height: 76,
                                                                    color: Colors
                                                                        .white,
                                                                    // color: activityColor
                                                                    //     .withValues(alpha:0.25),
                                                                    child: Center(
                                                                      child: Builder(
                                                                        builder: (_) {
                                                                          final iconPath =
                                                                              (activityIcons[activity.name] ??
                                                                                      MediaRes.notesActivityIcon)
                                                                                  .toString();
                                                                          if (iconPath.toLowerCase().endsWith(
                                                                            '.svg',
                                                                          )) {
                                                                            return SvgPicture.asset(
                                                                              iconPath,
                                                                              fit: BoxFit.contain,
                                                                            );
                                                                          }
                                                                          return Image.asset(
                                                                            iconPath,
                                                                            fit:
                                                                                BoxFit.fill,
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: Wrap(
                                                                        spacing:
                                                                            8,
                                                                        runSpacing:
                                                                            6,
                                                                        crossAxisAlignment:
                                                                            WrapCrossAlignment.center,
                                                                        children: [
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 12,
                                                                              vertical: 6,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: activityColor.withValues(
                                                                                alpha: 0.5,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                            ),
                                                                            child: Text(
                                                                              activity.name,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: const TextStyle(
                                                                                color: AppColors.primaryColor,
                                                                                fontSize: 12,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          if (activityApprovalStatusBadgeLabel(
                                                                                activity.approvalStatus,
                                                                              ) !=
                                                                              null)
                                                                            Container(
                                                                              padding: const EdgeInsets.symmetric(
                                                                                horizontal: 10,
                                                                                vertical: 6,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                color: activityApprovalStatusBadgeColor(
                                                                                  activity.approvalStatus,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(
                                                                                  4,
                                                                                ),
                                                                              ),
                                                                              child: Text(
                                                                                activityApprovalStatusBadgeLabel(
                                                                                      activity.approvalStatus,
                                                                                    ) ??
                                                                                    '',
                                                                                style: const TextStyle(
                                                                                  color: AppColors.primaryColor,
                                                                                  fontSize: 12,
                                                                                  fontWeight: FontWeight.w500,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  if (!isAttendanceCardActivityItem(
                                                                    activity,
                                                                  ))
                                                                    PopupMenuButton<
                                                                      String
                                                                    >(
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .more_horiz,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      onSelected:
                                                                          null,
                                                                      itemBuilder: (context) => [
                                                                        PopupMenuItem<
                                                                          String
                                                                        >(
                                                                          value:
                                                                              'view',
                                                                          child: PopupItem(
                                                                            title:
                                                                                'View',
                                                                            icon: Icon(
                                                                              Icons.visibility_outlined,
                                                                              color: AppColors.themeColor,
                                                                            ),
                                                                          ),
                                                                          onTap: () async {
                                                                            final destinationBuilder =
                                                                                activityRoutes[activity.name];
                                                                            if (destinationBuilder !=
                                                                                null) {
                                                                              final nextScreen = destinationBuilder(
                                                                                activity,
                                                                              );
                                                                              await Navigator.of(
                                                                                context,
                                                                              ).push(
                                                                                MaterialPageRoute(
                                                                                  builder:
                                                                                      (
                                                                                        _,
                                                                                      ) => nextScreen,
                                                                                ),
                                                                              );
                                                                              if (mounted) {
                                                                                await _loadDailyFeed(
                                                                                  refresh: true,
                                                                                );
                                                                              }
                                                                            }
                                                                          },
                                                                        ),
                                                                        if (isNotParent &&
                                                                            widget.allowActivityWrite &&
                                                                            canEditActivityItem(
                                                                              activity,
                                                                              isAdminPersona: _isAdminPersona,
                                                                              viewerStaffCode: _viewerStaffCode,
                                                                            ))
                                                                          PopupMenuItem<
                                                                            String
                                                                          >(
                                                                            value:
                                                                                'edit',
                                                                            child: PopupItem(
                                                                              title: 'Edit',
                                                                              icon: Icon(
                                                                                Icons.edit,
                                                                                color: AppColors.themeColor,
                                                                              ),
                                                                            ),
                                                                            onTap: () async {
                                                                              final destinationBuilder = editActivityRoutes[activity.name];
                                                                              if (destinationBuilder !=
                                                                                  null) {
                                                                                final nextScreen = destinationBuilder(
                                                                                  activity,
                                                                                );
                                                                                await Navigator.of(
                                                                                  context,
                                                                                ).push(
                                                                                  MaterialPageRoute(
                                                                                    builder:
                                                                                        (
                                                                                          _,
                                                                                        ) => nextScreen,
                                                                                  ),
                                                                                );
                                                                                if (mounted) {
                                                                                  await _loadDailyFeed(
                                                                                    refresh: true,
                                                                                  );
                                                                                }
                                                                              }
                                                                            },
                                                                          ),
                                                                        if (canAdminApproveOrRejectActivityItem(
                                                                              activity,
                                                                              isAdminPersona: _isAdminPersona,
                                                                            ) &&
                                                                            !isIncidentActivityItem(
                                                                              activity,
                                                                            )) ...[
                                                                          PopupMenuItem<
                                                                            String
                                                                          >(
                                                                            value:
                                                                                'approve',
                                                                            child: PopupItem(
                                                                              title: 'Approve',
                                                                              icon: Icon(
                                                                                Icons.check_circle_outline,
                                                                                color: AppColors.themeColor,
                                                                              ),
                                                                            ),
                                                                            onTap: () async {
                                                                              await _showApprovalActionBottomSheet(
                                                                                activity: activity,
                                                                                isApprove: true,
                                                                              );
                                                                            },
                                                                          ),
                                                                          PopupMenuItem<
                                                                            String
                                                                          >(
                                                                            value:
                                                                                'reject',
                                                                            child: PopupItem(
                                                                              title: 'Reject',
                                                                              icon: Icon(
                                                                                Icons.cancel_outlined,
                                                                                color: AppColors.themeColor,
                                                                              ),
                                                                            ),
                                                                            onTap: () async {
                                                                              await _showApprovalActionBottomSheet(
                                                                                activity: activity,
                                                                                isApprove: false,
                                                                              );
                                                                            },
                                                                          ),
                                                                        ],
                                                                        if (isNotParent &&
                                                                            widget.allowActivityWrite &&
                                                                            canDeleteActivityItem(
                                                                              activity,
                                                                              isAdminPersona: _isAdminPersona,
                                                                            ))
                                                                          PopupMenuItem<
                                                                            String
                                                                          >(
                                                                            value:
                                                                                'delete',
                                                                            onTap: () {
                                                                              showModalBottomSheet(
                                                                                context: context,
                                                                                isScrollControlled: true,
                                                                                backgroundColor: Colors.transparent,
                                                                                builder:
                                                                                    (
                                                                                      ctx,
                                                                                    ) {
                                                                                      return DeleteConfirmationBottomSheet(
                                                                                        name: activity.name,
                                                                                        type: 'Activity',
                                                                                        onDelete: () => _deleteActivityFromSheet(
                                                                                          ctx,
                                                                                          activity,
                                                                                        ),
                                                                                        onCancel: () {
                                                                                          Navigator.of(
                                                                                            ctx,
                                                                                          ).pop();
                                                                                        },
                                                                                      );
                                                                                    },
                                                                              );
                                                                            },
                                                                            child: PopupItem(
                                                                              title: 'Delete',
                                                                              icon: Icon(
                                                                                Icons.delete,
                                                                                color: AppColors.themeColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),

                                                              activityFeedStudentAvatarStack(
                                                                students,
                                                                studentCodes:
                                                                    feedStudentCodesForNames(
                                                                      activity,
                                                                    ),
                                                                onOpenStudentList: () =>
                                                                    showActivityStudentListSheet(
                                                                      context,
                                                                      students,
                                                                      studentCodes:
                                                                          feedStudentCodesForNames(
                                                                            activity,
                                                                          ),
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),

                                                              Text(
                                                                activityFeedCardBodyLine(
                                                                  activity,
                                                                ),
                                                                style: AppTextStyles.body.copyWith(
                                                                  color: AppColors
                                                                      .primaryColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  height: 1.0,
                                                                ),
                                                                strutStyle: StrutStyle(
                                                                  fontFamily: Fonts
                                                                      .manrope,
                                                                  fontSize: 14,
                                                                  height: 1.0,
                                                                  leading: 0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  forceStrutHeight:
                                                                      true,
                                                                ),
                                                                textHeightBehavior:
                                                                    const TextHeightBehavior(
                                                                      applyHeightToFirstAscent:
                                                                          false,
                                                                      applyHeightToLastDescent:
                                                                          false,
                                                                    ),
                                                                maxLines:
                                                                    activityFeedCardBodyMaxLines(
                                                                      activity,
                                                                    ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              AppText.small(
                                                                'Created By - ${activity.createdBy}',
                                                                style: AppTextStyles.small.copyWith(
                                                                  color: AppColors
                                                                      .primaryColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _datePickerFilter({
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => CalendarDialog(
            isTimePicker: false,
            initialDate: selectedDate,
            whiteBgColor: true,
          ),
        );

        if (result != null && result['date'] != null) {
          onDateSelected(result['date'] as DateTime);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFACEAEC).withValues(alpha: 0.102),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(selectedDate)
                      : 'Select Date',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: selectedDate == null
                        ? Colors.grey[600]
                        : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                MediaRes.calender_icon,
                height: 20.0,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDropdown(
    String hintText,
    List<String> items,
    String? selectedItem,
    ValueChanged<String?> onSelect, {
    bool isRequired = false,
    double? height,
  }) {
    return CustomDropdown(
      label: null,
      hintText: hintText,
      height: height ?? 40,
      items: items,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: selectedItem != null && selectedItem.trim().isNotEmpty
            ? Colors.black87
            : Colors.grey[600],
      ),
      popupItemTextStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  Widget _buildCustomMultiDropdown(
    String hintText,
    List<String> items,
    List<String> selectedItems,
    ValueChanged<List<String>> onChanged, {
    double? height,
  }) {
    return SizedBox(
      height: height ?? 40,
      child: CustomMultiSelectDropdown(
        hintText: hintText,
        items: items,
        selectedItems: selectedItems,
        onChanged: onChanged,
        gapHeight: 8,
        maxDropdownHeight: 280,
      ),
    );
  }
}

class PopupItem extends StatelessWidget {
  final String title;
  final Icon icon;

  const PopupItem({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

String _bathroomSubtypeDisplayForFeed(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  final lower = s.toLowerCase();
  if (lower == 'bm') return 'BM';
  if (lower == 'wet') return 'Wet';
  return s;
}

bool _bathroomFeedTypeIsDiaper(String? typeRaw) {
  return (typeRaw ?? '').toLowerCase().contains('diaper');
}

bool _bathroomFeedTypeIsPeeTrack(String? typeRaw) {
  final s = (typeRaw ?? '').trim().toLowerCase();
  if (s.contains('diaper')) return false;
  return s.contains('pee') || s.contains('potty');
}

bool _looksLikeSystemGeneratedDetailText(String activityName, String desc) {
  final d = desc.trim().toLowerCase();
  if (d.isEmpty) return false;
  if (d.contains('\n')) return true;
  switch (activityName) {
    case 'Bathroom':
      return d.contains('diaper') ||
          d.contains('potty') ||
          d.contains('pee') ||
          d.contains('bm') ||
          d.contains('wet') ||
          d.contains('dry');
    case 'Meal':
      return d.contains('quantity') ||
          d.contains('breakfast') ||
          d.contains('lunch') ||
          d.contains('snack') ||
          d.contains('dinner');
    case 'Bottle':
      return d.contains('oz') ||
          d.contains('consum') ||
          d.contains('intake') ||
          d.contains('left');
    case 'Nap Start':
    case 'Nap End':
      return d.contains('nap') && d.contains('at');
    case 'Learning':
      return d.contains('category') || d.contains('activity name');
    default:
      return false;
  }
}

String _joinPrimaryAndOptionalDescription({
  required String activityName,
  required String primary,
  String? description,
  String separator = '\n',
}) {
  final p = primary.trim();
  final d = (description ?? '').trim();
  if (p.isEmpty) return d;
  if (d.isEmpty) return p;
  final pn = p.toLowerCase();
  final dn = d.toLowerCase();
  if (pn == dn || pn.contains(dn) || dn.contains(pn)) return p;
  if (_looksLikeSystemGeneratedDetailText(activityName, d)) return p;
  return '$p$separator$d';
}

/// Feed card line under student avatars (Meal / Bottle / Nap / Learning / Bathroom + description).
String activityFeedCardBodyLine(ActivityItem activity) {
  if (activity.name == 'Meal') {
    final mt = activity.mealType?.trim();
    final mq = activity.mealQuantity?.trim();
    final desc = activity.description?.trim();

    String? firstLine;
    if (mt != null && mt.isNotEmpty && mq != null && mq.isNotEmpty) {
      firstLine = '$mt Quantity: $mq';
    } else if (mt != null && mt.isNotEmpty) {
      firstLine = mt;
    } else if (mq != null && mq.isNotEmpty) {
      firstLine = 'Quantity: $mq';
    }

    if (firstLine != null && firstLine.isNotEmpty) {
      return _joinPrimaryAndOptionalDescription(
        activityName: activity.name,
        primary: firstLine,
        description: desc,
      );
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Bottle') {
    final desc = activity.description?.trim();
    final consumedLine = _formatBottleOzConsumedLine(activity.amountConsumed);
    final st = activity.bottleConsumptionStatus?.trim();
    final stClean = (st == null || st.isEmpty)
        ? null
        : st.replaceAll(RegExp(r'[\s,;]+$'), '').trim();

    String? primary;
    if (stClean != null &&
        stClean.isNotEmpty &&
        consumedLine != null &&
        consumedLine.isNotEmpty) {
      primary = '$stClean · $consumedLine';
    } else if (consumedLine != null && consumedLine.isNotEmpty) {
      primary = consumedLine;
    } else if (stClean != null && stClean.isNotEmpty) {
      primary = stClean;
    }

    if (primary != null && primary.isNotEmpty) {
      return _joinPrimaryAndOptionalDescription(
        activityName: activity.name,
        primary: primary,
        description: desc,
        separator: ' · ',
      );
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Nap Start' || activity.name == 'Nap End') {
    final desc = activity.description?.trim();
    final isStart = activity.name == 'Nap Start';

    String _fmtNapTime(String? raw, String fallback) {
      final s = raw?.trim() ?? '';
      if (s.isEmpty) return fallback;
      try {
        final parsed = DateFormat('HH:mm').parse(s);
        return DateFormat.jm().format(parsed);
      } catch (_) {
        try {
          final parsed = DateFormat('h:mm a').parse(s);
          return DateFormat.jm().format(parsed);
        } catch (_) {
          return s;
        }
      }
    }

    final at = isStart
        ? _fmtNapTime(activity.napStartTime, activity.time.trim())
        : _fmtNapTime(
            activity.napEndTime,
            _fmtNapTime(activity.napStartTime, activity.time.trim()),
          );
    final firstLine = at.isNotEmpty
        ? 'Nap ${isStart ? 'started' : 'ended'} at $at'
        : 'Nap';
    return _joinPrimaryAndOptionalDescription(
      activityName: activity.name,
      primary: firstLine,
      description: desc,
    );
  }
  if (activity.name == 'Learning') {
    final at = activity.activityType?.trim();
    final cats = activity.categoryType;
    final desc = activity.description?.trim();
    final parts = <String>[];
    if (at != null && at.isNotEmpty) parts.add(at);
    if (cats != null && cats.isNotEmpty) {
      final c = cats.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
      if (c.isNotEmpty) parts.add(c);
    }
    if (parts.isNotEmpty) {
      final first = parts.join(' · ');
      return _joinPrimaryAndOptionalDescription(
        activityName: activity.name,
        primary: first,
        description: desc,
      );
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Bathroom') {
    final tRaw = activity.bathroomType?.trim();
    final stRaw = activity.bathroomSubType?.trim();
    final sizeRaw = activity.bathroomDiaperSize?.trim();
    final desc = activity.description?.trim();
    final stDisp = _bathroomSubtypeDisplayForFeed(stRaw);

    String? firstLine;
    if (_bathroomFeedTypeIsDiaper(tRaw)) {
      if (stDisp.isNotEmpty) {
        firstLine = (sizeRaw != null && sizeRaw.isNotEmpty)
            ? 'Diaper (Size : $sizeRaw) · $stDisp'
            : 'Diaper · $stDisp';
      } else if (sizeRaw != null && sizeRaw.isNotEmpty) {
        firstLine = 'Diaper (Size : $sizeRaw)';
      } else if (tRaw != null && tRaw.isNotEmpty) {
        firstLine = tRaw;
      } else {
        firstLine = 'Diaper';
      }
    } else if (_bathroomFeedTypeIsPeeTrack(tRaw) && stDisp.isNotEmpty) {
      firstLine = 'Pee · $stDisp';
    } else {
      final parts = <String>[];
      if (tRaw != null && tRaw.isNotEmpty) parts.add(tRaw);
      if (stRaw != null && stRaw.isNotEmpty) parts.add(stRaw);
      if (parts.isNotEmpty) {
        firstLine = parts.join(' · ');
      }
    }

    if (firstLine != null && firstLine.isNotEmpty) {
      return _joinPrimaryAndOptionalDescription(
        activityName: activity.name,
        primary: firstLine,
        description: desc,
      );
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Sign-in' ||
      activity.name == 'Sign-out' ||
      activity.name == 'Transfer' ||
      activity.name == 'Marked Absent') {
    final d = activity.description?.trim();
    return (d != null && d.isNotEmpty) ? d : 'No description';
  }
  final d = activity.description?.trim();
  return (d != null && d.isNotEmpty) ? d : 'No description';
}

int activityFeedCardBodyMaxLines(ActivityItem activity) {
  if (activity.name == 'Bottle') return 2;
  if (activity.name == 'Meal') return 3;
  if (activity.name == 'Nap Start' || activity.name == 'Nap End') return 4;
  if (activity.name == 'Learning') return 3;
  if (activity.name == 'Bathroom') return 3;
  if (activity.name == 'Sign-in' ||
      activity.name == 'Sign-out' ||
      activity.name == 'Transfer' ||
      activity.name == 'Marked Absent') {
    return 2;
  }
  return 1;
}

double? _parseBottleOzNumber(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw.trim();
  if (t.toUpperCase().contains('OZ')) {
    final numPart = t.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numPart);
  }
  return double.tryParse(t.replaceAll(',', ''));
}

String _formatOzAmountString(double n) {
  if (n == n.roundToDouble()) {
    return n.round().toString();
  }
  final fixed = n.toStringAsFixed(4);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String? _formatBottleOzCompact(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw.trim();
  final n = _parseBottleOzNumber(raw);
  if (n != null) {
    return '${_formatOzAmountString(n)} OZ';
  }
  if (t.toUpperCase().contains('OZ')) {
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  return t;
}

/// Feed subtitle line, e.g. `0.5 OZ consumed`.
String? _formatBottleOzConsumedLine(String? raw) {
  final n = _parseBottleOzNumber(raw);
  if (n == null) return null;
  return '${_formatOzAmountString(n)} OZ consumed';
}

/// Public for bottle detail view; same numeric formatting as the feed (`6 OZ`).
String? formatBottleAmountForDisplay(String? raw) =>
    _formatBottleOzCompact(raw);

/// Activity types where the API may return one feed row per student; adjacent
/// rows that match the same logged event are merged for display.
const Set<String> _mergeableMultiStudentActivityNames = {
  'Meal',
  'Bottle',
  'Notes',
  'Nap Start',
  'Nap End',
  'Nap',
  'Bathroom',
  'Learning',
  'Outdoor',
  'Medication',
  'Photo',
  'Video',
};

const Set<String> _attendanceMergeableActivityNames = {
  'Sign-in',
  'Sign-out',
  'Transfer',
  'Marked Absent',
};

bool activityItemsMergeableForFeedDisplay(ActivityItem a, ActivityItem b) {
  if (_attendanceMergeableActivityNames.contains(a.name)) {
    if (a.name != b.name) return false;
    if (a.time != b.time) return false;
    if (a.date != b.date) return false;
    if ((a.classroomCode ?? '') != (b.classroomCode ?? '')) return false;
    if ((a.description ?? '') != (b.description ?? '')) return false;
    final scA = a.studentCode?.trim() ?? '';
    final scB = b.studentCode?.trim() ?? '';
    if (scA.isNotEmpty && scA == scB) return false;
    return true;
  }

  if (!_mergeableMultiStudentActivityNames.contains(a.name)) return false;
  if (a.name != b.name) return false;
  if ((a.activityTypeCode ?? '') != (b.activityTypeCode ?? '')) return false;
  if ((a.classroomCode ?? '') != (b.classroomCode ?? '')) return false;
  if ((a.activityDateIso ?? '') != (b.activityDateIso ?? '')) return false;
  if ((a.description ?? '') != (b.description ?? '')) return false;
  if (a.name == 'Photo' || a.name == 'Video') {
    final aMedia = (a.photoUrl ?? a.videoUrl ?? '').trim();
    final bMedia = (b.photoUrl ?? b.videoUrl ?? '').trim();
    if (aMedia.isEmpty || aMedia != bMedia) return false;
  }
  final scA = a.studentCode?.trim() ?? '';
  final scB = b.studentCode?.trim() ?? '';
  if (scA.isNotEmpty && scA == scB) return false;
  if (a.name == 'Meal') {
    if (a.mealType != b.mealType) return false;
    if (a.mealQuantity != b.mealQuantity) return false;
  }
  if (a.name == 'Bottle') {
    if (a.amountConsumed != b.amountConsumed) return false;
    if (a.bottleConsumptionStatus != b.bottleConsumptionStatus) return false;
  }
  if (a.name == 'Bathroom') {
    if ((a.bathroomType ?? '') != (b.bathroomType ?? '')) return false;
    if ((a.bathroomSubType ?? '') != (b.bathroomSubType ?? '')) return false;
    if ((a.bathroomDiaperSize ?? '') != (b.bathroomDiaperSize ?? '')) {
      return false;
    }
  }
  return true;
}

List<Map<String, String>>? _mergedStudentActivityRefsForFeed(
  ActivityItem a,
  ActivityItem b,
) {
  final out = <Map<String, String>>[];
  void add(ActivityItem x) {
    final r = x.studentActivityRefs;
    if (r != null && r.isNotEmpty) {
      for (final m in r) {
        out.add(Map<String, String>.from(m));
      }
    } else {
      for (final name in x.studentList) {
        final nm = name.trim();
        if (nm.isEmpty) continue;
        out.add({
          'name': nm,
          'studentCode': x.studentCode?.trim() ?? '',
          'activityCode': x.activityCode?.trim() ?? '',
        });
      }
    }
  }

  add(a);
  add(b);
  final seen = <String>{};
  final unique = <Map<String, String>>[];
  for (final m in out) {
    final ac = (m['activityCode'] ?? '').trim();
    if (ac.isNotEmpty) {
      if (seen.contains(ac)) continue;
      seen.add(ac);
      unique.add(m);
      continue;
    }
    final sc = (m['studentCode'] ?? '').trim();
    final nm = (m['name'] ?? '').trim();
    final key = '$sc|$nm';
    if (seen.contains(key)) continue;
    seen.add(key);
    unique.add(m);
  }
  return unique.isEmpty ? null : unique;
}

ActivityItem mergeTwoActivityItemsForFeed(ActivityItem a, ActivityItem b) {
  final names = <String>[];
  void addUnique(Iterable<String> list) {
    for (final n in list) {
      final t = n.trim();
      if (t.isEmpty) continue;
      if (!names.contains(t)) names.add(t);
    }
  }

  addUnique(a.studentList);
  addUnique(b.studentList);
  if (names.isEmpty) names.add('Student');

  final mergedRefs = _mergedStudentActivityRefsForFeed(a, b);

  return ActivityItem(
    time: a.time,
    date: a.date,
    name: a.name,
    description: a.description,
    photoUrl: a.photoUrl ?? b.photoUrl,
    videoUrl: a.videoUrl ?? b.videoUrl,
    studentList: names,
    createdBy: preferActivityAuthorLabel(a.createdBy, b.createdBy),
    activityType: a.activityType,
    categoryType: a.categoryType,
    mealType: a.mealType,
    mealQuantity: a.mealQuantity,
    amountConsumed: a.amountConsumed,
    bottleConsumptionStatus: a.bottleConsumptionStatus,
    napStartTime: a.napStartTime,
    remainderOn: a.remainderOn,
    napEndTime: a.napEndTime,
    whatHappened: a.whatHappened,
    firstAidAdministered: a.firstAidAdministered,
    staffPresent: preferActivityAuthorLabel(
      a.staffPresent ?? '',
      b.staffPresent ?? '',
    ),
    staffPresentCode: (a.staffPresentCode ?? '').trim().isNotEmpty
        ? a.staffPresentCode!.trim()
        : ((b.staffPresentCode ?? '').trim().isNotEmpty
              ? b.staffPresentCode!.trim()
              : null),
    additionalNotes: a.additionalNotes,
    bathroomType: a.bathroomType,
    bathroomSubType: a.bathroomSubType,
    bathroomDiaperSize: a.bathroomDiaperSize ?? b.bathroomDiaperSize,
    activityTypeCode: a.activityTypeCode,
    activityCode: a.activityCode,
    studentCode: a.studentCode,
    classroomCode: a.classroomCode,
    activityDateIso: a.activityDateIso,
    snapshotAttachments: a.snapshotAttachments ?? b.snapshotAttachments,
    studentActivityRefs: mergedRefs,
    approvalStatus: a.approvalStatus ?? b.approvalStatus,
  );
}

List<ActivityItem> mergeAdjacentMultiStudentFeedItems(
  List<ActivityItem> items,
) {
  if (items.length < 2) return items;
  final out = <ActivityItem>[items.first];
  for (var i = 1; i < items.length; i++) {
    final prev = out.last;
    final cur = items[i];
    if (activityItemsMergeableForFeedDisplay(prev, cur)) {
      out[out.length - 1] = mergeTwoActivityItemsForFeed(prev, cur);
    } else {
      out.add(cur);
    }
  }
  return out;
}

String? _feedGroupKeyForItem(
  ActivityItem x, {
  required bool attendanceRequireDateAndTimeMatch,
}) {
  final name = x.name;
  if (_attendanceMergeableActivityNames.contains(name)) {
    final time = x.time.trim();
    if (time.isEmpty) return null;
    final date = x.date.trim();
    final cc = (x.classroomCode ?? '').trim();
    final desc = (x.description ?? '').trim();
    final dtPart = attendanceRequireDateAndTimeMatch
        ? '|$date|$time'
        : '|$time';
    return 'ATT|$name$dtPart|$cc|$desc';
  }

  if (!_mergeableMultiStudentActivityNames.contains(name)) return null;

  final typeCode = (x.activityTypeCode ?? '').trim();
  final cc = (x.classroomCode ?? '').trim();
  final iso = (x.activityDateIso ?? '').trim();
  final desc = (x.description ?? '').trim();
  final media = (x.photoUrl ?? x.videoUrl ?? '').trim();
  final mealType = (x.mealType ?? '').trim();
  final mealQty = (x.mealQuantity ?? '').trim();
  final bottleAmt = (x.amountConsumed ?? '').trim();
  final bottleStatus = (x.bottleConsumptionStatus ?? '').trim();
  final bathType = (x.bathroomType ?? '').trim();
  final bathSub = (x.bathroomSubType ?? '').trim();
  final bathSize = (x.bathroomDiaperSize ?? '').trim();

  return [
    'ACT',
    name,
    typeCode,
    cc,
    iso,
    desc,
    media,
    mealType,
    mealQty,
    bottleAmt,
    bottleStatus,
    bathType,
    bathSub,
    bathSize,
  ].join('|');
}

List<ActivityItem> groupMultiStudentFeedItems(
  List<ActivityItem> items, {
  required bool attendanceRequireDateAndTimeMatch,
}) {
  if (items.length < 2) return items;

  final out = <ActivityItem>[];
  final indexByKey = <String, int>{};

  for (final item in items) {
    final key = _feedGroupKeyForItem(
      item,
      attendanceRequireDateAndTimeMatch: attendanceRequireDateAndTimeMatch,
    );
    if (key == null) {
      out.add(item);
      continue;
    }
    final existingIndex = indexByKey[key];
    if (existingIndex == null) {
      indexByKey[key] = out.length;
      out.add(item);
      continue;
    }
    out[existingIndex] = mergeTwoActivityItemsForFeed(out[existingIndex], item);
  }

  return out;
}

String? activityApprovalStatusBadgeLabel(String? rawStatus) {
  final raw = (rawStatus ?? '').trim().toUpperCase();
  if (raw.isEmpty || raw == 'ACTIVE') return null;
  switch (raw) {
    case 'NOT_REQUIRED':
      return 'Not Required';
    case 'PENDING_ADMIN_APPROVAL':
      return 'Pending';
    case 'APPROVED':
      return 'Approved';
    case 'REJECTED':
      return 'Rejected';
    case 'PARENT_ACKNOWLEDGEMENT_PENDING':
      return 'Pending Acknowledgement';
    case 'ACKNOWLEDGED':
      return 'Acknowledged';
    default:
      return raw
          .split('_')
          .where((e) => e.isNotEmpty)
          .map((e) => '${e[0]}${e.substring(1).toLowerCase()}')
          .join(' ');
  }
}

Color activityApprovalStatusBadgeColor(String? rawStatus) {
  final raw = (rawStatus ?? '').trim().toUpperCase();
  switch (raw) {
    case 'NOT_REQUIRED':
      return const Color(0xFFE7E7E7);
    case 'PENDING_ADMIN_APPROVAL':
      return const Color(0xFFF3DE8A);
    case 'APPROVED':
      return const Color(0xFFBFE9D0);
    case 'REJECTED':
      return const Color(0xFFFFC8C8);
    case 'PARENT_ACKNOWLEDGEMENT_PENDING':
      return const Color(0xFFF3DE8A);
    case 'ACKNOWLEDGED':
      return const Color(0xFFBFE9D0);
    default:
      return const Color(0xFFE9E2F7);
  }
}

/// Rebuilds UI model from `GET /api/v1/activities/code/{code}` for edit prefetch.
ActivityItem activityItemFromActivityDetail(
  ActivityDetail detail, {
  String? viewerDisplayName,
}) {
  return activityItemFromFeedRow(
    ActivityFeedRow.fromActivityDetail(detail),
    viewerDisplayName: viewerDisplayName,
    activityTypeOptionCodeToLabel: activityFeedOptionLabelsForType(
      detail.activityTypeCode,
    ),
  );
}

/// Maps [ActivityItem] to student maps used by create/edit activity screens.
List<Map<String, dynamic>> studentDataMapsForActivityEdit(
  ActivityItem activity,
) {
  final room = activity.classroomCode?.trim();
  final refs = activity.studentActivityRefs;
  if (refs != null && refs.isNotEmpty) {
    return refs
        .map(
          (r) => <String, dynamic>{
            'name': (r['name'] ?? '').trim().isEmpty
                ? 'Student'
                : (r['name'] ?? '').trim(),
            if ((r['studentCode'] ?? '').trim().isNotEmpty)
              'studentCode': r['studentCode']!.trim(),
            if (room != null && room.isNotEmpty) 'classroomCode': room,
            if ((r['activityCode'] ?? '').trim().isNotEmpty)
              'activityCode': r['activityCode']!.trim(),
          },
        )
        .toList();
  }
  final code = activity.studentCode?.trim();
  final maps = <Map<String, dynamic>>[];
  for (final name in activity.studentList) {
    maps.add({
      'name': name,
      if (code != null && code.isNotEmpty) 'studentCode': code,
      if (room != null && room.isNotEmpty) 'classroomCode': room,
      if ((activity.activityCode ?? '').trim().isNotEmpty)
        'activityCode': activity.activityCode!.trim(),
    });
  }
  if (maps.isEmpty && activity.studentList.isEmpty) {
    maps.add({'name': 'Student'});
  }
  return maps;
}

/// Student codes aligned (by index) to [activity.studentList], so feed-card
/// avatars can resolve the real profile photo instead of showing initials.
/// Uses [ActivityItem.studentActivityRefs] (name→code), falling back to the
/// single `studentCode` for single-student activities.
List<String?> feedStudentCodesForNames(ActivityItem activity) {
  final refs = activity.studentActivityRefs;
  final byName = <String, String>{};
  if (refs != null) {
    for (final r in refs) {
      final n = (r['name'] ?? '').trim();
      final c = (r['studentCode'] ?? '').trim();
      if (n.isNotEmpty && c.isNotEmpty) byName[n] = c;
    }
  }
  final fallback = (activity.studentCode ?? '').trim();
  final single = activity.studentList.length == 1;
  return activity.studentList.map<String?>((name) {
    final c = byName[name.trim()];
    if (c != null && c.isNotEmpty) return c;
    if (single && fallback.isNotEmpty) return fallback;
    return null;
  }).toList();
}

/// Option code → label for activity type definitions (`GET …/activity-types/{code}`).
final Map<String, Map<String, String>> _activityFeedOptionLabelCache = {};

Future<void> ensureActivityFeedOptionLabelsForType(
  String activityTypeCode,
) async {
  final c = activityTypeCode.trim();
  if (c.isEmpty) return;
  if (_activityFeedOptionLabelCache.containsKey(c)) return;
  try {
    final uc = serviceLocator<GetActivityTypeDetailsUseCase>();
    final d = await uc(code: c);
    final map = <String, String>{};
    for (final param in d.parameters) {
      for (final o in param.options) {
        final lbl = (o.optionLabel ?? '').trim();
        if (lbl.isEmpty) continue;
        final oc = (o.optionCode ?? '').trim();
        final rawCode = o.code.trim();
        if (oc.isNotEmpty) map[oc] = lbl;
        if (rawCode.isNotEmpty && rawCode != oc) map[rawCode] = lbl;
      }
    }
    _activityFeedOptionLabelCache[c] = map;
  } catch (_) {
    _activityFeedOptionLabelCache[c] = {};
  }
}

Future<void> primeActivityFeedOptionLabelsFromRows(
  Iterable<ActivityFeedRow> rows,
) async {
  final codes = <String>{};
  for (final r in rows) {
    if (mapApiActivityTypeNameToUiLabel(r.activityTypeName) != 'Learning')
      continue;
    final code = r.activityTypeCode.trim();
    if (code.isNotEmpty) codes.add(code);
  }
  await Future.wait(codes.map(ensureActivityFeedOptionLabelsForType));
}

Map<String, String>? activityFeedOptionLabelsForType(String activityTypeCode) {
  final map = _activityFeedOptionLabelCache[activityTypeCode.trim()];
  if (map == null || map.isEmpty) return null;
  return map;
}

String? _resolveLearningFeedParamDisplay(
  Map<String, dynamic> p,
  Map<String, String> codeToLabel,
) {
  for (final key in ['selectedOptionLabel', 'optionLabel']) {
    final v = (p[key] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }

  final dt = (p['dataType'] ?? '').toString().toUpperCase();
  if (dt == 'DATE') {
    final d = (p['valueDate'] ?? '').toString().trim();
    if (d.isNotEmpty) return d;
  }
  if (dt == 'TIME') {
    final t = (p['valueTime'] ?? '').toString().trim();
    if (t.isNotEmpty) return t;
  }

  final sel = (p['selectedOptionCode'] ?? '').toString().trim();
  if (sel.isNotEmpty) {
    final hit = codeToLabel[sel];
    if (hit != null && hit.isNotEmpty) return hit;
  }

  for (final key in ['valueText', 'valueNumber']) {
    final raw = (p[key] ?? '').toString().trim();
    if (raw.isEmpty) continue;
    final hit = codeToLabel[raw];
    if (hit != null && hit.isNotEmpty) return hit;
    return raw;
  }
  return null;
}

/// Maps backend [ActivityFeedRow.activityTypeName] to UI keys used in [activityRoutes].
String mapApiActivityTypeNameToUiLabel(String apiName) {
  final s = apiName.toLowerCase().trim();
  if (s.isEmpty) return 'Notes';
  if (s.contains('nap')) {
    if (s.contains('start')) return 'Nap Start';
    if (s.contains('end') || s.contains('stop') || s.contains('wake')) {
      return 'Nap End';
    }
    return 'Nap Start';
  }
  if (s.contains('bathroom') || s.contains('potty') || s.contains('diaper')) {
    return 'Bathroom';
  }
  if (s.contains('bottle')) return 'Bottle';
  if (s.contains('meal') ||
      s.contains('lunch') ||
      s.contains('breakfast') ||
      s.contains('snack')) {
    return 'Meal';
  }
  if (s.contains('incident')) return 'Incident';
  if (s.contains('medication') || s.contains('medicine')) {
    return 'Medication';
  }
  if (s.contains('outdoor') || s.contains('outside')) return 'Outdoor';
  if (s.contains('learning')) return 'Learning';
  if (s.contains('photo') && !s.contains('video')) return 'Photo';
  if (s.contains('video')) return 'Video';
  if (s.contains('note')) return 'Notes';
  if (s.contains('sign') && s.contains('in')) return 'Sign-in';
  if (s.contains('sign') && s.contains('out')) return 'Sign-out';
  if (s.contains('absent')) return 'Marked Absent';
  return apiName.trim();
}

ActivityItem activityItemFromFeedRow(
  ActivityFeedRow row, {
  String? viewerDisplayName,
  String? schoolIana,
  Map<String, String>? staffDisplayNameByCode,
  Map<String, String>? activityTypeOptionCodeToLabel,
}) {
  bool? _boolFromAny(dynamic raw) {
    if (raw is bool) return raw;
    final v = (raw ?? '').toString().trim().toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
    return null;
  }

  bool? _pickNapFlagFromParameters(bool wantEnd) {
    for (final p in row.parameterValues) {
      final name = (p['parameterName'] ?? '').toString().toLowerCase().trim();
      if (!name.contains('nap')) continue;
      final hasTarget = wantEnd
          ? (name.contains('end') ||
                name.contains('wake') ||
                name.contains('stop'))
          : (name.contains('start') || name.contains('begin'));
      if (!hasTarget) continue;
      final fromBool = _boolFromAny(p['valueBool']);
      if (fromBool != null) return fromBool;
      final fromText = _boolFromAny(p['valueText']);
      if (fromText != null) return fromText;
      final fromOption = _boolFromAny(p['selectedOptionLabel']);
      if (fromOption != null) return fromOption;
    }
    return null;
  }

  DateTime dt;
  try {
    final parsed = DateTime.parse(row.activityDateIso);
    final iana = (schoolIana ?? '').trim();
    dt = iana.isEmpty
        ? parsed.toLocal()
        : SchoolZoneDateTime.dateTimeFromInstantInSchool(parsed, iana);
  } catch (_) {
    dt = AppTime.now();
  }
  final time = DateFormat.jm().format(dt);
  final date = DateFormat('MMMM d, yyyy').format(dt);
  var name = mapApiActivityTypeNameToUiLabel(row.activityTypeName);
  final rowNapEnd = row.napEnd ?? _pickNapFlagFromParameters(true);
  final rowNapStart = row.napStart ?? _pickNapFlagFromParameters(false);
  if (name == 'Nap Start' || name == 'Nap End') {
    if (rowNapEnd == true) {
      name = 'Nap End';
    } else if (rowNapStart == true) {
      name = 'Nap Start';
    }
  }

  String? photoUrl;
  String? videoUrl;
  for (final a in row.attachments) {
    final mt = (a['mediaType'] ?? '').toString().toLowerCase();
    // Fall back to processed variant URLs so images already render even while
    // the backend still reports status == PROCESSING (deliveryUrl null).
    final u = attachmentUsableDeliveryUrl(a);
    if (u.isEmpty) continue;
    if (mt.contains('video') ||
        u.toLowerCase().endsWith('.mp4') ||
        u.toLowerCase().endsWith('.mov')) {
      videoUrl ??= u;
    } else {
      photoUrl ??= u;
    }
  }

  String? pickParam(bool Function(String n) match) {
    for (final p in row.parameterValues) {
      final n = (p['parameterName'] ?? '').toString().toLowerCase();
      if (!match(n)) continue;
      if (name == 'Learning') {
        final m = activityTypeOptionCodeToLabel;
        if (m != null && m.isNotEmpty) {
          final resolved = _resolveLearningFeedParamDisplay(p, m);
          if (resolved != null && resolved.isNotEmpty) return resolved;
        }
      }
      // Prefer human-readable labels (dropdowns) before option codes in valueText.
      for (final key in <String>[
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
        'valueTime',
        'valueDatetime',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  String? pickStaffPresentFromParameters() {
    for (final p in row.parameterValues) {
      final n = (p['parameterName'] ?? '').toString().toLowerCase();
      if (n != 'staff present') continue;
      final dt = (p['dataType'] ?? '').toString().toUpperCase();
      if (dt == 'DATE' || dt == 'TIME') continue;
      for (final key in <String>[
        'selectedOptionCode',
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  String? paramDisplay(Map<String, dynamic> p) {
    for (final key in <String>[
      'selectedOptionLabel',
      'valueText',
      'valueNumber',
      'valueTime',
      'valueDatetime',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  /// Prefer [valueNumber] when present so fractional oz (e.g. 0.5) is not
  /// replaced by a stale [valueText] such as "0".
  String? bottleVolumeSingleParam(Map<String, dynamic> p) {
    final vnRaw = p['valueNumber'];
    final vnStr = vnRaw != null ? vnRaw.toString().trim() : '';
    final vn = vnStr.isNotEmpty
        ? double.tryParse(vnStr.replaceAll(',', ''))
        : null;

    String? textVal;
    for (final key in <String>[
      'selectedOptionLabel',
      'optionLabel',
      'valueText',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) {
        textVal = v;
        break;
      }
    }

    double? numFromText;
    if (textVal != null) {
      final m = RegExp(
        r'(\d+(?:\.\d+)?)',
      ).firstMatch(textVal.replaceAll(',', ''));
      if (m != null) {
        numFromText = double.tryParse(m.group(1)!);
      }
    }

    if (vn != null && numFromText != null && numFromText > 0) {
      if ((vn - 2 * numFromText).abs() < 0.001) {
        return numFromText == numFromText.roundToDouble()
            ? numFromText.round().toString()
            : numFromText.toString();
      }
    }

    if (vnRaw != null && vnStr.isNotEmpty) {
      return vnStr;
    }
    for (final key in <String>[
      'selectedOptionLabel',
      'optionLabel',
      'valueText',
      'valueTime',
      'valueDatetime',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  String? pickParamBottleVolume() {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      final isVol =
          pn.contains('amount') ||
          pn.contains('ounce') ||
          pn.contains('volume') ||
          pn.contains(' ml') ||
          RegExp(r'\boz\b').hasMatch(pn);
      if (!isVol || pn.contains('consumption')) continue;
      final vol = bottleVolumeSingleParam(p);
      if (vol != null && vol.isNotEmpty) return vol;
    }
    return null;
  }

  String? bottleVolumeFromParams;
  String? bottleStatusFromParams;
  if (name == 'Bottle') {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      final dt = (p['dataType'] ?? '').toString().toUpperCase();
      if (pn.contains('staff')) continue;
      if (dt == 'DATE' || dt == 'TIME') continue;
      if (pn == 'description' || (pn.contains('description') && dt == 'TEXT'))
        continue;
      final isConsumptionDropdown =
          dt == 'DROPDOWN' &&
          (pn.contains('consum') ||
              pn.contains('intake') ||
              pn.contains('status') ||
              pn.contains('left'));
      final isConsumptionText =
          !pn.contains('amount') &&
          !pn.contains('ounce') &&
          !pn.contains('volume') &&
          (pn.contains('consum') || pn.contains('intake'));
      if (isConsumptionDropdown || isConsumptionText) {
        final val = paramDisplay(p);
        if (val == null || val.isEmpty) continue;
        bottleStatusFromParams ??= val;
        continue;
      }
      final isVolume =
          pn.contains('amount') ||
          pn.contains('ounce') ||
          pn.contains('volume') ||
          pn.contains(' ml') ||
          RegExp(r'\boz\b').hasMatch(pn);
      if (isVolume) {
        final vol = bottleVolumeSingleParam(p);
        if (vol != null && vol.isNotEmpty) {
          bottleVolumeFromParams ??= vol;
        }
      }
    }
  }

  final amountConsumed = name == 'Bottle'
      ? (bottleVolumeFromParams ??
            pickParamBottleVolume() ??
            pickParam(
              (n) =>
                  (n.contains('amount') ||
                      n.contains('ounce') ||
                      n.contains('oz')) &&
                  !n.contains('consumption'),
            ))
      : pickParam(
          (n) =>
              n.contains('amount') ||
              n.contains('ounce') ||
              n.contains('oz') ||
              n.contains('consumed'),
        );
  final mealType =
      pickParam((n) => n.contains('meal') && n.contains('type')) ??
      pickParam((n) => n.contains('meal') && !n.contains('quantity'));
  final mealQuantity = name == 'Meal'
      ? pickParam(
          (n) =>
              (n.contains('quant') || n.contains('portion')) &&
              !n.contains('meal type'),
        )
      : pickParam((n) => n.contains('quantity') || n.contains('portion'));
  final napStartTime =
      pickParam((n) => n.contains('nap') && n.contains('start')) ??
      pickParam((n) => n.contains('start') && n.contains('nap'));
  final napEndTime =
      pickParam(
        (n) => n.contains('nap') && (n.contains('end') || n.contains('stop')),
      ) ??
      pickParam(
        (n) =>
            n.contains('end') &&
            n.contains('nap') &&
            (n.contains('time') || n.contains('stop')),
      );

  /// Single "Time" param (e.g. PM_027) when nap start/end params are absent.
  final napTimeParam = pickParam((n) => n.trim().toLowerCase() == 'time');
  final bathroomType =
      pickParam((n) => n.contains('bathroom') && n.contains('type')) ??
      pickParam((n) => n.contains('potty') || n.contains('diaper'));
  final bathroomSubType =
      pickParam((n) => n.contains('sub') && n.contains('type')) ??
      pickParam((n) => n.contains('subtype'));

  String? pickBathroomDiaperSizeFromParams() {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      if (!pn.contains('size')) continue;
      if (pn.contains('subtype')) continue;
      if (pn.contains('sub type')) continue;
      for (final key in <String>[
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  final bathroomDiaperSizeLabel = name == 'Bathroom'
      ? pickBathroomDiaperSizeFromParams()
      : null;

  final desc = row.description.trim();
  final napDescription = (name == 'Nap End')
      ? 'Nap Ended'
      : (name == 'Nap Start' ? 'Nap Started' : '');
  final effectiveDescription = desc.isNotEmpty
      ? desc
      : (napDescription.isNotEmpty ? napDescription : '');
  final studentNamesFromApi = row.students
      .map((s) => (s['name'] ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final studentName = row.studentDisplayName.isEmpty
      ? 'Student'
      : row.studentDisplayName;
  final studentListForItem = studentNamesFromApi.isNotEmpty
      ? studentNamesFromApi
      : [studentName];
  final staffFromParams = pickStaffPresentFromParameters();
  final mappedStaffName = (() {
    final raw = (staffFromParams ?? '').trim();
    if (raw.isEmpty) return null;
    final resolved = staffDisplayNameByCode?[raw]?.trim() ?? '';
    if (resolved.isNotEmpty) return resolved;
    return raw;
  })();
  final by = resolveActivityCreatedByForUi(
    rawCreatedBy: '',
    staffLabelFromParameters: mappedStaffName,
    viewerDisplayNameFallback: null,
  );

  /// Learning: API stores these in [parameterValues] (e.g. PM_054 Activity Name, PM_055 Categories).
  final String? learningActivityName = name == 'Learning'
      ? (pickParam(
              (n) =>
                  n.contains('activity') &&
                  (n.contains('name') || n.contains('type')),
            ) ??
            pickParam((n) => n.contains('learning') && !n.contains('categor')))
      : null;
  final String? learningCategory = name == 'Learning'
      ? pickParam((n) => n.contains('categor'))
      : null;

  final sc = (row.studentCode ?? '').trim();
  final ac = (row.activityCode ?? '').trim();

  /// Incident's "Additional Notes" (CUSTOM parameter, distinct from "What
  /// happened?" which the API already surfaces via [row.description]) has
  /// no flat field on [ActivityFeedRow] — it must be read out of
  /// [row.parameterValues] like every other custom parameter (bathroomType,
  /// mealType, …) below.
  final additionalNotesFromParams = name == 'Incident'
      ? pickParam((n) => n.contains('additional') && n.contains('note'))
      : null;

  return ActivityItem(
    time: time,
    date: date,
    name: name,
    description: effectiveDescription.isEmpty ? null : effectiveDescription,
    photoUrl: photoUrl,
    videoUrl: videoUrl,
    studentList: studentListForItem,
    createdBy: by,
    activityType: learningActivityName,
    categoryType: learningCategory != null && learningCategory.isNotEmpty
        ? [learningCategory]
        : null,
    mealType: name == 'Meal' ? mealType : null,
    mealQuantity: name == 'Meal' ? mealQuantity : null,
    amountConsumed: name == 'Bottle' ? amountConsumed : null,
    bottleConsumptionStatus: name == 'Bottle' ? bottleStatusFromParams : null,
    napStartTime: (name == 'Nap Start' || name == 'Nap End')
        ? (napStartTime ?? napTimeParam)
        : null,
    napEndTime: name == 'Nap End' ? (napEndTime ?? napTimeParam) : null,
    whatHappened:
        (name == 'Incident' || name == 'Notes') &&
            effectiveDescription.isNotEmpty
        ? effectiveDescription
        : null,
    additionalNotes: additionalNotesFromParams,
    staffPresent: by,
    staffPresentCode: (staffFromParams ?? '').trim().isEmpty
        ? null
        : staffFromParams!.trim(),
    bathroomType: name == 'Bathroom' ? bathroomType : null,
    bathroomSubType: name == 'Bathroom' ? bathroomSubType : null,
    bathroomDiaperSize: name == 'Bathroom' ? bathroomDiaperSizeLabel : null,
    activityTypeCode: row.activityTypeCode.trim().isEmpty
        ? null
        : row.activityTypeCode.trim(),
    activityCode: ac.isEmpty ? null : ac,
    studentCode: sc.isEmpty ? null : sc,
    classroomCode: (row.classroomCode ?? '').trim().isEmpty
        ? null
        : row.classroomCode!.trim(),
    activityDateIso: row.activityDateIso.trim().isEmpty
        ? null
        : row.activityDateIso.trim(),
    snapshotAttachments: row.attachments.isEmpty
        ? null
        : row.attachments.map((e) => Map<String, dynamic>.from(e)).toList(),
    studentActivityRefs: row.students.isNotEmpty
        ? row.students
              .map(
                (s) => <String, String>{
                  'name': (s['name'] ?? '').trim(),
                  if ((s['studentCode'] ?? '').trim().isNotEmpty)
                    'studentCode': s['studentCode']!.trim(),
                  if (ac.isNotEmpty) 'activityCode': ac,
                },
              )
              .where((m) => (m['name'] ?? '').isNotEmpty)
              .toList()
        : [
            {
              'name': studentName,
              if (sc.isNotEmpty) 'studentCode': sc,
              if (ac.isNotEmpty) 'activityCode': ac,
            },
          ],
    approvalStatus: row.approvalStatus,
  );
}
