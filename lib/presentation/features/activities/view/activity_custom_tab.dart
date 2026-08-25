import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../app/di/di.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/guardian_code_resolver.dart';
import '../../../../core/util/activity_feed_invalidation.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/staff_code_resolver.dart';
import '../../../../core/util/school_timezone_resolver.dart';
import '../../../../core/util/school_zone_datetime.dart';
import '../../../../domain/features/activity/entities/activity_feed_row.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../cubit/activity_feed_scope_cubit.dart';
import '../cubit/activity_moderation_cubit.dart';
import '../../../../shared/common/app/cubit/role_cubit.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/student_attendance_absent_form.dart'
    hide StudentAttendanceTime;
import '../utils/activity_parent_feed_merge.dart';
import '../widgets/activity_feed_student_avatar.dart';
import 'activity_filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import '../widgets/avtivity_media_preview.dart';

/// Feed card model + permissions (`activity_feed_card_permissions.dart`) come through this barrel export.
import 'activity_daily_tab.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/nap_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';

class ActivityCustomTab extends StatelessWidget {
  const ActivityCustomTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.studentProfile,
    this.isNotParent = true,
    this.allowActivityWrite = true,
    this.onRefreshStaffSignInStatus,
    this.initialActivityTypes,
    this.initialClassrooms,
    this.resetKey,
  });

  final bool fromStudentProfile;
  final String? studentName;

  /// Full student context ({name, studentCode, classroom, classroomCode, …})
  /// when launched from a student profile. Used to lock the feed to that student
  /// (by studentCode) and resolve its classroom, mirroring [ActivityDailyTab].
  final Map<String, dynamic>? studentProfile;
  final bool isNotParent;

  /// Edit / delete; false when [DAILY_ACTIVITY] has `write: false`.
  final bool allowActivityWrite;

  /// Re-checks the staff persona's today sign-in status (drives the parent
  /// screen's Add-activity FAB gate). Invoked on manual pull-to-refresh so the
  /// FAB reflects a sign-in/out done elsewhere without needing an app restart.
  final Future<void> Function()? onRefreshStaffSignInStatus;

  /// Pre-selected activity types.
  final List<String>? initialActivityTypes;

  /// Pre-selected classrooms.
  final List<String>? initialClassrooms;

  /// Used to force state reset in didUpdateWidget when navigating repeatedly.
  final String? resetKey;

  static const String routeName = '/activityCustomTab';

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ActivityFeedScopeCubit>(
          create: (_) => serviceLocator<ActivityFeedScopeCubit>(),
        ),
        BlocProvider<ActivityModerationCubit>(
          create: (_) => serviceLocator<ActivityModerationCubit>(),
        ),
      ],
      child: _ActivityCustomTabView(
        fromStudentProfile: fromStudentProfile,
        studentName: studentName,
        studentProfile: studentProfile,
        isNotParent: isNotParent,
        allowActivityWrite: allowActivityWrite,
        onRefreshStaffSignInStatus: onRefreshStaffSignInStatus,
        initialActivityTypes: initialActivityTypes,
        initialClassrooms: initialClassrooms,
        resetKey: resetKey,
      ),
    );
  }
}

class _ActivityCustomTabView extends StatefulWidget {
  const _ActivityCustomTabView({
    this.fromStudentProfile = false,
    this.studentName,
    this.studentProfile,
    this.isNotParent = true,
    this.allowActivityWrite = true,
    this.onRefreshStaffSignInStatus,
    this.initialActivityTypes,
    this.initialClassrooms,
    this.resetKey,
  });

  final bool fromStudentProfile;
  final String? studentName;
  final Map<String, dynamic>? studentProfile;
  final bool isNotParent;
  final bool allowActivityWrite;
  final Future<void> Function()? onRefreshStaffSignInStatus;
  final List<String>? initialActivityTypes;
  final List<String>? initialClassrooms;
  final String? resetKey;

  @override
  State<_ActivityCustomTabView> createState() => _ActivityCustomTabViewState();
}

