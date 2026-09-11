import 'dart:async';
import 'package:wowcare/core/utils/app_time.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/guardian_code_resolver.dart';
import 'package:wowcare/core/utils/activity_feed_invalidation.dart';
import 'package:wowcare/core/utils/cache_manager.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_query.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_scope_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_state.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_moderation_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_feed_student_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/activities/model/activity_route_args.dart';
import 'activity_filter_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/activities/widgets/avtivity_media_preview.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_tab_shared_helpers.dart';
import 'package:wowcare/domain/features/activity/services/activity_feed_display_rules.dart';

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
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _classroomNameByCode = {};
  final Map<String, String> _studentCodeByName = {};
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  Map<String, String> _tagNameToCode = {};
  final Set<String> _studentCodesForTagFilter = {};
  final Set<String> _parentAllowedStudentCodes = {};

  /// The child the feed is CURRENTLY scoped to, `{studentCode: classroomCode}`.
  /// Its keys are the guardian fan-out set, so for a guardian it normally holds
  /// exactly one entry.
  final Map<String, String> _parentStudentClassroomByCode = {};

  /// EVERY linked child's classroom, from the last successful bootstrap — see
  /// the daily tab's field of the same name for why the narrowed map above
  /// cannot answer for a sibling.
  final Map<String, String> _parentClassroomByStudentCodeAll = {};

  /// Guards [_bootstrapParentHome] against re-entry from the per-frame
  /// [_syncWithGlobalChildSelection] scheduled in `build`.
  bool _parentBootstrapInFlight = false;
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

  // --------------------------------------------------------------------------
  // Mandate 2 (final slice): BOTH the STAFF/non-parent AND the GUARDIAN/
  // parent RANGE-feed paths now live in [ActivityFeedCubit] — the staff
  // branch calls [ActivityFeedCubit.loadRange]/`loadNextPage`, the parent
  // branch calls [ActivityFeedCubit.loadRangeForGuardian]/`loadNextPage`
  // (see `_loadParentHomeRangeFeed`/`_loadNextParentHomeRangeFeedPage`). One
  // cubit instance is shared across both, since `_parentHome` is fixed for
  // the life of a given State instance (a persona switch remounts the whole
  // screen) — the two paths never drive the same cubit instance concurrently
  // from one State. Mirrors `activity_daily_tab.dart`'s final-slice wiring of
  // `ActivityFeedCubit.loadDaily`/`loadDailyForGuardian` verbatim; see that
  // file's matching comment for the full rationale.
  //
  // The cubit is created LAZILY (on first use from [_loadRangeFeed]/
  // [_loadNextRangeFeedPage], whichever persona branch runs first), NOT via
  // `BlocProvider.create` at the outer widget's `build()` — `create` there
  // would run before `_bootstrapSchoolZone()`/`_bootstrapRangeFeed()` resolve
  // `_viewerStaffDisplayName`/`_schoolIana`, freezing the cubit's
  // [ActivityFeedPresentation] with empty/fallback values for the whole
  // widget lifetime. By construction time, every call site only ever runs
  // after those are resolved.
  ActivityFeedCubit? _feedCubitInstance;

  // BlocBuilder (wrapping `_buildTabBody` in `build()`) subscribes to this
  // cubit's stream itself now — no manual StreamSubscription to hold/cancel.
  ActivityFeedCubit get _feedCubit {
    final existing = _feedCubitInstance;
    if (existing != null) return existing;
    final cubit = ActivityFeedCubit(
      dataSource: _feedScope,
      storageService: _storageService,
      presentation: ActivityFeedPresentation(
        viewerStaffDisplayName: _viewerStaffDisplayName,
        schoolIana: _schoolIana,
        // Live references (both fields are `final` and only ever mutated
        // in place via clear()/addAll()/addEntries()) so the cubit keeps
        // seeing up-to-date values even though presentation itself is
        // resolved once, at cubit-creation time.
        classroomNameByCode: _classroomNameByCode,
        tagStudentCodes: _studentCodesForTagFilter,
      ),
    );
    _feedCubitInstance = cubit;
    return cubit;
  }

  /// The cubit's state if it has been created yet, else the same defaults
  /// `ActivityFeedState.initial()` carries (empty/not-loading) — which is
  /// exactly what the pre-migration local fields held before the first
  /// [_loadRangeFeed] call, so reading this before the cubit exists is
  /// behaviourally identical to the old pre-bootstrap render.
  ActivityFeedState get _effectiveFeedState =>
      _feedCubitInstance?.state ?? ActivityFeedState.initial();

  /// Both personas (STAFF and GUARDIAN/parent) are now cubit-backed: the
  /// View's `_withClientFilters` (multi-select activity-type narrowing +
  /// approval-status re-filter) is intentionally NOT applied inside the
  /// cubit (see its `_mapDailyFeedPageToItems` NOTE) because it depends on
  /// View-only state (`_filterActivityTypes`, `_classroomActivitySettings`)
  /// that isn't part of the resolved query. Applied here, as a pure
  /// post-fetch transform, at every display read site, for both personas.
  /// Note: unlike `activity_daily_tab.dart`, this file keeps its pre-existing
  /// (non-"ed") getter name `_displayActivities` — already the sole read site
  /// at every render call — instead of introducing a differently-named
  /// `_displayedActivities`.
  List<ActivityItem> get _displayActivities =>
      _sortItemsByLatestFirst(_withClientFilters(_effectiveFeedState.items));

  bool get _displayedLoadingFeed => _effectiveFeedState.isLoading;

  bool get _displayedLoadingMoreFeed => _effectiveFeedState.isLoadingMore;

  bool get _displayedFeedHasMore => _effectiveFeedState.hasMore;

  /// Whether the rows on screen answer the currently selected scope. Mirrors
  /// `activity_daily_tab.dart`'s latch of the same name — see it for the two
  /// windows that used to render "No Activities found" wrongly.
  bool _feedResultIsCurrent = false;

  /// The feed is busy, or has no result for the current scope: show the loader,
  /// not "No Activities found". See [shouldShowActivityFeedLoadingPlaceholder].
  bool get _showFeedLoadingPlaceholder =>
      shouldShowActivityFeedLoadingPlaceholder(
        isLoading: _displayedLoadingFeed,
        isLoadingParentContext: _loadingParentContext,
        hasCurrentResult: _feedResultIsCurrent,
        hasBootstrapError: _feedError != null,
      );

  /// Marks the on-screen rows stale because a (re)load has just been decided.
  /// Must run synchronously, before the load's first `await`.
  void _beginFeedLoad() {
    if (!_feedResultIsCurrent) return;
    _feedResultIsCurrent = false;
    if (mounted) setState(() {});
  }

  /// Marks the on-screen rows as the answer to the current scope.
  void _endFeedLoad() {
    if (_feedResultIsCurrent) return;
    _feedResultIsCurrent = true;
    if (mounted) setState(() {});
  }

  /// `_feedError` is still written directly by bootstrap
  /// (`_bootstrapRangeFeed`/`_loadStaffClassroomScope`/`_bootstrapParentHome`)
  /// for bootstrap-level failures (school not selected / classrooms failed to
  /// load / guardian profile failed to resolve) — those happen before a
  /// query can even be built, so they can't flow through the cubit. A
  /// bootstrap error takes priority; otherwise fall back to the cubit's own
  /// load error. Mirrors `activity_daily_tab.dart`'s `_displayedFeedError`.
  String? get _displayedFeedError => _feedError ?? _effectiveFeedState.error;

  final List<String> activityType = [
    'Sign-in',
    'Sign-out',
    'Transfer',
    'Marked Absent',
  ];
  final Map<String, List<String>> classroomStudents = {};
  final List<String> _classroomOptions = [];

  // Map activity label to the destination edit route name + typed args.
  static final Map<String, (String, Object) Function(ActivityItem)>
  editActivityRoutes = {
    'Nap Start': (activity) => (
      NapActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Nap End': (activity) => (
      NapActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Bathroom': (activity) => (
      BathroomActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Bottle': (activity) => (
      BottleActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Meal': (activity) => (
      MealActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Incident': (activity) => (
      IncidentActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Photo': (activity) => (
      PhotoVideoActivityScreen.routeName,
      PhotoVideoActivityScreenArgs(
        activityData: activity,
        isEdit: true,
        isPhoto: true,
      ),
    ),
    'Video': (activity) => (
      PhotoVideoActivityScreen.routeName,
      PhotoVideoActivityScreenArgs(
        activityData: activity,
        isEdit: true,
        isPhoto: false,
      ),
    ),
    'Medication': (activity) => (
      MedicationActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Notes': (activity) => (
      NotesActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Outdoor': (activity) => (
      OutdoorActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
    'Learning': (activity) => (
      LearningActivityScreen.routeName,
      ActivityTypeScreenArgs(activityData: activity, isEdit: true),
    ),
  };

  static final Map<String, (String, Object) Function(ActivityItem)>
  activityRoutes = {
    'Nap Start': (activity) => (
      NapActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Nap End': (activity) => (
      NapActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Bathroom': (activity) => (
      BathroomActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Bottle': (activity) => (
      BottleActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Meal': (activity) => (
      MealActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Incident': (activity) => (
      IncidentActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Photo': (activity) => (
      PhotoVideoActivityScreen.routeName,
      PhotoVideoActivityScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
        isPhoto: true,
      ),
    ),
    'Video': (activity) => (
      PhotoVideoActivityScreen.routeName,
      PhotoVideoActivityScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
        isPhoto: false,
      ),
    ),
    'Medication': (activity) => (
      MedicationActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Notes': (activity) => (
      NotesActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Outdoor': (activity) => (
      OutdoorActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
    ),
    'Learning': (activity) => (
      LearningActivityScreen.routeName,
      ActivityTypeScreenArgs(
        activityData: activity,
        isEdit: true,
        readOnly: true,
      ),
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
    } catch (e) {
      AppLogger.d('_bootstrapSchoolZone failed: $e');
    }
  }

  @override
  void dispose() {
    _feedInvalidationSub?.cancel();
    _moderationSub?.cancel();
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    _feedCubitInstance?.close();
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
      // Both personas are cubit-backed now: item removal lives inside
      // ActivityFeedCubit's state, which has no local-splice API — a full
      // refetch reconciles it instead (approve/reject already took this
      // path; delete now does too, for both STAFF and GUARDIAN/parent).
      // Mirrors activity_daily_tab.dart's equivalent tradeoff for
      // _loadDailyFeed/ActivityFeedCubit.
      _loadRangeFeed(refresh: true);
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
    if (_displayedLoadingMoreFeed ||
        !_displayedFeedHasMore ||
        _isFeedRequestInFlight) {
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
      // Silent by design: this runs on every pairwise sort comparison, so
      // logging a parse miss here would spam the log per malformed row
      // instead of once. Falls through to the display-string parse below.
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
      } catch (e) {
        AppLogger.d(
          'unparsable date/time "$cardDate $normalizedTime", sorting as epoch: $e',
        );
      }
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

  Future<void> _loadNextRangeFeedPage() async {
    if (_parentHome) {
      return _loadNextParentHomeRangeFeedPage();
    }

    // STAFF path: delegate to ActivityFeedCubit, which has its own
    // single-flight (`isLoadingMore`) and `hasMore`/`isLoading` guards — see
    // its `loadNextPage()` doc. Nothing to paginate if no first page has ever
    // been requested (cubit not yet created). Mirrors
    // activity_daily_tab.dart's `_loadNextDailyFeedPage`.
    if (_feedCubitInstance == null) return;
    await _feedCubit.loadNextPage();
  }

  /// GUARDIAN/parent path: delegates to [ActivityFeedCubit.loadRangeForGuardian]
  /// — the per-student fan-out (each child fetched in its own classroom over
  /// the date range, merged) — instead of running the fan-out here.
  /// `school`/`start`/`end` resolution still has to happen in the View (the
  /// cubit can't build a query without them), but the "no linked children"
  /// not-ready case is covered by the cubit's own guard
  /// (`studentClassroomByCode.isEmpty`), so it's no longer checked here
  /// before calling. The request-key de-dupe/throttle wrapper
  /// (`_lastFeedRequestKey`/`_isFeedRequestInFlight`/`_lastFeedCompletedAt`/
  /// `_lastFeedCompletedWithError`) is the same one the STAFF branch below
  /// uses — shared fields, never written by both branches from the same
  /// State instance (see the Mandate 2 note above `_feedCubitInstance`).
  /// Mirrors `activity_daily_tab.dart`'s `_loadParentHomeDailyFeed`.
  Future<void> _loadParentHomeRangeFeed({bool refresh = false}) async {
    // Synchronously, before any await — see [_beginFeedLoad].
    _beginFeedLoad();
    final school = _schoolCode;
    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (school == null || school.isEmpty || start == null || end == null) {
      // Mirrors the STAFF branch's not-ready handling below: nothing to
      // clear before a cubit exists (see `_effectiveFeedState`'s fallback),
      // and once one exists, drive it back to its own not-ready state.
      if (_feedCubitInstance != null) {
        await _feedCubit.loadRangeForGuardian(
          const ActivityFeedQuery(
            organizationCode: '',
            schoolCode: '',
            classroomCode: '',
            dateStr: '',
            endDateStr: '',
          ),
          const <String, String>{},
        );
      }
      return;
    }

    // The not-ready return above deliberately does NOT end the load: "not
    // ready" means the school, range or child map is still resolving, which is
    // exactly when the loader must hold. Every genuine dead end sets
    // `_feedError` instead, which the display rule treats as terminal.
    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    final codes = _parentAllowedStudentCodes.toList()..sort();
    final selectedEvent = _selectedAttendanceEventFilter();
    final signInAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-in')
        ? 'NOT_NULL'
        : null;
    final signOutAtFilter =
        (!_isMarkedAbsentEvent(selectedEvent) && selectedEvent == 'Sign-out')
        ? 'NOT_NULL'
        : null;
    final typeCodes = _activityTypeCodesForApiFilter();
    final approvalStatuses = _approvalStatusesForApiFilter();
    final includeAttendance =
        _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();
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
      // In-flight: leave the result stale, the running request will end it.
      if (_isFeedRequestInFlight) return;
      // Same scope as the completed request, so the rows on screen already ARE
      // the answer — re-affirm them rather than holding the placeholder.
      if (!_lastFeedCompletedWithError) {
        _endFeedLoad();
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

    // Fetch, per-student fan-out merge, tri-source assembly, sort/group/
    // dedupe and hasMore computation are all now owned by ActivityFeedCubit
    // (a verbatim port of this branch) — see its class doc. It also owns its
    // own generation/school-switch staleness guard, so `_feedGeneration`/
    // `_isStaleFeedResponse` are no longer consulted here (they remain the
    // STAFF branch's mechanism below).
    await _feedCubit.loadRangeForGuardian(
      ActivityFeedQuery(
        // Unused by ActivityFeedCubit's guardian fan-out (not read anywhere
        // in its fetch path) — left empty rather than threading a new
        // organizationCode resolution through this View for a field the
        // cubit doesn't consume.
        organizationCode: '',
        schoolCode: school,
        // Per-student classroom scoping comes from `studentClassroomByCode`
        // below, not this field — the cubit's fan-out ignores it.
        classroomCode: '',
        dateStr: _dateQueryParam(start),
        endDateStr: _dateQueryParam(end),
        attendanceEvent: selectedEvent,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        typeCodes: typeCodes,
        approvalStatuses: approvalStatuses,
        tagCodes: _tagCodesForApiFilter(),
        guardianPersona: true,
        includeAttendance: includeAttendance,
        isMarkedAbsentEvent: _isMarkedAbsentEvent(selectedEvent),
        pageSize: _feedPageSize,
      ),
      Map<String, String>.from(_parentStudentClassroomByCode),
      refresh: refresh,
    );

    _isFeedRequestInFlight = false;
    _lastFeedCompletedAt = AppTime.nowUtc();
    final feedError = _feedCubit.state.error;
    _lastFeedCompletedWithError = feedError != null;
    // Fetch done: the rows on screen now answer the current scope. Set on the
    // error path too — an errored load is still a completed one, and the
    // message branch renders the error rather than the empty text.
    _endFeedLoad();
    if (feedError != null) {
      if (mounted) {
        CoreUtils.logApiError(feedError, showOnScreen: true, context: context);
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeLoadNextRangeFeedPage(),
    );
  }

  /// GUARDIAN/parent pagination: delegates to [ActivityFeedCubit.loadNextPage],
  /// which has its own single-flight (`isLoadingMore`) and `hasMore`/
  /// `isLoading` guards and continues the guardian fan-out it stored from the
  /// most recent [ActivityFeedCubit.loadRangeForGuardian] call — see its doc.
  /// Nothing to paginate if no first page has ever been requested (cubit not
  /// yet created), matching the STAFF pagination function below.
  Future<void> _loadNextParentHomeRangeFeedPage() async {
    if (_feedCubitInstance == null) return;
    await _feedCubit.loadNextPage();
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

    final result = await context.push<Map<String, List<String>>>(
      ActivityFilterScreen.routeName,
      extra: ActivityFilterArgs(
        schoolCode: school,
        classroomCode: classroomCode,
        initialFilters: {
          'Tags': List<String>.from(_filterTags),
          'Activity Type': List<String>.from(_filterActivityTypes),
          'Status': List<String>.from(_filterApprovalStatuses),
        },
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
      } catch (e) {
        AppLogger.d('getStudentClassroomList failed for $classroomCode: $e');
      }
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
      } catch (e) {
        AppLogger.d('getStudentClassroomList failed for $classroomCode: $e');
      }
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

  /// `_filterTags` holds tag NAMES (the multi-select shows names) — the
  /// attendance/absent endpoints' `tagCodes` query param, and the student-code
  /// resolution below, both need actual codes. Case-insensitive fallback
  /// because `_tagNameToCode`'s keys come from the API's own casing, which
  /// may not exactly match a name round-tripped through the multi-select. A
  /// name with no resolved code (stale selection, options not loaded yet) is
  /// dropped rather than sent as a bogus filter value.
  List<String> _tagCodesForApiFilter() {
    final tagNameToCodeLower = <String, String>{
      for (final e in _tagNameToCode.entries)
        e.key.trim().toLowerCase(): e.value,
    };
    return _filterTags
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
  }

  Future<void> _rebuildStudentCodesForTagFilter() async {
    _studentCodesForTagFilter.clear();
    if (_filterTags.isEmpty || !mounted) return;
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;

    final tagCodes = _tagCodesForApiFilter();
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
    } catch (e) {
      AppLogger.d('classroom cache read failed, falling back to network: $e');
    }

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
      } catch (e) {
        AppLogger.d('decodeCodes: malformed cached classroom-codes JSON: $e');
      }
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
    if (_parentBootstrapInFlight) return;
    _parentBootstrapInFlight = true;

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
          });
        }
        // Empty student map -> the cubit's own not-ready guard clears its
        // feed state (no network call), matching `_loadParentHomeRangeFeed`'s
        // not-ready handling.
        await _loadRangeFeed(refresh: true);
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
      _parentClassroomByStudentCodeAll.clear();
      for (final s in page.items) {
        final code = s.code.trim();
        if (code.isEmpty) continue;
        final cc = s.classroom.trim();
        if (cc.isEmpty) continue;
        _parentAllowedStudentCodes.add(code);
        _parentStudentClassroomByCode[code] = cc;
        _parentClassroomByStudentCodeAll[code] = cc;
      }

      // Which child this feed is for. The Custom tab is never an activity
      // notification's own destination (the resolver emits no `tab` param, so
      // those always land on Daily), hence no deep-link student here — but the
      // dropdown selection can still be unresolved when a parent switches to
      // this tab right after a cold launch. Falling back to the first linked
      // child keeps the range feed scoped to ONE child instead of fanning out
      // over all of them and rendering a merged list that then shrinks.
      final globalSelectedCode =
          resolveGuardianFeedStudentCode(
            deepLinkStudentCode: null,
            deepLinkAlreadyApplied: true,
            selectedChildCode: context
                .read<ParentChildCubit>()
                .selectedChild
                ?.code,
            ownedStudentCodes: _parentClassroomByStudentCodeAll.keys,
          ) ??
          '';
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
          });
        }
        // Empty student map -> the cubit's own not-ready guard clears its
        // feed state (no network call), matching `_loadParentHomeRangeFeed`'s
        // not-ready handling.
        await _loadRangeFeed(refresh: true);
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
    } finally {
      // Released on every exit path (including the early `return`s above) so a
      // failed bootstrap stays retryable.
      _parentBootstrapInFlight = false;
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
      backgroundColor: AppColors.transparentColor,
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

    // Synchronously, before any await — see [_beginFeedLoad].
    _beginFeedLoad();
    final classroomCodes = _selectedClassroomCodesForFeed();
    final classroomCode = classroomCodes.isNotEmpty
        ? classroomCodes.first
        : null;
    final classroomName =
        _selectdClassroom ??
        (classroomCode == null ? null : _classroomNameByCode[classroomCode]);
    final classroomNameKey = classroomName ?? (classroomCode ?? '');
    if (classroomCode == null || classroomCode.trim().isEmpty) {
      // Mirrors the old clear-on-not-ready — only meaningful once a cubit
      // (and therefore possibly stale items) exists; nothing to clear before
      // that, since `_effectiveFeedState` already falls back to
      // `ActivityFeedState.initial()`. Mirrors activity_daily_tab.dart's
      // `_loadDailyFeed` not-ready guard.
      if (_feedCubitInstance != null) {
        await _feedCubit.loadRange(
          const ActivityFeedQuery(
            organizationCode: '',
            schoolCode: '',
            classroomCode: '',
            dateStr: '',
            endDateStr: '',
          ),
        );
      }
      return;
    }

    // As in the guardian branch, the not-ready returns here and just below
    // deliberately do NOT end the load: every genuine dead end sets
    // `_feedError` instead.
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
      // In-flight: leave the result stale, the running request will end it.
      if (_isFeedRequestInFlight) return;
      // Same scope as the completed request — the rows on screen are already
      // the answer.
      if (!_lastFeedCompletedWithError) {
        _endFeedLoad();
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

    // Fetch, tri-source merge, sort/group/dedupe and hasMore computation are
    // all now owned by ActivityFeedCubit.loadRange (a verbatim port of this
    // branch) — see its class doc. It also owns its own generation/
    // school-switch staleness guard, so `_feedGeneration`/
    // `_isStaleFeedResponse` are no longer consulted here for the feed items
    // (they remain the parent path's mechanism, mirroring
    // activity_daily_tab.dart's `_loadDailyFeed`).
    await _feedCubit.loadRange(
      ActivityFeedQuery(
        // Unused by ActivityFeedCubit today (not read anywhere in its fetch
        // path) — left empty rather than threading a new organizationCode
        // resolution through this View for a field the cubit doesn't consume.
        organizationCode: '',
        schoolCode: _schoolCode ?? '',
        classroomCode: classroomCode,
        classroomCodes: classroomCodes,
        dateStr: _dateQueryParam(start),
        endDateStr: _dateQueryParam(end),
        studentCode: selectedStudentCode,
        studentCodes: studentCodes,
        attendanceEvent: selectedEvent,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        typeCodes: typeCodes,
        approvalStatuses: approvalStatuses,
        tagCodes: _tagCodesForApiFilter(),
        guardianPersona: false,
        includeAttendance: includeAttendance,
        isMarkedAbsentEvent: _isMarkedAbsentEvent(selectedEvent),
        pageSize: _feedPageSize,
      ),
      refresh: refresh,
    );

    _isFeedRequestInFlight = false;
    _lastFeedCompletedAt = AppTime.nowUtc();
    final feedError = _feedCubit.state.error;
    _lastFeedCompletedWithError = feedError != null;
    // Fetch done: the rows on screen now answer the current scope. Set on the
    // error path too — an errored load is still a completed one, and the
    // message branch renders the error rather than the empty text.
    _endFeedLoad();
    if (feedError != null) {
      if (mounted) {
        CoreUtils.logApiError(feedError, showOnScreen: true, context: context);
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeLoadNextRangeFeedPage(),
    );

    // Non-blocking classroom-students / activity-type-settings reload. This
    // does NOT read `activityFeedPage` (it re-fetches its own
    // `getStudentClassroomList`/`loadActivityTypeSettingsForFilters` calls),
    // so it stays here unchanged from the pre-cubit code, running after a
    // successful ActivityFeedCubit.loadRange exactly as it ran after the old
    // inline fetch succeeded. activity_daily_tab.dart's `_loadDailyFeed` has
    // no equivalent block — this is specific to the range tab.
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
            } catch (e) {
              AppLogger.d('student-classroom cache read failed for $classroomNameKey: $e');
            }
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
    } catch (e) {
      AppLogger.d('staff cache invalidation on refresh failed: $e');
    }
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

  /// Re-scopes the range feed when the global child dropdown changes.
  ///
  /// Mirrors the daily tab's method of the same name — see its doc for why the
  /// latch must not be set before the async bootstrap (a failed bootstrap
  /// otherwise strands a multi-child parent on the previous child) and why the
  /// unnarrowed classroom map exists.
  void _syncWithGlobalChildSelection() {
    if (!_parentHome) return;
    final globalSelectedCode =
        (context.read<ParentChildCubit>().selectedChild?.code ?? '').trim();
    if (globalSelectedCode.isEmpty) return;
    if (_lastGlobalSelectedStudentCode == globalSelectedCode) return;

    final classroom =
        _parentStudentClassroomByCode[globalSelectedCode] ??
        _parentClassroomByStudentCodeAll[globalSelectedCode];

    if (classroom == null || classroom.trim().isEmpty) {
      unawaited(_bootstrapParentHome());
      return;
    }

    _lastGlobalSelectedStudentCode = globalSelectedCode;

    _parentAllowedStudentCodes
      ..clear()
      ..add(globalSelectedCode);
    _parentStudentClassroomByCode
      ..clear()
      ..[globalSelectedCode] = classroom.trim();

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
    // BlocBuilder (not the old manual `cubit.stream.listen((_) { setState() })`
    // + StreamSubscription pair) is what actually subscribes to feed-cubit
    // emissions now — Mandate 2's named anti-pattern. `_feedCubit` still
    // lazily constructs the cubit on first access (deliberately deferred past
    // `viewerStaffDisplayName`/`schoolIana` bootstrap, per the doc on that
    // getter), so touching it here to supply `bloc:` is exactly the same
    // trigger point the old getter-based read already was.
    return BlocBuilder<ActivityFeedCubit, ActivityFeedState>(
      bloc: _feedCubit,
      builder: (context, _) => _buildTabBody(context),
    );
  }

  // Renders the same layout regardless of orientation — landscape used to
  // early-return an empty SizedBox here, which is why the Custom tab went
  // blank (feed never rendered, filters/date range never restored) whenever
  // the device was rotated. Responsive sizing (ResponsiveSizing.contentPadding
  // etc.) already adapts this layout across widths, so no separate landscape
  // tree is needed.
  Widget _buildTabBody(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          Padding(
            padding: ResponsiveHelper(context).contentPadding,
            // filter card
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerColor),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.cardColor,
              ),
              child: widget.fromStudentProfile && !isNotParent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 40,
                          child: AbsorbPointer(
                            child: buildActivityTabCustomDropdown(
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
                              child: buildActivityTabCustomMultiDropdown(
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
                              child: buildActivityTabCustomMultiDropdown(
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
                              color: AppColors.transparentColor,
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
                                            padding: const EdgeInsets.symmetric(
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
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              badgeCount > 99
                                                  ? '99+'
                                                  : '$badgeCount',
                                              style: AppTextStyles
                                                  .activitySmallBadgeText,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

          if (_showFeedLoadingPlaceholder && _displayActivities.isEmpty)
            Expanded(
              child: _portraitOverscrollFeedWrapper(
                child: Padding(
                  padding: ResponsiveHelper(context).contentPadding,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardColor,
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
          if (!_showFeedLoadingPlaceholder && _displayActivities.isEmpty)
            Expanded(
              child: _portraitOverscrollFeedWrapper(
                child: Padding(
                  padding: ResponsiveHelper(context).contentPadding,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardColor,
                    ),
                    child: Center(
                      child: Text(
                        _displayedFeedError ?? 'No Activities found',
                        style: AppTextStyles.activityEmptyFeedText,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_displayActivities.isNotEmpty)
            Expanded(
              child: Padding(
                padding: ResponsiveHelper(context).contentPadding,
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
                            (_displayedLoadingMoreFeed ? 1 : 0),
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
                                      style: AppTextStyles.activityBodyValue,
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
                                              isAdminPersona: _isAdminPersona,
                                              viewerStaffCode: _viewerStaffCode,
                                            );
                                        final destinationBuilder = canOpenEdit
                                            ? editActivityRoutes[activity.name]
                                            : activityRoutes[activity.name];
                                        if (destinationBuilder != null) {
                                          final (routeName, args) =
                                              destinationBuilder(activity);
                                          await context.push(
                                            routeName,
                                            extra: args,
                                          );
                                          if (mounted) {
                                            await _loadRangeFeed(refresh: true);
                                          }
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 15),
                                          Container(
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
                                                color: activityColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: SizedBox(
                                                    width: 140,
                                                    height: 120,
                                                    child:
                                                        activityHasMediaOrProcessing(
                                                          activity,
                                                        )
                                                        ? ActivityMediaPreview(
                                                            activity: activity,
                                                            activityColor:
                                                                activityColor,
                                                          )
                                                        : Container(
                                                            width: 122,
                                                            height: 76,
                                                            color: AppColors
                                                                .cardColor,
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
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Wrap(
                                                              spacing: 8,
                                                              runSpacing: 6,
                                                              crossAxisAlignment:
                                                                  WrapCrossAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
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
                                                                    style: AppTextStyles
                                                                        .activitySmallText,
                                                                  ),
                                                                ),
                                                                if (activityApprovalStatusBadgeLabel(
                                                                      activity
                                                                          .approvalStatus,
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
                                                                        activity
                                                                            .approvalStatus,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      activityApprovalStatusBadgeLabel(
                                                                            activity.approvalStatus,
                                                                          ) ??
                                                                          '',
                                                                      style: AppTextStyles
                                                                          .activityMetaText,
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
                                                              onSelected: null,
                                                              itemBuilder: (context) => [
                                                                PopupMenuItem<
                                                                  String
                                                                >(
                                                                  value: 'view',
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
                                                                      final (
                                                                        routeName,
                                                                        args,
                                                                      ) = destinationBuilder(
                                                                        activity,
                                                                      );
                                                                      await context.push(
                                                                        routeName,
                                                                        extra:
                                                                            args,
                                                                      );
                                                                      if (mounted) {
                                                                        await _loadRangeFeed(
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
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                    onTap: () async {
                                                                      final destinationBuilder =
                                                                          editActivityRoutes[activity
                                                                              .name];
                                                                      if (destinationBuilder !=
                                                                          null) {
                                                                        final (
                                                                          routeName,
                                                                          args,
                                                                        ) = destinationBuilder(
                                                                          activity,
                                                                        );
                                                                        await context.push(
                                                                          routeName,
                                                                          extra:
                                                                              args,
                                                                        );
                                                                        if (mounted) {
                                                                          await _loadRangeFeed(
                                                                            refresh:
                                                                                true,
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
                                                                        color: AppColors
                                                                            .themeColor,
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
                                                                        color: AppColors
                                                                            .themeColor,
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
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                    onTap: () {
                                                                      showModalBottomSheet(
                                                                        context:
                                                                            context,
                                                                        isScrollControlled:
                                                                            true,
                                                                        backgroundColor:
                                                                            AppColors.transparentColor,
                                                                        builder: (ctx) {
                                                                          return DeleteConfirmationBottomSheet(
                                                                            name:
                                                                                activity.name,
                                                                            type:
                                                                                'Activity',
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
                                                      Text(
                                                        'Created By - ${activity.createdBy}',

                                                        style: AppTextStyles
                                                            .activityMetaText,
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

  Widget _datePickerFilter({
    required DateTime? selectedStartDate,
    required DateTime? selectedEndDate,
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
          color: AppColors.activitySoftPurpleFieldColor.withValues(
            alpha: 0.102,
          ),
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
                  style: AppTextStyles.activityDropdownValueText(
                    hasValue: selectedStartDate != null,
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
}

// PopupItem is defined in activity_daily_tab.dart (imported above) — both
// screens shared a byte-identical copy of this widget; this file now reuses
// that one instead of maintaining its own.