class _ActivityCustomTabViewState extends State<_ActivityCustomTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late bool isNotParent;
  bool get _parentHome => !isNotParent && !widget.fromStudentProfile;

  DateTime? _selectedStartDate = DateTime(
    AppTime.now().year,
    AppTime.now().month,
    1,
  );
  DateTime? _selectedEndDate = DateTime(
    AppTime.now().year,
    AppTime.now().month + 1,
    0,
  );
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
  String? _feedError;
  String? _schoolCode;
  String _viewerStaffDisplayName = '';
  String _viewerStaffCode = '';
  final Map<String, String> _staffDisplayNameByCode = {};
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _classroomNameByCode = {};
  final Map<String, String> _studentCodeByName = {};
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  Map<String, String> _tagNameToCode = {};
  final Set<String> _studentCodesForTagFilter = {};
  final Set<String> _parentAllowedStudentCodes = {};
  final Map<String, String> _parentStudentClassroomByCode = {};
  bool _loadingParentContext = false;
  bool _isFeedRequestInFlight = false;
  bool _forceAllClassroomsOnLoad = false;
  String? _lastFeedRequestKey;
  String? _lastGlobalSelectedStudentCode;
  DateTime? _lastFeedCompletedAt;
  bool _lastFeedCompletedWithError = false;
  String? _lastResolvedClassroomCode;
  // Pull a large merged window so all three APIs are unified before render.
  static const int _feedPageSize = 1000;
  final ScrollController _feedScrollController = ScrollController();
  bool _feedHasMore = false;
  bool _loadingMoreFeed = false;
  int _feedNextPage = 0;

  // Staff persona scoping
  List<String> _allowedClassroomCodes = const [];
  String? _primaryClassroomCode;

  ActivityFeedScopeCubit get _feedScope =>
      context.read<ActivityFeedScopeCubit>();
  ActivityModerationCubit get _moderationCubit =>
      context.read<ActivityModerationCubit>();
  StreamSubscription<ActivityModerationState>? _moderationSub;
  late final StorageService _storageService;
  late final CacheManager _cacheManager;
  StreamSubscription<void>? _feedInvalidationSub;
  bool _isAdminPersona = false;

  final List<String> activityType = [
    'Sign-in',
    'Sign-out',
    'Transfer',
    'Marked Absent',
  ];
  final Map<String, List<String>> classroomStudents = {};
  // final List<String> _allStudents = [
  //   'Raghave Gupta',
  //   'Rohan Gupta',
  //   'Ruhi Gupta',
  //   'Anya Mehta',
  //   'Kabir Mehta',
  //   'Sara Khan',
  // ];
  final List<String> _classroomOptions = [];
  final List<ActivityItem> activities = [];

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

  @override
  void didUpdateWidget(covariant _ActivityCustomTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool changed = false;

    // If resetKey changes, we force apply the initial filters again
    final bool forceReset =
        widget.resetKey != oldWidget.resetKey && widget.resetKey != null;

    if (forceReset ||
        widget.initialActivityTypes != oldWidget.initialActivityTypes) {
      if (widget.initialActivityTypes != null &&
          widget.initialActivityTypes!.isNotEmpty) {
        _filterActivityTypes = List.from(widget.initialActivityTypes!);
        changed = true;
      }
    }

    if (forceReset || widget.initialClassrooms != oldWidget.initialClassrooms) {
      if (widget.initialClassrooms != null &&
          widget.initialClassrooms!.isNotEmpty) {
        _selectedClassrooms = List.from(widget.initialClassrooms!);
        if (_selectedClassrooms.length == 1 &&
            _selectedClassrooms.first.toLowerCase() == 'all') {
          _forceAllClassroomsOnLoad = true;
          _selectdClassroom = null;
          if (_classroomOptions.isNotEmpty) {
            _selectedClassrooms = List.from(_classroomOptions);
          } else {
            _selectedClassrooms = [];
          }
        } else {
          _selectdClassroom = _selectedClassrooms.first;
        }
        changed = true;
      }
    }

    if (changed) {
      // Re-run filter logic and fetch feed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRangeFeed(refresh: true);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _storageService = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storageService);
    _moderationSub = _moderationCubit.stream.listen(_onModerationState);

    isNotParent = widget.isNotParent;
    // Opened from a student profile: pre-select that student (and their
    // classroom) in the admin filter row so the range feed is filtered to them
    // and the dropdowns reflect it on the first frame, instead of showing an
    // empty "Select Student" while the lists load.
    _seedProfileContext();
    _updateAvailableStudents();
    //_selectedStudent = _allStudents[0];

    // Apply initial filters passed from the route
    if (widget.initialActivityTypes != null &&
        widget.initialActivityTypes!.isNotEmpty) {
      _filterActivityTypes = List.from(widget.initialActivityTypes!);
    }
    if (widget.initialClassrooms != null &&
        widget.initialClassrooms!.isNotEmpty) {
      _selectedClassrooms = List.from(widget.initialClassrooms!);
      if (_selectedClassrooms.length == 1 &&
          _selectedClassrooms.first.toLowerCase() == 'all') {
        _forceAllClassroomsOnLoad = true;
        _selectdClassroom = null;
        if (_classroomOptions.isNotEmpty) {
          _selectedClassrooms = List.from(_classroomOptions);
        } else {
          _selectedClassrooms = [];
        }
      } else {
        _selectdClassroom = _selectedClassrooms.first;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapSchoolZone();
      // Feed is locked to the profile student's code + classroom already, so
      // load it right away rather than waiting for the classroom/student
      // bootstrap; _loadRangeFeed de-dupes so the later bootstrap won't refetch.
      if (widget.fromStudentProfile && widget.studentProfile != null) {
        final school =
            (await _storageService.getString(StorageKeys.schoolCode) ?? '')
                .trim();
        if (school.isNotEmpty && mounted) {
          _schoolCode = school;
          unawaited(_loadRangeFeed(refresh: true));
        }
      }
      await _bootstrapRangeFeed();
    });
    _feedScrollController.addListener(_onFeedScroll);
    _feedInvalidationSub = ActivityFeedInvalidation.onInvalidated.listen((_) {
      if (mounted) {
        _loadRangeFeed(refresh: true);
      }
    });
  }

  Future<void> _bootstrapSchoolZone() async {
    try {
      final z = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: serviceLocator<ApiClient>(),
      );
      if (!mounted) return;
      final today = SchoolZoneDateTime.schoolCalendarTodayOnly(z);
      setState(() {
        _schoolIana = z;
        _selectedStartDate = DateTime(today.year, today.month, 1);
        _selectedEndDate = DateTime(today.year, today.month + 1, 0);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _feedInvalidationSub?.cancel();
    _moderationSub?.cancel();
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
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
        _loadRangeFeed(refresh: true);
      }
    } else if (state is ActivityModerationFailure) {
      CoreUtils.logApiError(
        state.message,
        showOnScreen: true,
        context: context,
      );
    }
  }

  void _onFeedScroll() {
    _maybeLoadNextRangeFeedPage();
  }

  void _maybeLoadNextRangeFeedPage() {
    if (!_feedScrollController.hasClients) return;
    if (_loadingMoreFeed || !_feedHasMore || _isFeedRequestInFlight) {
      return;
    }
    final position = _feedScrollController.position;
    if (position.maxScrollExtent <= 0) {
      _loadNextRangeFeedPage();
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextRangeFeedPage();
    }
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
    // Opened from a student profile: lock the feed to that student's code so the
    // range feed only shows their activities (name→code resolution can miss
    // before the student list loads, which let other students' activities leak
    // through).
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
    final fromSelectedStudents = classroomStudents.entries
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

    // Opened from a student profile: fall back to the student's classroom CODE
    // so the range feed resolves the room even before the name→code maps load.
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

  // `t.hour`/`.minute`/`.second` are SCHOOL-local wall-clock fields (the
  // attendance API has no timezone context of its own — see
  // [StudentAttendanceTimeModel.fromJson]). The DateTime built here is
  // therefore only valid for DISPLAY formatting; it must NOT be fed to
  // `.toIso8601String()` directly for [ActivityItem.activityDateIso] — Dart
  // would interpret these school-local field values as DEVICE-local and
  // compute the wrong UTC instant whenever the device's timezone differs
  // from the school's. Use [_wallClockToUtcIso] for the ISO field instead.
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

  /// Converts a SCHOOL-local wall-clock [DateTime] (as produced by
  /// [_attendanceClockToDateTime]/[_absentClockToDateTime]) into the correct
  /// UTC instant, for use as [ActivityItem.activityDateIso] — the field the
  /// cross-source sort comparator (`_activityDateTimeOrEpoch`) relies on.
  /// Without this, attendance/absent-sourced rows sort against a wrong
  /// instant (offset by device-tz vs school-tz) while activity-feed rows
  /// (whose ISO comes untouched from the backend) sort correctly, producing
  /// a source-clustered order instead of true chronological interleaving.
  String _wallClockToUtcIso(DateTime schoolWallClock) {
    return SchoolZoneDateTime.utcFromSchoolWallClockDateTime(
      schoolWallClock,
      _schoolIana,
    ).toIso8601String();
  }

  DateTime _activityDateTimeOrEpoch(ActivityItem item) {
    // Prefer the full-precision ISO instant \u2014 every source (activity feed,
    // attendance daily, absent records) already populates [activityDateIso]
    // with real second-level precision. The display `date`/`time` strings
    // below are formatted with DateFormat.jm() ("10:15 AM"), which never
    // includes seconds, so trying them FIRST (as this used to) meant two
    // rows occurring in the same minute always collapsed to an identical
    // sort key and silently fell through to the alphabetical tiebreak in
    // [_compareActivityItemsByTimeDesc] instead of true chronological order.
    final iso = (item.activityDateIso ?? '').trim();
    if (iso.isNotEmpty) {
      try {
        return SchoolZoneDateTime.dateTimeFromInstantInSchool(
          DateTime.parse(iso),
          _schoolIana,
        );
      } catch (_) {}
    }

    final cardDate = item.date.trim();
    final normalizedTime = item.time
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u202f', ' ')
        .trim();

    if (cardDate.isNotEmpty && normalizedTime.isNotEmpty) {
      try {
        final day = DateFormat('MMMM d, yyyy').parseLoose(cardDate);
        final parsedTime = DateFormat.jm().parseLoose(normalizedTime);
        return DateTime(
          day.year,
          day.month,
          day.day,
          parsedTime.hour,
          parsedTime.minute,
          parsedTime.second,
        );
      } catch (_) {}
    }

    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  int _compareActivityItemsByTimeDesc(ActivityItem a, ActivityItem b) {
    final byTime = _activityDateTimeOrEpoch(
      b,
    ).compareTo(_activityDateTimeOrEpoch(a));
    if (byTime != 0) return byTime;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    final aStudents = a.studentList.join(',').toLowerCase();
    final bStudents = b.studentList.join(',').toLowerCase();
    return aStudents.compareTo(bStudents);
  }

  List<ActivityItem> _sortItemsByLatestFirst(Iterable<ActivityItem> items) {
    final sorted = List<ActivityItem>.from(items);
    sorted.sort(_compareActivityItemsByTimeDesc);
    return sorted;
  }

  List<ActivityItem> get _displayActivities =>
      _sortItemsByLatestFirst(activities);

  List<ActivityItem> _itemsFromAttendancePage(StudentAttendanceDailyPage page) {
    if (!_shouldIncludeAttendanceEntries()) return const <ActivityItem>[];
    final eventFilter = _selectedAttendanceEventFilter();
    final selectedClassroomName = _selectdClassroom;
    final selectedClassroomCode = selectedClassroomName != null
        ? _classroomCodeByName[selectedClassroomName]
        : null;
    final out = <ActivityItem>[];
    for (final row in page.items) {
      DateTime rowDay;
      try {
        final attendanceDateSrc = (row.attendanceDate ?? '').trim();
        if (attendanceDateSrc.isNotEmpty) {
          rowDay = DateTime.parse(attendanceDateSrc);
        } else {
          final src = (row.signedInAt ?? row.signedOutAt ?? '').trim();
          rowDay = src.isEmpty
              ? (_selectedStartDate ?? AppTime.now())
              : SchoolZoneDateTime.dateTimeFromInstantInSchool(
                  DateTime.parse(src),
                  _schoolIana,
                );
        }
      } catch (_) {
        rowDay = _selectedStartDate ?? AppTime.now();
      }
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
              _attendanceClockToDateTime(row.transferTime, rowDay) ??
              _attendanceClockToDateTime(row.nextActionTime, rowDay) ??
              rowDay;
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
              activityDateIso: _wallClockToUtcIso(at),
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
        // Backend may return the final sign-out time on the last transfer row.
        if ((eventFilter == null || eventFilter == 'Sign-out') &&
            row.signedOutTime != null) {
          final at =
              _attendanceClockToDateTime(row.signedOutTime, rowDay) ?? rowDay;
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
              activityDateIso: _wallClockToUtcIso(at),
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
        final at =
            _attendanceClockToDateTime(row.signedInTime, rowDay) ?? rowDay;
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
            activityDateIso: _wallClockToUtcIso(at),
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
        final at =
            _attendanceClockToDateTime(row.signedOutTime, rowDay) ?? rowDay;
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
            activityDateIso: _wallClockToUtcIso(at),
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
    return _sortItemsByLatestFirst(_withClientFilters(out));
  }

  List<ActivityItem> _itemsFromAbsentRecordsPage(
    StudentAttendanceAbsentFormPage page,
  ) {
    final out = <ActivityItem>[];
    for (final row in page.items) {
      DateTime rowDay;
      try {
        final src = row.absenceDate.trim();
        rowDay = src.isEmpty
            ? (_selectedStartDate ?? AppTime.now())
            : DateTime.parse(src);
      } catch (_) {
        rowDay = _selectedStartDate ?? AppTime.now();
      }
      final at = _absentClockToDateTime(row.markedAbsentTime, rowDay) ?? rowDay;
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
          activityDateIso: _wallClockToUtcIso(at),
          studentActivityRefs: <Map<String, String>>[
            {
              'name': studentName,
              if (studentCode.isNotEmpty) 'studentCode': studentCode,
            },
          ],
        ),
      );
    }
    return _sortItemsByLatestFirst(_withClientFilters(out));
  }

  Future<void> _loadNextRangeFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _isFeedRequestInFlight) return;

    if (_parentHome) {
      return _loadNextParentHomeRangeFeedPage();
    }

    final classroomCodes = _selectedClassroomCodesForFeed();
    final classroomCode = classroomCodes.isNotEmpty
        ? classroomCodes.first
        : null;
    if (classroomCode == null || classroomCode.trim().isEmpty) return;

    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (start == null || end == null) return;
    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    var studentCodes = _selectedStudentCodesForAttendanceFilter();
    if ((studentCodes == null || studentCodes.isEmpty) &&
        _selectedStudents.isNotEmpty &&
        isNotParent) {
      await _loadAllStudentsForAllowedClassrooms();
      if (!mounted) return;
      studentCodes = _selectedStudentCodesForAttendanceFilter();
    }
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
      final typeCodes = _activityTypeCodesForApiFilter();
      final approvalStatuses = _approvalStatusesForApiFilter();
      final pageIndex = _feedNextPage;

      final includeAttendance =
          _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();
      final activityFeedPage = await _feedScope.getRangeActivityFeed(
        classroomCode: classroomCode,
        startDate: _dateQueryParam(start),
        endDate: _dateQueryParam(end),
        studentCode: selectedStudentCode,
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        activityTypeCodes: typeCodes,
        approvalStatuses: approvalStatuses,
        guardianPersona: _parentHome,
        page: pageIndex,
        size: _feedPageSize,
      );
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (includeAttendance) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _feedScope.getStudentAbsentRecordsActivity(
            fromAbsenceDate: _dateQueryParam(start),
            toAbsenceDate: _dateQueryParam(end),
            classroomCodes: classroomCodes,
            studentCodes: studentCodes,
            page: pageIndex,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final startStr = _dateQueryParam(start);
          final endStr = _dateQueryParam(end);
          final dailyAbsent = await Future.wait([
            _feedScope.getStudentAttendanceDaily(
              attendanceDate: startStr,
              fromAttendanceDate: startStr,
              toAttendanceDate: endStr,
              classroomCodes: classroomCodes,
              studentCodes: studentCodes,
              signInAtFilter: null,
              signOutAtFilter: null,
              page: pageIndex,
              size: _feedPageSize,
            ),
            _feedScope.getStudentAbsentRecordsActivity(
              fromAbsenceDate: startStr,
              toAbsenceDate: endStr,
              classroomCodes: classroomCodes,
              studentCodes: studentCodes,
              page: pageIndex,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _feedScope.getStudentAttendanceDaily(
            attendanceDate: _dateQueryParam(start),
            fromAttendanceDate: _dateQueryParam(start),
            toAttendanceDate: _dateQueryParam(end),
            classroomCodes: classroomCodes,
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
        if (attendancePage != null) ..._itemsFromAttendancePage(attendancePage),
        if (absentPage != null) ..._itemsFromAbsentRecordsPage(absentPage),
        ..._itemsFromActivityFeedPage(activityFeedPage),
      ];
      final sortedItems = _sortItemsByLatestFirst(items);

      if (!mounted) return;
      setState(() {
        activities.addAll(sortedItems);
        final grouped = _sortItemsByLatestFirst(
          groupMultiStudentFeedItems(
            activities,
            attendanceRequireDateAndTimeMatch: true,
          ),
        );
        activities
          ..clear()
          ..addAll(grouped);
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
          (_) => _maybeLoadNextRangeFeedPage(),
        );
      }
    }
  }

  Future<void> _loadParentHomeRangeFeed({bool refresh = false}) async {
    final school = _schoolCode;
    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (school == null ||
        school.isEmpty ||
        start == null ||
        end == null ||
        _parentAllowedStudentCodes.isEmpty) {
      if (mounted) {
        setState(() {
          activities.clear();
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }
    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    final codes = _parentAllowedStudentCodes.toList()..sort();
    final selectedEvent = _selectedAttendanceEventFilter();
    final requestKey = [
      'parentRange',
      school,
      codes.join(','),
      _dateQueryParam(start),
      _dateQueryParam(end),
      selectedEvent ?? '',
      _filterActivityTypes.join(','),
      _filterTags.join(','),
      _filterApprovalStatuses.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      if (_isFeedRequestInFlight) return;
      if (!_lastFeedCompletedWithError) return;
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          AppTime.nowUtc().difference(completedAt) <
              const Duration(seconds: 3)) {
        return;
      }
    }

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    try {
      final signInAtFilter =
          (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
          ? 'NOT_NULL'
          : null;
      final signOutAtFilter =
          (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
          ? 'NOT_NULL'
          : null;
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (_filterApprovalStatuses.isEmpty &&
          _shouldIncludeAttendanceEntries()) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _feedScope.getStudentAbsentRecordsActivity(
            fromAbsenceDate: _dateQueryParam(start),
            toAbsenceDate: _dateQueryParam(end),
            studentCodes: codes,
            page: 0,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final startStr = _dateQueryParam(start);
          final endStr = _dateQueryParam(end);
          final dailyAbsent = await Future.wait([
            _feedScope.getStudentAttendanceDaily(
              attendanceDate: startStr,
              fromAttendanceDate: startStr,
              toAttendanceDate: endStr,
              studentCodes: codes,
              signInAtFilter: null,
              signOutAtFilter: null,
              page: 0,
              size: _feedPageSize,
            ),
            _feedScope.getStudentAbsentRecordsActivity(
              fromAbsenceDate: startStr,
              toAbsenceDate: endStr,
              studentCodes: codes,
              page: 0,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _feedScope.getStudentAttendanceDaily(
            attendanceDate: _dateQueryParam(start),
            fromAttendanceDate: _dateQueryParam(start),
            toAttendanceDate: _dateQueryParam(end),
            studentCodes: codes,
            signInAtFilter: signInAtFilter,
            signOutAtFilter: signOutAtFilter,
            page: 0,
            size: _feedPageSize,
          );
        }
      }
      final typeCodes = _activityTypeCodesForApiFilter();
      final approvalStatuses = _approvalStatusesForApiFilter();
      final activityPages = await Future.wait(
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
          return _feedScope.getRangeActivityFeed(
            classroomCode: cc,
            startDate: _dateQueryParam(start),
            endDate: _dateQueryParam(end),
            studentCode: sc,
            activityTypeCodes: typeCodes,
            approvalStatuses: approvalStatuses,
            guardianPersona: true,
            page: 0,
            size: _feedPageSize,
          );
        }),
      );
      final mergedActivityPage = mergeActivityFeedPages(activityPages);
      await _primeStaffDisplayNamesFromFeedRows(mergedActivityPage.content);
      await primeActivityFeedOptionLabelsFromRows(mergedActivityPage.content);
      final items = <ActivityItem>[
        if (attendancePage != null) ..._itemsFromAttendancePage(attendancePage),
        if (absentPage != null) ..._itemsFromAbsentRecordsPage(absentPage),
        ..._itemsFromActivityFeedPage(mergedActivityPage),
      ];
      final sortedItems = _sortItemsByLatestFirst(items);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        activities
          ..clear()
          ..addAll(
            _sortItemsByLatestFirst(
              groupMultiStudentFeedItems(
                sortedItems,
                attendanceRequireDateAndTimeMatch: true,
              ),
            ),
          );
        _feedError = null;
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !mergedActivityPage.last;
        _feedNextPage = _feedHasMore ? 1 : 0;
        _loadingMoreFeed = false;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadNextRangeFeedPage(),
      );
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = true;
    }
  }

  Future<void> _loadNextParentHomeRangeFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _isFeedRequestInFlight) return;

    final school = _schoolCode;
    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (school == null ||
        school.isEmpty ||
        start == null ||
        end == null ||
        _parentAllowedStudentCodes.isEmpty) {
      return;
    }
    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    final selectedEvent = _selectedAttendanceEventFilter();
    final pageIndex = _feedNextPage;

    _loadingMoreFeed = true;
    if (mounted) setState(() {});

    try {
      final signInAtFilter =
          (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
          ? 'NOT_NULL'
          : null;
      final signOutAtFilter =
          (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
          ? 'NOT_NULL'
          : null;
      StudentAttendanceDailyPage? attendancePage;
      StudentAttendanceAbsentFormPage? absentPage;
      if (_filterApprovalStatuses.isEmpty &&
          _shouldIncludeAttendanceEntries()) {
        if (_isMarkedAbsentEvent(selectedEvent)) {
          absentPage = await _feedScope.getStudentAbsentRecordsActivity(
            fromAbsenceDate: _dateQueryParam(start),
            toAbsenceDate: _dateQueryParam(end),
            studentCodes: _parentAllowedStudentCodes.toList(),
            page: pageIndex,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final startStr = _dateQueryParam(start);
          final endStr = _dateQueryParam(end);
          final dailyAbsent = await Future.wait([
            _feedScope.getStudentAttendanceDaily(
              attendanceDate: startStr,
              fromAttendanceDate: startStr,
              toAttendanceDate: endStr,
              studentCodes: _parentAllowedStudentCodes.toList(),
              signInAtFilter: null,
              signOutAtFilter: null,
              page: pageIndex,
              size: _feedPageSize,
            ),
            _feedScope.getStudentAbsentRecordsActivity(
              fromAbsenceDate: startStr,
              toAbsenceDate: endStr,
              studentCodes: _parentAllowedStudentCodes.toList(),
              page: pageIndex,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _feedScope.getStudentAttendanceDaily(
            attendanceDate: _dateQueryParam(start),
            fromAttendanceDate: _dateQueryParam(start),
            toAttendanceDate: _dateQueryParam(end),
            studentCodes: _parentAllowedStudentCodes.toList(),
            signInAtFilter: signInAtFilter,
            signOutAtFilter: signOutAtFilter,
            page: pageIndex,
            size: _feedPageSize,
          );
        }
      }
      final typeCodes = _activityTypeCodesForApiFilter();
      final approvalStatuses = _approvalStatusesForApiFilter();
      final activityPages = await Future.wait(
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
          return _feedScope.getRangeActivityFeed(
            classroomCode: cc,
            startDate: _dateQueryParam(start),
            endDate: _dateQueryParam(end),
            studentCode: sc,
            activityTypeCodes: typeCodes,
            approvalStatuses: approvalStatuses,
            guardianPersona: true,
            page: pageIndex,
            size: _feedPageSize,
          );
        }),
      );
      final mergedActivityPage = mergeActivityFeedPages(activityPages);
      await _primeStaffDisplayNamesFromFeedRows(mergedActivityPage.content);
      await primeActivityFeedOptionLabelsFromRows(mergedActivityPage.content);
      final items = <ActivityItem>[
        if (attendancePage != null) ..._itemsFromAttendancePage(attendancePage),
        if (absentPage != null) ..._itemsFromAbsentRecordsPage(absentPage),
        ..._itemsFromActivityFeedPage(mergedActivityPage),
      ];
      final sortedItems = _sortItemsByLatestFirst(items);

      if (!mounted) return;
      setState(() {
        activities.addAll(sortedItems);
        final grouped = _sortItemsByLatestFirst(
          groupMultiStudentFeedItems(
            activities,
            attendanceRequireDateAndTimeMatch: true,
          ),
        );
        activities
          ..clear()
          ..addAll(grouped);
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !mergedActivityPage.last;
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
          (_) => _maybeLoadNextRangeFeedPage(),
        );
      }
    }
  }

  void _updateAvailableStudents() {
    if (_selectedClassrooms.isNotEmpty) {
      final selectedClassroomNames = _selectedClassrooms;
      _availableStudents =
          selectedClassroomNames
              .expand((name) => classroomStudents[name] ?? const <String>[])
              .toSet()
              .toList()
            ..sort();
      // If current selected student is not in the new list, clear it
      if (_selectedStudent != null &&
          !_availableStudents.contains(_selectedStudent)) {
        _selectedStudent = null;
      }
      _selectedStudents = _selectedStudents
          .where((name) => _availableStudents.contains(name))
          .toList();
    } else {
      _availableStudents =
          classroomStudents.values
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
        _classroomOptions.add(cls);
        _classroomOptions.sort();
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
    if (school == null || school.isEmpty) {
      return;
    }

    final classroomName = _selectdClassroom;
    final classroomCode =
        (classroomName != null &&
            _classroomCodeByName.containsKey(classroomName))
        ? _classroomCodeByName[classroomName]!
        : '';

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
    await _loadRangeFeed(refresh: true);
  }

  Future<void> _loadAllStudentsForAllowedClassrooms({
    bool refresh = false,
  }) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty || _classroomOptions.isEmpty) return;

    final mergedByName = <String, String>{};
    final byClassroom = <String, List<String>>{};

    for (final classroomName in _classroomOptions) {
      final classroomCode = _classroomCodeByName[classroomName];
      if (classroomCode == null || classroomCode.trim().isEmpty) continue;
      try {
        final students = await _feedScope.getStudentClassroomList(
          schoolCode: school,
          classroomCode: classroomCode,
          status: const ['ACTIVE'],
          refresh: refresh,
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
      classroomStudents
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
    bool refresh = false,
  }) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty || selectedClassroomNames.isEmpty)
      return;

    final mergedByName = Map<String, String>.from(_studentCodeByName);
    final byClassroom = Map<String, List<String>>.from(classroomStudents);

    for (final classroomName in selectedClassroomNames) {
      final classroomCode = _classroomCodeByName[classroomName];
      if (classroomCode == null || classroomCode.trim().isEmpty) continue;
      try {
        final students = await _feedScope.getStudentClassroomList(
          schoolCode: school,
          classroomCode: classroomCode,
          status: const ['ACTIVE'],
          refresh: refresh,
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
      classroomStudents
        ..clear()
        ..addAll(byClassroom);
      _studentCodeByName
        ..clear()
        ..addAll(mergedByName);
      _updateAvailableStudents();
    });
  }

  /// Refreshes dropdown dependencies from the network without triggering feed.
  Future<void> _refreshApisAfterClearAll() async {
    await _loadTagFilterOptions(forceRefresh: true);
    if (isNotParent) {
      await _loadAllStudentsForAllowedClassrooms(refresh: true);
    }
  }

  void _resetDateRangeToCurrentMonth() {
    final today = SchoolZoneDateTime.schoolCalendarTodayOnly(_schoolIana);
    _selectedStartDate = DateTime(today.year, today.month, 1);
    _selectedEndDate = DateTime(today.year, today.month + 1, 0);
  }

  Future<void> _loadTagFilterOptions({bool forceRefresh = false}) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;
    try {
      final map = await _feedScope.loadTagNameCodeMap(
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

  String _dateQueryParam(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
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

  String? _activityTypeCodeForLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    for (final s in _classroomActivitySettings) {
      if (_filterLabelMatchesSetting(label, s.activityTypeName)) {
        return s.activityTypeCode;
      }
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

  List<String>? _activityTypeCodesForApiFilter() {
    // Attendance events are handled via attendance APIs.
    final event = _selectedAttendanceEventFilter();
    if (event != null) return null;
    final codes = <String>{};
    for (final label in _filterActivityTypes) {
      final code = _activityTypeCodeForLabel(label);
      if (code != null && code.trim().isNotEmpty) {
        codes.add(code.trim());
      }
    }
    return codes.isEmpty ? null : codes.toList();
  }

  int _appliedFilterBadgeCount() {
    final hasActivityTypeFilter = _filterActivityTypes.isNotEmpty;
    final hasTagFilter = _filterTags.isNotEmpty;
    final hasStatusFilter = _filterApprovalStatuses.isNotEmpty;
    return (hasActivityTypeFilter ? 1 : 0) +
        (hasTagFilter ? 1 : 0) +
        (hasStatusFilter ? 1 : 0);
  }

  List<ActivityItem> _itemsFromActivityFeedPage(ActivityFeedPage page) {
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
    final resolved = await _feedScope.resolveStaffDisplayNames(missingCodes);
    _staffDisplayNameByCode.addAll(resolved);
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

  Future<void> _rebuildStudentCodesForTagFilter() async {
    _studentCodesForTagFilter.clear();
    if (_filterTags.isEmpty || !mounted) return;
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;

    final tagNameToCodeLower = <String, String>{
      for (final e in _tagNameToCode.entries)
        e.key.trim().toLowerCase(): e.value,
    };
    final tagCodes = _filterTags
        .map((name) {
          final key = name.trim();
          if (key.isEmpty) return null;
          return (_tagNameToCode[key] ?? tagNameToCodeLower[key.toLowerCase()])
              ?.trim();
        })
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (tagCodes.isEmpty) return;

    try {
      final classroomCodes = _parentHome
          ? _parentStudentClassroomByCode.values
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList()
          : _selectedClassroomCodesForFeed();
      if (classroomCodes.isEmpty) return;

      for (final cc in classroomCodes) {
        if (cc.trim().isEmpty) continue;
        final students = await _feedScope.getStudentCodesForActivityTagFilter(
          schoolCode: school,
          classroomCode: cc,
          tagCodes: tagCodes,
        );
        if (!mounted) return;
        _studentCodesForTagFilter.addAll(students);
      }
    } catch (_) {
      if (mounted) _studentCodesForTagFilter.clear();
    }
  }

  Future<void> _bootstrapRangeFeed() async {
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

    _schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

    if ((_schoolCode ?? '').isEmpty) {
      if (!mounted) return;
      const msg = 'School is not selected.';
      setState(() {
        _feedError = msg;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      return;
    }

    if (_parentHome) {
      await _bootstrapParentHome();
      return;
    }

    await _loadStaffClassroomScope();

    final school = _schoolCode ?? '';
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
            .where(
              (e) =>
                  (e['name'] ?? '').isNotEmpty && (e['code'] ?? '').isNotEmpty,
            )
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
            ..addEntries(
              scoped
                  .map((c) => MapEntry(c['name'] ?? '', c['code'] ?? ''))
                  .where((e) => e.key.isNotEmpty && e.value.isNotEmpty),
            );
          _classroomNameByCode
            ..clear()
            ..addEntries(
              scoped
                  .map((c) => MapEntry(c['code'] ?? '', c['name'] ?? ''))
                  .where((e) => e.key.isNotEmpty && e.value.isNotEmpty),
            );

          final names =
              scoped
                  .map((c) => (c['name'] ?? '').trim())
                  .where((n) => n.isNotEmpty)
                  .toList()
                ..sort();
          if (mounted) {
            setState(() {
              _classroomOptions
                ..clear()
                ..addAll(names);
              if (_classroomOptions.isNotEmpty &&
                  (_selectdClassroom == null ||
                      !_classroomOptions.contains(_selectdClassroom))) {
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
            });
            hydratedClassroomsFromCache = _classroomOptions.isNotEmpty;
          }
        }
      }
    } catch (_) {}

    // For unrestricted personas (admin), continue to API refresh so stale
    // staff-scoped cache cannot lock the dropdown.
    if (hydratedClassroomsFromCache &&
        mounted &&
        _allowedClassroomCodes.isNotEmpty) {
      await _loadRangeFeed(refresh: false);
      unawaited(_loadTagFilterOptions(forceRefresh: false).catchError((_) {}));
      return;
    }

    try {
      final classrooms = await _feedScope.getActiveClassrooms(
        schoolCode: school,
        onlyTypeClassroom: true,
      );

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
        if (!mounted) return;
        setState(() {
          _classroomCodeByName.clear();
          _classroomNameByCode.clear();
          _classroomOptions.clear();
          _selectdClassroom = null;
          _feedError = 'No classrooms found. Pull to refresh.';
        });
        return;
      }
      _classroomCodeByName
        ..clear()
        ..addEntries(scoped.map((c) => MapEntry(c.name, c.code)));
      _classroomNameByCode
        ..clear()
        ..addEntries(scoped.map((c) => MapEntry(c.code, c.name)));
      _classroomOptions
        ..clear()
        ..addAll(scoped.map((c) => c.name));

      if (_forceAllClassroomsOnLoad) {
        _selectedClassrooms = List.from(_classroomOptions);
        _selectdClassroom = null;
      } else if (_classroomOptions.isNotEmpty &&
          (_selectdClassroom == null ||
              !_classroomOptions.contains(_selectdClassroom))) {
        final primaryCode = (_primaryClassroomCode ?? '').trim();
        final primaryName = primaryCode.isNotEmpty
            ? _classroomNameByCode[primaryCode]
            : null;
        // If the primary classroom is Office (filtered out of the selectable
        // list) or otherwise unavailable, fall back to the top sorted classroom.
        _selectdClassroom =
            (primaryName != null && _classroomOptions.contains(primaryName))
            ? primaryName
            : _classroomOptions.first;
      }

      // Keep multi-select UI in sync with default classroom.
      if (!_forceAllClassroomsOnLoad &&
          _selectdClassroom != null &&
          _selectdClassroom!.trim().isNotEmpty) {
        _selectedClassrooms = <String>[_selectdClassroom!];
      }
      _forceAllClassroomsOnLoad = false;
      await _cacheManager.saveCache(classroomCacheKey, {
        // Persist full school classrooms; apply staff scope only at runtime.
        'classrooms': classrooms
            .map((c) => {'name': c.name, 'code': c.code})
            .toList(),
      });

      await _loadRangeFeed();
      unawaited(_loadTagFilterOptions().catchError((_) {}));
    } catch (e) {
      if (!mounted) return;
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
        final profile = await _feedScope.getOwnStaffProfileForClassroomScope(
          staffCode: staffCode,
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
            activities.clear();
          });
        }
        return;
      }

      final page = await _feedScope.getStudentPage(
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
        if (selectedClassroom != null && selectedClassroom.trim().isNotEmpty) {
          _parentAllowedStudentCodes
            ..clear()
            ..add(globalSelectedCode);
          _parentStudentClassroomByCode.clear();
          _parentStudentClassroomByCode[globalSelectedCode] = selectedClassroom
              .trim();
          _lastGlobalSelectedStudentCode = globalSelectedCode;
        } else {
          // Keep the full guardian student->classroom map when the globally
          // selected child has no classroom mapping yet. Otherwise range-feed
          // API calls are skipped due to missing classroomCode.
          CoreUtils.logApiError(
            'Parent selected child has no classroom mapping; using all mapped guardian students for custom feed.',
          );
        }
      }

      if (_parentAllowedStudentCodes.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'No linked children with a classroom.';
            _loadingParentContext = false;
            activities.clear();
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _loadingParentContext = false;
        });
      }
      await _loadRangeFeed(refresh: true);
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

  Future<void> _loadRangeFeed({bool refresh = false}) async {
    if (_parentHome) {
      return _loadParentHomeRangeFeed(refresh: refresh);
    }

    final classroomCodes = _selectedClassroomCodesForFeed();
    final classroomCode = classroomCodes.isNotEmpty
        ? classroomCodes.first
        : null;
    final classroomName =
        _selectdClassroom ??
        (classroomCode == null ? null : _classroomNameByCode[classroomCode]);
    final classroomNameKey = classroomName ?? (classroomCode ?? '');
    if (classroomCode == null || classroomCode.trim().isEmpty) {
      if (mounted) {
        setState(() {
          activities.clear();
          _feedError = null;
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }

    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (start == null || end == null) return;
    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;
    var studentCodes = _selectedStudentCodesForAttendanceFilter();
    if ((studentCodes == null || studentCodes.isEmpty) &&
        _selectedStudents.isNotEmpty &&
        isNotParent) {
      await _loadAllStudentsForAllowedClassrooms();
      if (!mounted) return;
      studentCodes = _selectedStudentCodesForAttendanceFilter();
    }
    final selectedEvent = _selectedAttendanceEventFilter();
    final requestKey = [
      classroomCode,
      _dateQueryParam(start),
      _dateQueryParam(end),
      (studentCodes ?? const <String>[]).join(','),
      selectedEvent ?? '',
      _filterActivityTypes.join(','),
      _filterTags.join(','),
      _filterApprovalStatuses.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      if (_isFeedRequestInFlight) return;
      if (!_lastFeedCompletedWithError) {
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          AppTime.nowUtc().difference(completedAt) <
              const Duration(seconds: 3)) {
        return;
      }
    }

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    try {
      final signInAtFilter =
          (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
          ? 'NOT_NULL'
          : null;
      final signOutAtFilter =
          (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
          ? 'NOT_NULL'
          : null;
      final selectedStudentCode =
          (studentCodes != null && studentCodes.isNotEmpty)
          ? studentCodes.first
          : null;
      final typeCodes = _activityTypeCodesForApiFilter();
      final approvalStatuses = _approvalStatusesForApiFilter();

      final includeAttendance =
          _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();
      final activityFeedPage = await _feedScope.getRangeActivityFeed(
        classroomCode: classroomCode,
        startDate: _dateQueryParam(start),
        endDate: _dateQueryParam(end),
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
          absentPage = await _feedScope.getStudentAbsentRecordsActivity(
            fromAbsenceDate: _dateQueryParam(start),
            toAbsenceDate: _dateQueryParam(end),
            classroomCodes: classroomCodes,
            studentCodes: studentCodes,
            page: 0,
            size: _feedPageSize,
          );
        } else if (selectedEvent == null) {
          final startStr = _dateQueryParam(start);
          final endStr = _dateQueryParam(end);
          final dailyAbsent = await Future.wait([
            _feedScope.getStudentAttendanceDaily(
              attendanceDate: startStr,
              fromAttendanceDate: startStr,
              toAttendanceDate: endStr,
              classroomCodes: classroomCodes,
              studentCodes: studentCodes,
              signInAtFilter: null,
              signOutAtFilter: null,
              page: 0,
              size: _feedPageSize,
            ),
            _feedScope.getStudentAbsentRecordsActivity(
              fromAbsenceDate: startStr,
              toAbsenceDate: endStr,
              classroomCodes: classroomCodes,
              studentCodes: studentCodes,
              page: 0,
              size: _feedPageSize,
            ),
          ]);
          attendancePage = dailyAbsent[0] as StudentAttendanceDailyPage;
          absentPage = dailyAbsent[1] as StudentAttendanceAbsentFormPage;
        } else {
          attendancePage = await _feedScope.getStudentAttendanceDaily(
            attendanceDate: _dateQueryParam(start),
            fromAttendanceDate: _dateQueryParam(start),
            toAttendanceDate: _dateQueryParam(end),
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
        if (attendancePage != null) ..._itemsFromAttendancePage(attendancePage),
        if (absentPage != null) ..._itemsFromAbsentRecordsPage(absentPage),
        ..._itemsFromActivityFeedPage(activityFeedPage),
      ];
      final sortedItems = _sortItemsByLatestFirst(items);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        activities
          ..clear()
          ..addAll(sortedItems);
        _feedError = null;
        _feedHasMore =
            (attendancePage?.hasMore ?? false) ||
            (absentPage?.hasMore ?? false) ||
            !activityFeedPage.last;
        _feedNextPage = _feedHasMore ? 1 : 0;
        _loadingMoreFeed = false;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadNextRangeFeedPage(),
      );

      try {
        final school = _schoolCode;
        final shouldReloadClassroomDependencies =
            refresh ||
            _lastResolvedClassroomCode != classroomCode ||
            !classroomStudents.containsKey(classroomName);

        if (shouldReloadClassroomDependencies) {
          if (school != null && school.isNotEmpty) {
            final studentsCacheKey = CacheManager.buildCacheKey(
              feature: 'activity',
              resource: 'students',
              identifier: '$school|$classroomCode',
            );
            if (!refresh) {
              try {
                final cachedStudents = await _cacheManager.loadCache(
                  studentsCacheKey,
                );
                if (cachedStudents != null &&
                    cachedStudents['students'] is List) {
                  final cachedList = (cachedStudents['students'] as List)
                      .whereType<Map>()
                      .map(
                        (e) => <String, String>{
                          'name': (e['name'] ?? '').toString(),
                          'code': (e['code'] ?? '').toString(),
                        },
                      )
                      .where(
                        (e) =>
                            (e['name'] ?? '').isNotEmpty &&
                            (e['code'] ?? '').isNotEmpty,
                      )
                      .toList();
                  if (cachedList.isNotEmpty) {
                    if (mounted) {
                      setState(() {
                        _studentCodeByName
                          ..clear()
                          ..addEntries(
                            cachedList.map(
                              (s) => MapEntry(s['name'] ?? '', s['code'] ?? ''),
                            ),
                          );
                        classroomStudents[classroomNameKey] = cachedList
                            .map((s) => s['name'] ?? '')
                            .toList();
                        _updateAvailableStudents();
                      });
                    }
                  }
                }
              } catch (_) {}
            }

            final students = await _feedScope.getStudentClassroomList(
              schoolCode: school,
              classroomCode: classroomCode,
              status: const ['ACTIVE'],
              refresh: refresh,
            );
            if (mounted) {
              setState(() {
                _studentCodeByName
                  ..clear()
                  ..addEntries(
                    students.map((s) => MapEntry(s.fullName, s.studentCode)),
                  );
                classroomStudents[classroomNameKey] = students
                    .map((s) => s.fullName)
                    .toList();
                _updateAvailableStudents();
              });
            }
            await _cacheManager.saveCache(studentsCacheKey, {
              'students': students
                  .map((s) => {'name': s.fullName, 'code': s.studentCode})
                  .toList(),
            });
          }

          try {
            if ((refresh || _classroomActivitySettings.isEmpty) &&
                school != null &&
                school.isNotEmpty) {
              _classroomActivitySettings = await _feedScope
                  .loadActivityTypeSettingsForFilters(
                    schoolCode: school,
                    forceRefresh: refresh,
                  );
            }
          } catch (_) {
            // Keep existing in-memory settings on fetch failure.
          }
          _lastResolvedClassroomCode = classroomCode;
          if (mounted) setState(() {});
        }
      } catch (_) {
        // Students/settings are non-blocking after the feed is shown.
      }
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = AppTime.nowUtc();
      _lastFeedCompletedWithError = true;
    }
  }

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

    // Force refresh of tag map + feed. Also bust staff dropdown cache.
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
      // Parent bootstrap already calls _loadRangeFeed(refresh: true).
      await _loadTagFilterOptions(forceRefresh: true);
      return;
    } else {
      // Force classroom metadata refresh for staff/admin personas too.
      final school = (_schoolCode ?? '').trim();
      if (school.isNotEmpty) {
        final classroomCacheKey = CacheManager.buildCacheKey(
          feature: 'activity',
          resource: 'classrooms',
          identifier: school,
        );
        await _cacheManager.invalidateCache(classroomCacheKey);
      }
      await _bootstrapRangeFeed();
    }
    await _loadTagFilterOptions(forceRefresh: true);
    await _loadRangeFeed(refresh: true);
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

  void _syncWithGlobalChildSelection() {
    if (!_parentHome) return;
    final globalSelectedCode =
        (context.read<ParentChildCubit>().selectedChild?.code ?? '').trim();
    if (globalSelectedCode.isEmpty) return;
    if (_lastGlobalSelectedStudentCode == globalSelectedCode) return;

    _lastGlobalSelectedStudentCode = globalSelectedCode;

    // If we don't yet have classroom mapping for this child, bootstrap first.
    if (_parentStudentClassroomByCode[globalSelectedCode] == null) {
      _bootstrapParentHome();
      return;
    }

    _parentAllowedStudentCodes
      ..clear()
      ..add(globalSelectedCode);

    _loadRangeFeed(refresh: true);
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
          return const SizedBox.shrink();
        } else {
          return CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  // filter card
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
                                  selectedStartDate: _selectedStartDate,
                                  selectedEndDate: _selectedEndDate,
                                  // onDateRangeSelected: (date) {
                                  //   List<String>? dates = date?.split('-\n');
                                  //   setState(() {
                                  //     _selectedStartDate = dates?[0].trim() as DateTime?;
                                  //     _selectedEndDate = dates?[1].trim() as DateTime;
                                  //
                                  //   });
                                  // },
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomClearAllChip(
                                onTap: () async {
                                  setState(() {
                                    _resetDateRangeToCurrentMonth();
                                    _selectdClassroom = null;
                                    _selectedClassrooms = <String>[];
                                    _selectedStudent = null;
                                    _selectedStudents = [];
                                    _filterActivityTypes.clear();
                                    _filterTags.clear();
                                    _filterApprovalStatuses.clear();
                                  });
                                  await _refreshApisAfterClearAll();
                                  await _loadRangeFeed(refresh: true);
                                },
                                label: 'Clear All',
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
                                            _resetDateRangeToCurrentMonth();
                                            _selectdClassroom = null;
                                            _selectedClassrooms = <String>[];
                                            _selectedStudent = null;
                                            _selectedStudents = [];
                                            _filterActivityTypes.clear();
                                            _filterTags.clear();
                                            _filterApprovalStatuses.clear();
                                            _updateAvailableStudents();
                                          });
                                          await _refreshApisAfterClearAll();
                                          await _loadRangeFeed(refresh: true);
                                          return;
                                        }

                                        setState(() {
                                          _selectedClassrooms = values;
                                          _selectdClassroom = values.first;
                                          _updateAvailableStudents();
                                        });
                                        if (isNotParent) {
                                          await _loadStudentsForSelectedClassrooms(
                                            values,
                                          );
                                        }
                                        await _loadRangeFeed(refresh: true);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    // child: _buildCustomDropdown(
                                    //   'Select Student',
                                    //   _allStudents,
                                    //   _selectedStudent,
                                    //       (v) => setState(() {
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
                                        _loadRangeFeed(refresh: true);
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
                                                    color: const Color.fromRGBO(
                                                      179,
                                                      38,
                                                      30,
                                                      1,
                                                    ),
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
                                      selectedStartDate: _selectedStartDate,
                                      selectedEndDate: _selectedEndDate,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CustomClearAllChip(
                                    onTap: () async {
                                      setState(() {
                                        _resetDateRangeToCurrentMonth();
                                        _selectdClassroom = null;
                                        _selectedClassrooms = <String>[];
                                        _selectedStudent = null;
                                        _selectedStudents = [];
                                        _filterActivityTypes.clear();
                                        _filterTags.clear();
                                        _filterApprovalStatuses.clear();
                                      });
                                      await _refreshApisAfterClearAll();
                                      await _loadRangeFeed(refresh: true);
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
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_loadingParentContext && _displayActivities.isEmpty)
                  Expanded(
                    child: _portraitOverscrollFeedWrapper(
                      child: Padding(
                        padding: ResponsiveSizing.contentPadding(context),
                        child: Container(
                          width: double.infinity,
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
                if (!_loadingParentContext && _displayActivities.isEmpty)
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
                            child: Text(
                              _feedError ?? 'No Activities found',
                              style: AppTextStyles.emptyState.copyWith(
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

                if (_displayActivities.isNotEmpty)
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
                                  _displayActivities.length +
                                  (_loadingMoreFeed ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _displayActivities.length) {
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
                                final activity = _displayActivities[index];
                                final students = activity.studentList;
                                final Color activityColor =
                                    AppColors.colorPalette[index %
                                        AppColors.colorPalette.length];

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: activityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 2,
                                              color: activityColor,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 100,
                                          height: 4,
                                          color: activityColor,
                                        ),
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: activityColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          height: 20,
                                          child: Text(
                                            activity.time,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.primaryColor,
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
                                          color: activityColor,
                                        ),

                                        const SizedBox(width: 16),

                                        // Activity Card
                                        Expanded(
                                          child: InkWell(
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
                                                  await _loadRangeFeed(
                                                    refresh: true,
                                                  );
                                                }
                                              }
                                            },
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 15),
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        minHeight: 180,
                                                      ),
                                                  margin: const EdgeInsets.only(
                                                    bottom: 10,
                                                  ),
                                                  padding: const EdgeInsets.all(
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
                                                              //             color: activityColor
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
                                                                        if (iconPath
                                                                            .toLowerCase()
                                                                            .endsWith(
                                                                              '.svg',
                                                                            )) {
                                                                          return SvgPicture.asset(
                                                                            iconPath,
                                                                            fit:
                                                                                BoxFit.contain,
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
                                                                  child: Wrap(
                                                                    spacing: 8,
                                                                    runSpacing:
                                                                        6,
                                                                    crossAxisAlignment:
                                                                        WrapCrossAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              12,
                                                                          vertical:
                                                                              6,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color: activityColor.withValues(
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
                                                                          style: AppTextStyles.bodySmall.copyWith(
                                                                            color:
                                                                                AppColors.primaryColor,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (activityApprovalStatusBadgeLabel(
                                                                            activity.approvalStatus,
                                                                          ) !=
                                                                          null)
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                10,
                                                                            vertical:
                                                                                6,
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
                                                                            style: AppTextStyles.caption.copyWith(
                                                                              color: AppColors.primaryColor,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
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
                                                                            Icons.visibility_outlined,
                                                                            color:
                                                                                AppColors.themeColor,
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
                                                                              await _loadRangeFeed(
                                                                                refresh: true,
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
                                                                              Icons.edit,
                                                                              color: AppColors.themeColor,
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
                                                                                await _loadRangeFeed(
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
                                                                            title:
                                                                                'Reject',
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
                                                                              Icons.delete,
                                                                              color: AppColors.themeColor,
                                                                            ),
                                                                          ),
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
                                                            Text(
                                                              'Created By - ${activity.createdBy}',

                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontSize: 12,
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
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: ResponsiveSizing.contentPadding(context),
  //         // filter card
  //         child: Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: AppColors.cardBorderColor),
  //             borderRadius: BorderRadius.circular(12),
  //             color: AppColors.cardColor,
  //           ),
  //           child: widget.fromStudentProfile
  //               ? Column(
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: [
  //                     SizedBox(
  //                       height: 40,
  //                       child: AbsorbPointer(
  //                         child: _buildCustomDropdown(
  //                           'Select Student',
  //                           [?widget.studentName],
  //                           widget.studentName,
  //                           (v) => setState(() {
  //                             _selectedStudent = v;
  //                           }),
  //                           height: 40,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 8),
  //                     SizedBox(
  //                       height: 40,
  //                       child: _datePickerFilter(
  //                         selectedStartDate: _selectedStartDate,
  //                         selectedEndDate: _selectedEndDate,
  //                         // onDateRangeSelected: (date) {
  //                         //   List<String>? dates = date?.split('-\n');
  //                         //   setState(() {
  //                         //     _selectedStartDate = dates?[0].trim() as DateTime?;
  //                         //     _selectedEndDate = dates?[1].trim() as DateTime;
  //                         //
  //                         //   });
  //                         // },
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               : isNotParent
  //               ? Column(
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: _buildCustomDropdown(
  //                             'Select Classroom',
  //                             _classroomOptions,
  //                             _selectdClassroom,
  //                             (v) => setState(() {
  //                               _selectdClassroom = v;
  //                               _updateAvailableStudents();
  //                             }),
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           // child: _buildCustomDropdown(
  //                           //   'Select Student',
  //                           //   _allStudents,
  //                           //   _selectedStudent,
  //                           //       (v) => setState(() {
  //                           //     _selectedStudent = v;
  //                           //   }),
  //                           // ),
  //                           child: _buildCustomDropdown(
  //                             _selectdClassroom == null
  //                                 ? 'Select Classroom First'
  //                                 : 'Select Student',
  //                             _availableStudents,
  //                             _selectedStudent,
  //                             (value) {
  //                               if (_selectdClassroom != null) {
  //                                 setState(() {
  //                                   _selectedStudent = value;
  //                                 });
  //                               }
  //                             },
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Material(
  //                           color: Colors.transparent,
  //                           child: InkWell(
  //                             borderRadius: BorderRadius.circular(100),
  //                             onTap: () async {
  //                               final result = await Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (_) => FilterScreen(
  //                                     sections: [
  //                                       FilerSection(
  //                                         label: 'Tags',
  //                                         hintText: 'Select tags',
  //                                         items: [
  //                                           '5 Days',
  //                                           'Full Day',
  //                                           'Photo Permission',
  //                                           'Vegetarian',
  //                                           'First Aid',
  //                                           'Allergy',
  //                                           'Pickup Authorized',
  //                                           'Medication',
  //                                           'Half Day',
  //                                           'Boy',
  //                                           'Girl',
  //                                         ],
  //                                         initialSelected: _filterTags,
  //                                         isMultiSelectDropDown: false,
  //                                       ),
  //                                       FilerSection(
  //                                         label: 'Activity Type',
  //                                         hintText: 'Select Activity',
  //                                         items: [
  //                                           'Nap Start',
  //                                           'Nap End',
  //                                           'Bathroom',
  //                                           'Bottle',
  //                                           'Meal',
  //                                           'Incident',
  //                                           'Photo',
  //                                           'Outdoor',
  //                                           'Medication',
  //                                           'Notes',
  //                                           'Learning',
  //                                           'Sign-in',
  //                                           'Sign-out',
  //                                           'Absent',
  //                                         ],
  //                                         initialSelected: _filterActivityTypes,
  //                                         isMultiSelectDropDown: false,
  //                                       ),
  //                                     ],
  //                                     onApply: (filters) {
  //                                       setState(() {
  //                                         _filterTags = filters['Tags']!;
  //                                         _filterActivityTypes =
  //                                             filters['Activity Type']!;
  //                                       });
  //                                     },
  //                                   ),
  //                                 ),
  //                               );
  //                               if (!mounted) return;
  //                               if (result is Map) {
  //                                 // TODO: apply filters to list
  //                                 setState(() {});
  //                               }
  //                             },
  //                             child: Padding(
  //                               padding: const EdgeInsets.all(8),
  //                               child: SvgPicture.asset(
  //                                 MediaRes.filterIcon,
  //                                 height: 20,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 16),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Expanded(
  //                           child: _datePickerFilter(
  //                             selectedStartDate: _selectedStartDate,
  //                             selectedEndDate: _selectedEndDate,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         CustomClearAllChip(
  //                           onTap: () {
  //                             setState(() {
  //                               _selectdClassroom = _classroomOptions[0];
  //                               _selectedStudent = null;
  //                               _filterActivityTypes.clear();
  //                               _filterTags.clear();
  //                             });
  //                           },
  //                           label: 'Clear All',
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 )
  //               : Row(
  //                   children: [
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 40,
  //                         child: _datePickerFilter(
  //                           selectedStartDate: _selectedStartDate,
  //                           selectedEndDate: _selectedEndDate,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 40,
  //                         child: _buildCustomDropdown(
  //                           'Activity Type',
  //                           activityType,
  //                           _selectedActivityType,
  //                           (v) => setState(() {
  //                             _selectedActivityType = v;
  //                           }),
  //                           height: 40,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //         ),
  //       ),
  //
  //       const SizedBox(height: 12),
  //
  //       if (activities.length == 0)
  //         Expanded(
  //           child: Padding(
  //             padding: ResponsiveSizing.contentPadding(context),
  //             child: Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 border: Border.all(color: AppColors.cardBorderColor),
  //                 borderRadius: BorderRadius.circular(12),
  //                 color: AppColors.cardColor,
  //               ),
  //               child: Center(
  //                 child: Text(
  //                   'No Activities found',
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                     fontFamily: 'Manrope',
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //
  //       if (activities.length != 0)
  //         Expanded(
  //           child: Padding(
  //             padding: ResponsiveSizing.contentPadding(context),
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 10),
  //                 Expanded(
  //                   child: ListView.builder(
  //                     padding: const EdgeInsets.only(right: 16),
  //                     itemCount: activities.length,
  //                     itemBuilder: (context, index) {
  //                       final activity = activities[index];
  //                       final students = activity.studentList;
  //                       final Color activityColor = _colorPalette[index % _colorPalette.length];
  //
  //                       return Column(
  //                         children: [
  //                           Row(
  //                             children: [
  //                               Column(
  //                                 children: [
  //                                   Container(
  //                                     width: 18,
  //                                     height: 18,
  //                                     decoration: BoxDecoration(
  //                                       color: activityColor,
  //                                       shape: BoxShape.circle,
  //                                     ),
  //                                   ),
  //                                   Container(
  //                                     width: 4,
  //                                     height: 2,
  //                                     color: activityColor,
  //                                   ),
  //                                 ],
  //                               ),
  //                               Container(
  //                                 width: 100,
  //                                 height: 4,
  //                                 color: activityColor,
  //                               ),
  //                               Container(
  //                                 width: 18,
  //                                 height: 18,
  //                                 decoration: BoxDecoration(
  //                                   color: activityColor,
  //                                   shape: BoxShape.circle,
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 20),
  //                               SizedBox(
  //                                 height: 20,
  //                                 child: Text(
  //                                   activity.time,
  //                                   style: TextStyle(
  //                                     fontSize: 14,
  //                                     color: AppColors.primaryColor,
  //                                     fontWeight: FontWeight.w500,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                           Row(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               const SizedBox(width: 7),
  //                               Container(
  //                                 width: 4,
  //                                 height: 220,
  //                                 color: activityColor,
  //                               ),
  //
  //                               const SizedBox(width: 16),
  //
  //                               // Activity Card
  //                               Expanded(
  //                                 child: Column(
  //                                   children: [
  //                                     const SizedBox(height: 15),
  //                                     Container(
  //                                       height: 180,
  //                                       margin: const EdgeInsets.only(
  //                                         bottom: 24,
  //                                       ),
  //                                       padding: const EdgeInsets.all(12),
  //                                       decoration: BoxDecoration(
  //                                         color: activityColor.withValues(alpha:
  //                                           0.15,
  //                                         ),
  //                                         borderRadius: BorderRadius.circular(
  //                                           16,
  //                                         ),
  //                                         border: Border.all(
  //                                           color: activityColor.withValues(alpha:
  //                                             0.4,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       child: Row(
  //                                         // crossAxisAlignment:
  //                                         //     CrossAxisAlignment.center,
  //                                         children: [
  //                                           ClipRRect(
  //                                             borderRadius:
  //                                                 BorderRadius.circular(12),
  //                                             child: SizedBox(
  //                                               width: 140,
  //                                               height: 120,
  //                                               child:
  //                                               activity.photoUrl != null || activity.videoUrl != null
  //                                                   ? ActivityMediaPreview(activity: activity, activityColor: activityColor,)
  //                                                   // ? Image.network(
  //                                                   //     activity.photoUrl!,
  //                                                   //     fit: BoxFit.cover,
  //                                                   //     loadingBuilder:
  //                                                   //         (
  //                                                   //           context,
  //                                                   //           child,
  //                                                   //           loadingProgress,
  //                                                   //         ) {
  //                                                   //           if (loadingProgress ==
  //                                                   //               null)
  //                                                   //             return child;
  //                                                   //           return Container(
  //                                                   //             color: Colors
  //                                                   //                 .transparent,
  //                                                   //             child: const Center(
  //                                                   //               child: CircularProgressIndicator(
  //                                                   //                 strokeWidth:
  //                                                   //                     2,
  //                                                   //               ),
  //                                                   //             ),
  //                                                   //           );
  //                                                   //         },
  //                                                   //     errorBuilder:
  //                                                   //         (
  //                                                   //           context,
  //                                                   //           error,
  //                                                   //           stackTrace,
  //                                                   //         ) {
  //                                                   //           return Container(
  //                                                   //             width: 122,
  //                                                   //             height: 76,
  //                                                   //             color: activityColor
  //                                                   //                 .withValues(alpha:
  //                                                   //                   0.25,
  //                                                   //                 ),
  //                                                   //             child: Center(
  //                                                   //               child: Image.asset(
  //                                                   //                 activityIcons[activity
  //                                                   //                     .name],
  //                                                   //                 //'assets/icons/activity-nap-icon.png',
  //                                                   //                 fit: BoxFit
  //                                                   //                     .fill,
  //                                                   //               ),
  //                                                   //             ),
  //                                                   //           );
  //                                                   //         },
  //                                                   //   )
  //                                                   : Container(
  //                                                       width: 122,
  //                                                       height: 76,
  //                                                       color: Colors.white,
  //                                                       // color: activityColor
  //                                                       //     .withValues(alpha:0.25),
  //                                                       child: Center(
  //                                                         child: Image.asset(
  //                                                           activityIcons[activity
  //                                                               .name],
  //                                                           //'assets/icons/activity-nap-icon.png',
  //                                                           fit: BoxFit.fill,
  //                                                         ),
  //                                                       ),
  //                                                     ),
  //                                             ),
  //                                           ),
  //                                           const SizedBox(width: 12),
  //                                           Expanded(
  //                                             child: Column(
  //                                               crossAxisAlignment:
  //                                                   CrossAxisAlignment.start,
  //                                               mainAxisAlignment:
  //                                                   MainAxisAlignment
  //                                                       .spaceEvenly,
  //                                               children: [
  //                                                 Row(
  //                                                   mainAxisAlignment:
  //                                                       MainAxisAlignment
  //                                                           .spaceBetween,
  //                                                   children: [
  //                                                     Container(
  //                                                       padding:
  //                                                           const EdgeInsets.symmetric(
  //                                                             horizontal: 12,
  //                                                             vertical: 6,
  //                                                           ),
  //                                                       decoration: BoxDecoration(
  //                                                         color: activityColor,
  //                                                         borderRadius:
  //                                                             BorderRadius.circular(
  //                                                               20,
  //                                                             ),
  //                                                       ),
  //                                                       child: Text(
  //                                                         activity.name,
  //                                                         style:
  //                                                             const TextStyle(
  //                                                               color: Colors
  //                                                                   .white,
  //                                                               fontSize: 11,
  //                                                               fontWeight:
  //                                                                   FontWeight
  //                                                                       .bold,
  //                                                             ),
  //                                                       ),
  //                                                     ),
  //                                                     PopupMenuButton<String>(
  //                                                       icon: const Icon(
  //                                                         Icons.more_horiz,
  //                                                         size: 20,
  //                                                       ),
  //                                                       onSelected: null,
  //                                                       itemBuilder: (context) => [
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'view',
  //                                                           child: PopupItem(
  //                                                             title: 'View',
  //                                                             icon: Icon(
  //                                                               Icons
  //                                                                   .visibility_outlined,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                           onTap: () {
  //                                                             final destinationBuilder =
  //                                                                 activityRoutes[activity
  //                                                                     .name];
  //                                                             if (destinationBuilder !=
  //                                                                 null) {
  //                                                               final nextScreen =
  //                                                                   destinationBuilder(
  //                                                                     activity,
  //                                                                   );
  //                                                               Navigator.of(
  //                                                                 context,
  //                                                               ).push(
  //                                                                 MaterialPageRoute(
  //                                                                   builder: (_) =>
  //                                                                       nextScreen,
  //                                                                 ),
  //                                                               );
  //                                                             }
  //                                                           },
  //                                                         ),
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'edit',
  //                                                           child: PopupItem(
  //                                                             title: 'Edit',
  //                                                             icon: Icon(
  //                                                               Icons.edit,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'delete',
  //                                                           child: PopupItem(
  //                                                             title: 'Delete',
  //                                                             icon: Icon(
  //                                                               Icons.delete,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                       ],
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //
  //                                                 SizedBox(
  //                                                   height: 32,
  //                                                   child: Stack(
  //                                                     children: [
  //                                                       for (
  //                                                         int i = 0;
  //                                                         i < students.length &&
  //                                                             i < 4;
  //                                                         i++
  //                                                       )
  //                                                         Positioned(
  //                                                           left: i * 20,
  //                                                           child:
  //                                                               DocumentImageWidget(
  //                                                                 fileUuid: '',
  //                                                                 name:
  //                                                                     students[i],
  //                                                                 size: 28,
  //                                                                 fontSize: 10,
  //                                                               ),
  //                                                         ),
  //
  //                                                       // Extra count tooltip
  //                                                       if (students.length > 4)
  //                                                         Positioned(
  //                                                           left:
  //                                                               4 *
  //                                                               20, // after 4 avatars
  //                                                           child: Tooltip(
  //                                                             message: students
  //                                                                 .skip(4)
  //                                                                 .join(', '),
  //                                                             child: DocumentImageWidget(
  //                                                               fileUuid: '',
  //                                                               name:
  //                                                                   '+${students.length - 4}',
  //                                                               size: 28,
  //                                                               fontSize: 10,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                     ],
  //                                                   ),
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //
  //                                                 Text(
  //                                                   activity.description!,
  //
  //                                                   style: TextStyle(
  //                                                     color: AppColors
  //                                                         .primaryColor,
  //                                                     fontSize: 14,
  //                                                     fontWeight:
  //                                                         FontWeight.w600,
  //                                                   ),
  //                                                   maxLines: 1,
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //                                                 Text(
  //                                                   'Created By - ${activity.createdBy}',
  //
  //                                                   style: TextStyle(
  //                                                     color: AppColors
  //                                                         .primaryColor,
  //                                                     fontSize: 12,
  //                                                     fontWeight:
  //                                                         FontWeight.w500,
  //                                                   ),
  //                                                   maxLines: 1,
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _datePickerFilter({
    required DateTime? selectedStartDate,
    required DateTime? selectedEndDate,
    //required Function(String?) onDateRangeSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => CalendarDialog(
            isRangePicker: true,
            isTimePicker: false,
            initialDate: selectedStartDate,
            initialEndDate: selectedEndDate,
            whiteBgColor: true,
          ),
        );

        if (result != null) {
          setState(() {
            _selectedStartDate = result['startDate'] as DateTime?;
            if (result['endDate'] != null)
              _selectedEndDate = result['endDate'] as DateTime?;
          });
          _loadRangeFeed(refresh: true);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
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
                  selectedStartDate != null
                      ? '${DateFormat('MMM dd, yyyy').format(selectedStartDate)} - ${DateFormat('MMM dd, yyyy').format(selectedEndDate ?? selectedStartDate)}'
                      : 'Select Date',
                  style: AppTextStyles.body.copyWith(
                    color: selectedStartDate == null
                        ? Colors.grey[600]
                        : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Flexible(
              //   child: Text(
              //     selectedEndDate != null
              //         ? DateFormat('MMM dd, yyyy').format(selectedEndDate)
              //         : 'Select Date',
              //     style: TextStyle(
              //       color: selectedEndDate == null
              //           ? AppColors.primaryColor.withValues(alpha:0.6)
              //           : AppColors.primaryColor,
              //       fontSize: 14,
              //       fontWeight: FontWeight.w500,
              //     ),
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
              // const SizedBox(width: 4),
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
      items: items,
      height: height ?? 40,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      selectedTextStyle: AppTextStyles.body.copyWith(
        color: selectedItem != null && selectedItem.trim().isNotEmpty
            ? Colors.black87
            : Colors.grey[600],
      ),
      popupItemTextStyle: AppTextStyles.body.copyWith(color: Colors.black87),
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

// PopupItem is defined in activity_daily_tab.dart (imported above) — both
// screens shared a byte-identical copy of this widget; this file now reuses
// that one instead of maintaining its own.

//
// class ActivityItem {
//   final String time;
//   final String name;
//   final String description;
//   final Color color;
//   final String photoUrl;
//   final List<String> studentList;
//   final String createdBy;
//
//   const ActivityItem({
//     required this.time,
//     required this.name,
//     required this.description,
//     required this.color,
//     required this.photoUrl,
//     required this.studentList,
//     required this.createdBy
//   });
// }
