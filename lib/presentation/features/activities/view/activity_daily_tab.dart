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
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/nap_activity.dart';
import 'package:wowcare/presentation/features/activities/widgets/avtivity_media_preview.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_tab_shared_helpers.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/guardian_code_resolver.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/activity_feed_invalidation.dart';
import 'package:wowcare/core/utils/cache_manager.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
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
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';
import 'package:wowcare/domain/features/activity/services/activity_feed_display_rules.dart';
import 'package:wowcare/domain/features/activity/services/activity_staff_display.dart';
import 'activity_feed_card_permissions.dart';
import '../model/activity_item.dart';
import '../model/activity_feed_grouping.dart';

export '../model/activity_item.dart';
export '../model/activity_feed_grouping.dart';
export '../model/activity_item_from_feed_row.dart';
export 'activity_feed_card_permissions.dart';
export 'package:wowcare/presentation/features/activities/model/activity_item_edit_mappers.dart'
    show activityItemFromActivityDetail, studentDataMapsForActivityEdit;
export 'package:wowcare/data/features/activity/mappers/activity_patch_attachments.dart'
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

class ActivityDailyTab extends StatelessWidget {
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
    this.deepLinkStudentCode,
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

  /// The child a notification deep-link is about (GUARDIAN persona only).
  ///
  /// For a guardian the feed's subject is the selected child, not a classroom,
  /// so a parent of two children needs to know WHICH child the tapped
  /// notification concerns. This used to be carried only by the separate
  /// `ParentChildCubit.selectByCode` call in `NotificationNavigator` /
  /// `NotificationCenterScreen`, which meant the feed loaded whichever child
  /// happened to be selected whenever that call hadn't landed yet — a
  /// cold-launch tap (the splash route never made it at all) or a tap that
  /// crossed a school switch (which resets the cubit, so the selection is
  /// deferred until its list reloads).
  ///
  /// Untrusted payload input: it is only honoured after being matched against
  /// the guardian's own student page fetched in [_bootstrapParentHome], so a
  /// code for someone else's child is ignored, never queried.
  final String? deepLinkStudentCode;

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
      child: _ActivityDailyTabView(
        fromStudentProfile: fromStudentProfile,
        studentName: studentName,
        studentProfile: studentProfile,
        isNotParent: isNotParent,
        allowActivityWrite: allowActivityWrite,
        highlightCode: highlightCode,
        highlightDate: highlightDate,
        highlightClassroomCode: highlightClassroomCode,
        deepLinkStudentCode: deepLinkStudentCode,
        onRefreshStaffSignInStatus: onRefreshStaffSignInStatus,
      ),
    );
  }
}

class _ActivityDailyTabView extends StatefulWidget {
  const _ActivityDailyTabView({
    this.fromStudentProfile = false,
    this.studentName,
    this.studentProfile,
    this.isNotParent = true,
    this.allowActivityWrite = true,
    this.highlightCode,
    this.highlightDate,
    this.highlightClassroomCode,
    this.deepLinkStudentCode,
    this.onRefreshStaffSignInStatus,
  });

  final String? highlightCode;
  final DateTime? highlightDate;
  final String? highlightClassroomCode;
  final String? deepLinkStudentCode;
  final bool fromStudentProfile;
  final String? studentName;
  final Map<String, dynamic>? studentProfile;
  final bool isNotParent;
  final bool allowActivityWrite;
  final Future<void> Function()? onRefreshStaffSignInStatus;

  @override
  State<_ActivityDailyTabView> createState() => _ActivityDailyTabViewState();
}

class _ActivityDailyTabViewState extends State<_ActivityDailyTabView>
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
  static const int _feedPageSize = 10;
  final ScrollController _feedScrollController = ScrollController();
  bool _isFeedRequestInFlight = false;
  String? _lastFeedRequestKey;
  DateTime? _lastFeedCompletedAt;
  bool _lastFeedCompletedWithError = false;
  String? _feedError;
  String? _schoolCode;

  /// Logged-in user's display name; used when feed [createdBy] is "system", etc.
  String _viewerStaffDisplayName = '';
  String _viewerStaffCode = '';
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  Map<String, String> _tagNameToCode = {};
  final Set<String> _studentCodesForTagFilter = {};

  /// Guardian home: children we may show activities for.
  final Set<String> _parentAllowedStudentCodes = {};

  /// The child the feed is CURRENTLY scoped to, as `{studentCode: classroomCode}`.
  /// Its keys drive `ActivityFeedCubit.loadDailyForGuardian`'s per-student
  /// fan-out, so it deliberately holds exactly one entry for a guardian.
  final Map<String, String> _parentStudentClassroomByCode = {};

  /// EVERY linked child's classroom, from the last successful bootstrap.
  ///
  /// [_parentStudentClassroomByCode] is narrowed to the selected child because
  /// its keys are the fan-out set; that narrowing is what made
  /// [_syncWithGlobalChildSelection] see a `null` classroom for every OTHER
  /// child and re-run the whole guardian/student-page bootstrap on each switch.
  /// Keeping the unnarrowed map here lets a switch between already-known
  /// children apply immediately, with no refetch and no chance of two
  /// concurrent bootstraps interleaving their `clear()`s.
  final Map<String, String> _parentClassroomByStudentCodeAll = {};

  /// Guards against [_bootstrapParentHome] being re-entered — `build` schedules
  /// [_syncWithGlobalChildSelection] on every frame, so an in-flight (or
  /// failing) bootstrap would otherwise be restarted frame after frame.
  bool _parentBootstrapInFlight = false;

  // Staff persona scoping
  List<String> _allowedClassroomCodes = const [];
  String? _primaryClassroomCode;
  bool _loadingParentContext = false;
  String? _lastGlobalSelectedStudentCode;

  /// Whether the rows on screen answer the question currently being asked —
  /// this child, this day, this room. Starts false: an empty list before the
  /// first load means "we don't know yet", not "there are none".
  ///
  /// Cleared by [_beginFeedLoad] and set by [_endFeedLoad], which is what keeps
  /// the two leaks of the "No Activities found" empty state closed:
  ///
  ///  * **before the first load** — the pre-bootstrap window, which spans
  ///    `_bootstrapSchoolZone()` (storage + the timezone API) and
  ///    `_bootstrap()`'s storage reads. Nothing was flagged as loading yet (the
  ///    cubit doesn't exist, so `_effectiveFeedState` falls back to
  ///    `ActivityFeedState.initial()`, and `_loadingParentContext` is only set
  ///    once `_bootstrapParentHome` is genuinely running), so the screen
  ///    claimed there were no activities before it had looked;
  ///  * **on a deep link into an already-open tab** — this State is keep-alive
  ///    inside an `IndexedStack`, so when the route key doesn't change it is
  ///    reused, carrying the PREVIOUS visit's completed (and possibly empty)
  ///    result. `didUpdateWidget` would render that stale answer to the new
  ///    question for a frame before its reload flipped the cubit's `isLoading`
  ///    — the reported "empty, then a loader, then the list".
  bool _feedResultIsCurrent = false;

  /// The feed is busy, or has no result for the current scope: show the loader,
  /// not "No Activities found". See [shouldShowActivityFeedLoadingPlaceholder]
  /// for the rule and why a bootstrap error deliberately does not hold the
  /// loader open.
  bool get _showFeedLoadingPlaceholder =>
      shouldShowActivityFeedLoadingPlaceholder(
        isLoading: _displayedLoadingFeed,
        isLoadingParentContext: _loadingParentContext,
        hasCurrentResult: _feedResultIsCurrent,
        hasBootstrapError: _feedError != null,
      );

  /// Marks the on-screen rows stale because a (re)load has just been decided.
  ///
  /// Must run **synchronously**, before the first `await` of the load, so no
  /// frame can be painted between the decision and the placeholder going up.
  void _beginFeedLoad() {
    if (!_feedResultIsCurrent) return;
    _feedResultIsCurrent = false;
    if (mounted) setState(() {});
  }

  /// Marks the on-screen rows as the answer to the current scope — the load
  /// finished, so an empty list now genuinely means "no activities".
  void _endFeedLoad() {
    if (_feedResultIsCurrent) return;
    _feedResultIsCurrent = true;
    if (mounted) setState(() {});
  }

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
  // parent daily-feed paths now live in [ActivityFeedCubit] — the staff
  // branch calls [ActivityFeedCubit.loadDaily]/`loadNextPage`, the parent
  // branch calls [ActivityFeedCubit.loadDailyForGuardian]/`loadNextPage`
  // (see `_loadParentHomeDailyFeed`/`_loadNextParentHomeDailyFeedPage`). One
  // cubit instance is shared across both, since `_parentHome` is fixed for
  // the life of a given State instance (a persona switch remounts the whole
  // screen — see `ActivityFeedScreen._contextReloadEpoch`) — the two paths
  // never drive the same cubit instance concurrently from one State.
  //
  // The cubit is created LAZILY (on first use from [_loadDailyFeed]/
  // [_loadNextDailyFeedPage], whichever persona branch runs first), NOT via
  // `BlocProvider.create` at the outer `ActivityDailyTab.build()` — `create`
  // there would run before `_bootstrap()`/`_bootstrapSchoolZone()` resolve
  // `_viewerStaffDisplayName`/`_schoolIana`, freezing the cubit's
  // [ActivityFeedPresentation] with empty/fallback values for the whole
  // widget lifetime (those two String fields are NOT live references, unlike
  // the two Map/Set fields below). By construction time, every call site
  // only ever runs after those are resolved.
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
  /// [_loadDailyFeed] call, so reading this before the cubit exists is
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
  List<ActivityItem> get _displayedActivities =>
      _withClientFilters(_effectiveFeedState.items);

  bool get _displayedLoadingFeed => _effectiveFeedState.isLoading;

  bool get _displayedLoadingMoreFeed => _effectiveFeedState.isLoadingMore;

  bool get _displayedFeedHasMore => _effectiveFeedState.hasMore;

  /// `_feedError` is still written directly by `_bootstrap()`/
  /// `_bootstrapParentHome()` for bootstrap-level failures (school not
  /// selected / classrooms failed to load / guardian profile failed to
  /// resolve) — those happen before a query can even be built, so they can't
  /// flow through the cubit. A bootstrap error takes priority (the feed can't
  /// run without a resolved school/classroom-or-student-map); otherwise fall
  /// back to the cubit's own load error.
  String? get _displayedFeedError => _feedError ?? _effectiveFeedState.error;

  final List<Color> _colorPalette = AppColors.activityDailyColorPalette;
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

  /// View: same screens as edit, read-only.
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
    } catch (e) {
      AppLogger.d('staff cache invalidation on refresh failed: $e');
    }
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

  /// `_filterTags` holds tag NAMES (the multi-select shows names) — the
  /// attendance/absent endpoints' `tagCodes` query param, and the student-code
  /// resolution in `_rebuildStudentCodesForTagFilter`, both need actual codes.
  /// Case-insensitive fallback because `_tagNameToCode`'s keys come from the
  /// API's own casing, which may not exactly match a name round-tripped
  /// through the multi-select. A name with no resolved code (stale
  /// selection, options not loaded yet) is dropped rather than sent as a
  /// bogus filter value.
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
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
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
    } catch (e) {
      AppLogger.d('classroom cache read failed, falling back to network: $e');
    }

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
      final classrooms = await _feedScope.getActiveClassrooms(
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

  /// The child the GUARDIAN feed should load — see
  /// [resolveGuardianFeedStudentCode] for the precedence and why the
  /// deep-link's student outranks the dropdown exactly once.
  ///
  /// The owned set is [_parentClassroomByStudentCodeAll], the student page just
  /// fetched for this guardian, so an unowned code is never queried. Returns
  /// null only when the guardian has no children with a classroom, which the
  /// caller already reports as its own error.
  String? _resolveParentFeedStudentCode() {
    final deepLink = widget.deepLinkStudentCode;
    final resolved = resolveGuardianFeedStudentCode(
      deepLinkStudentCode: deepLink,
      deepLinkAlreadyApplied: _deepLinkStudentApplied,
      selectedChildCode: context.read<ParentChildCubit>().selectedChild?.code,
      ownedStudentCodes: _parentClassroomByStudentCodeAll.keys,
    );
    // Burn the one-shot only when the deep link is what actually answered,
    // so a tap whose child could not be resolved this time (list still
    // settling) can still win the retry.
    if (resolved != null &&
        !_deepLinkStudentApplied &&
        resolved.toUpperCase() == (deepLink ?? '').trim().toUpperCase()) {
      _deepLinkStudentApplied = true;
    }
    return resolved;
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
        // feed state (no network call), matching `_loadParentHomeDailyFeed`'s
        // not-ready handling.
        await _loadDailyFeed(refresh: true);
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

      // Which child this feed is for. See [_resolveParentFeedStudentCode] for
      // the precedence and why the deep-link's student outranks the dropdown.
      final targetCode = _resolveParentFeedStudentCode();
      if (targetCode != null) {
        // Push the resolution back into the app's single source of truth, so
        // the app-bar switcher (and every other parent screen) agrees with the
        // feed. This is also what keeps the post-frame
        // `_syncWithGlobalChildSelection` from immediately re-scoping to the
        // PREVIOUSLY selected child and firing a second fetch: the latch below
        // and the cubit now hold the same code. No-op when they already match.
        context.read<ParentChildCubit>().selectByCode(targetCode);

        final targetClassroom = _parentClassroomByStudentCodeAll[targetCode];
        _parentAllowedStudentCodes
          ..clear()
          ..add(targetCode);
        _parentStudentClassroomByCode.clear();
        if (targetClassroom != null && targetClassroom.trim().isNotEmpty) {
          _parentStudentClassroomByCode[targetCode] = targetClassroom.trim();
        }
        _lastGlobalSelectedStudentCode = targetCode;
      }

      if (_parentAllowedStudentCodes.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'No linked children with a classroom.';
            _loadingParentContext = false;
          });
        }
        // Empty student map -> the cubit's own not-ready guard clears its
        // feed state (no network call), matching `_loadParentHomeDailyFeed`'s
        // not-ready handling.
        await _loadDailyFeed(refresh: true);
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
    } finally {
      // Released even on the early `return`s and the `if (!mounted) return`
      // above, so a failed bootstrap can be retried by the next selection
      // change rather than wedging the guard on forever.
      _parentBootstrapInFlight = false;
    }
  }

  /// Re-scopes the feed when the global child dropdown changes.
  ///
  /// Two things here are deliberate and were previously wrong:
  ///
  /// * **The latch is set only once the switch has actually been applied.** It
  ///   used to be set BEFORE the (async, network-backed) bootstrap, so if that
  ///   bootstrap failed — an offline moment, a 5xx on the student page — the
  ///   guard already believed the new child was live. Every later call
  ///   early-returned and the feed stayed on the PREVIOUS child indefinitely,
  ///   with the app bar showing the new one. That is only reachable for a
  ///   parent with more than one child.
  /// * **A child whose classroom is already known switches with no refetch**,
  ///   via [_parentClassroomByStudentCodeAll]. The narrowed map can never
  ///   answer for another child (its keys are the fan-out set), so every switch
  ///   used to re-run the whole guardian + student-page bootstrap.
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
      // No parent context yet, or a child we've never resolved a classroom for
      // (newly linked / newly enrolled). Fetch it; the bootstrap sets the latch
      // itself once it succeeds. Not latching here is what makes a failure
      // retryable.
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

    // Hold the loading placeholder across the switch. The rows on screen still
    // belong to the PREVIOUS child until the new fetch emits, and if that child
    // happened to have an empty day the feed would drop to "No Activities
    // found" for the gap before `loadDailyForGuardian` flips `isLoading` — the
    // same wrong-empty-state the deep-link path had.
    setState(() {
      _loadingParentContext = true;
    });
    unawaited(
      _loadDailyFeed(refresh: true).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _loadingParentContext = false;
        });
      }),
    );
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
      // STAFF path is fully cubit-backed now — nothing local to clear here;
      // `_loadDailyFeed`'s own not-ready guard (called by
      // `_reloadStudentsAndSettingsThenFeed`) clears the cubit's feed state.
      return;
    }

    final code = _classroomCodeByName[classroomName]!;
    final studentsCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'students',
      identifier: code,
    );

    try {
      final settings = await _feedScope.loadActivityTypeSettingsForFilters(
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
      } catch (e) {
        AppLogger.d('student-classroom cache read failed for $classroomName: $e');
      }
    }

    try {
      final students = await _feedScope.getStudentClassroomList(
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
        final students = await _feedScope.getStudentClassroomList(
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
      } catch (e) {
        AppLogger.d('getStudentClassroomList failed for $classroomCode: $e');
      }
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
        final students = await _feedScope.getStudentClassroomList(
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
      } catch (e) {
        AppLogger.d('getStudentClassroomList failed for $classroomCode: $e');
      }
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

  void _onFeedScroll() {
    _maybeLoadNextDailyFeedPage();
  }

  void _maybeLoadNextDailyFeedPage() {
    if (!_feedScrollController.hasClients) return;
    if (_displayedLoadingMoreFeed ||
        !_displayedFeedHasMore ||
        _displayedLoadingFeed ||
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
    if (_parentHome) {
      return _loadNextParentHomeDailyFeedPage();
    }

    // STAFF path: delegate to ActivityFeedCubit, which has its own
    // single-flight (`isLoadingMore`) and `hasMore`/`isLoading` guards — see
    // its `loadNextPage()` doc. Nothing to paginate if no first page has ever
    // been requested (cubit not yet created).
    if (_feedCubitInstance == null) return;
    await _feedCubit.loadNextPage();
  }

  /// GUARDIAN/parent path: delegates to [ActivityFeedCubit.loadDailyForGuardian]
  /// — the per-student fan-out (each child fetched in its own classroom,
  /// merged) — instead of running the fan-out here. `school`/`date`
  /// resolution still has to happen in the View (the cubit can't build a
  /// query without them), but the "no linked children" not-ready case is
  /// covered by the cubit's own guard (`studentClassroomByCode.isEmpty`), so
  /// it's no longer checked here before calling. The request-key de-dupe/
  /// throttle wrapper (`_lastFeedRequestKey`/`_isFeedRequestInFlight`/
  /// `_lastFeedCompletedAt`/`_lastFeedCompletedWithError`) is the same one
  /// the STAFF branch below uses — shared fields, never written by both
  /// branches from the same State instance (see the Mandate 2 note above
  /// `_feedCubitInstance`).
  Future<void> _loadParentHomeDailyFeed({bool refresh = false}) async {
    // Synchronously, before any await: whatever is on screen no longer answers
    // the question we are about to ask.
    _beginFeedLoad();
    final school = _schoolCode;
    final date = _selectedDate;
    if (school == null || school.isEmpty || date == null) {
      // Mirrors the STAFF branch's not-ready handling below: nothing to
      // clear before a cubit exists (see `_effectiveFeedState`'s fallback),
      // and once one exists, drive it back to its own not-ready state.
      if (_feedCubitInstance != null) {
        await _feedCubit.loadDailyForGuardian(
          const ActivityFeedQuery(
            organizationCode: '',
            schoolCode: '',
            classroomCode: '',
            dateStr: '',
          ),
          const <String, String>{},
        );
      }
      return;
    }

    // Note there is deliberately no `_endFeedLoad()` on the not-ready return
    // above: "not ready" means the school, day or child map is still
    // resolving, which is exactly when the loader must hold. Every genuine
    // dead end (no school selected, guardian profile unresolvable, no linked
    // children) sets `_feedError` instead, which the display rule treats as
    // terminal — so this cannot spin forever.
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
    final includeAttendance =
        _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();
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
      // The in-flight case leaves the result stale on purpose — the request
      // that is already running will end the load.
      if (_isFeedRequestInFlight) return;
      if (!_lastFeedCompletedWithError) {
        // Same scope as the completed request: the rows on screen already ARE
        // the answer, so re-affirm them rather than holding the placeholder.
        _endFeedLoad();
        _scheduleHighlightScroll();
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          AppTime.nowUtc().difference(completedAt) <
              const Duration(seconds: 3)) {
        _endFeedLoad();
        _scheduleHighlightScroll();
        return;
      }
    }

    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    // Fetch, per-student fan-out merge, tri-source assembly, sort/group/
    // dedupe and hasMore computation are all now owned by ActivityFeedCubit
    // (a verbatim port of this branch) — see its class doc. It also owns its
    // own generation/school-switch staleness guard, so `_feedGeneration`/
    // `_isStaleFeedResponse` are no longer consulted here (they remain the
    // STAFF branch's mechanism below).
    await _feedCubit.loadDailyForGuardian(
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
        dateStr: dateStr,
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
    // The fetch is done, so the rows on screen now answer the current scope —
    // an empty list from here on genuinely means "no activities". Set on the
    // error path too: an errored load is still a completed one, and the
    // message branch renders the error rather than the empty text.
    _endFeedLoad();
    if (feedError != null) {
      if (mounted) {
        CoreUtils.logApiError(feedError, showOnScreen: true, context: context);
      }
    } else {
      _scheduleHighlightScroll();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadNextDailyFeedPage(),
      );
    }
  }

  /// GUARDIAN/parent pagination: delegates to [ActivityFeedCubit.loadNextPage],
  /// which has its own single-flight (`isLoadingMore`) and `hasMore`/
  /// `isLoading` guards and continues the guardian fan-out it stored from the
  /// most recent [ActivityFeedCubit.loadDailyForGuardian] call — see its doc.
  /// Nothing to paginate if no first page has ever been requested (cubit not
  /// yet created), matching the STAFF pagination function below.
  Future<void> _loadNextParentHomeDailyFeedPage() async {
    if (_feedCubitInstance == null) return;
    await _feedCubit.loadNextPage();
  }

  Future<void> _loadDailyFeed({bool refresh = false}) async {
    if (_parentHome) {
      return _loadParentHomeDailyFeed(refresh: refresh);
    }

    // Synchronously, before any await — see [_beginFeedLoad].
    _beginFeedLoad();
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
      // Mirrors the old clear-on-not-ready — only meaningful once a cubit
      // (and therefore possibly stale items) exists; nothing to clear before
      // that, since `_effectiveFeedState` already falls back to
      // `ActivityFeedState.initial()`. An empty schoolCode/classroomCode/
      // dateStr is exactly ActivityFeedCubit.loadDaily's own "not ready" gate.
      if (_feedCubitInstance != null) {
        await _feedCubit.loadDaily(
          const ActivityFeedQuery(
            organizationCode: '',
            schoolCode: '',
            classroomCode: '',
            dateStr: '',
          ),
        );
      }
      return;
    }

    // As in the guardian branch, the not-ready return above deliberately does
    // NOT end the load: every genuine dead end sets `_feedError` instead.
    final dateStr = _dateQueryParam(date);

    // Resolve the active tag filter to student codes BEFORE fetching/filtering
    // below — without this, `_studentCodesForTagFilter` stays permanently
    // empty for the STAFF persona (only the guardian branch above called this),
    // so `_withTagFilterOnly`/`_withClientFilters` always filtered every item
    // out regardless of which tags were selected. Mirrors the Custom tab's
    // `_loadRangeFeed`, which already awaits this before its own fetch.
    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

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
        // Same request is already running; skip duplicate calls. The result
        // stays stale on purpose — the running request will end the load.
        return;
      }
      if (!_lastFeedCompletedWithError) {
        // Last identical request already completed successfully
        // (including empty-result success). No need to refetch — but the rows
        // ARE already loaded, so a pending deep-link still needs its scroll.
        // Returning here previously skipped it entirely, which is why a cached
        // feed highlighted without ever scrolling. Same scope as that
        // completed request, so the rows on screen already are the answer.
        _endFeedLoad();
        _scheduleHighlightScroll();
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          AppTime.nowUtc().difference(completedAt) <
              const Duration(seconds: 3)) {
        // Throttle repeated failed requests for same filters.
        _endFeedLoad();
        _scheduleHighlightScroll();
        return;
      }
    }

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    final selectedStudentCode =
        (studentCodes != null && studentCodes.isNotEmpty)
        ? studentCodes.first
        : null;
    final typeCodes = _activityTypeCodesForApiFilter();
    final approvalStatuses = _approvalStatusesForApiFilter();
    final includeAttendance =
        _filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries();

    // Fetch, tri-source merge, sort/group/dedupe and hasMore computation are
    // all now owned by ActivityFeedCubit (a verbatim port of this branch) —
    // see its class doc. It also owns its own generation/school-switch
    // staleness guard, so `_feedGeneration`/`_isStaleFeedResponse` are no
    // longer consulted here (they remain the parent path's mechanism).
    await _feedCubit.loadDaily(
      ActivityFeedQuery(
        // Unused by ActivityFeedCubit today (not read anywhere in its fetch
        // path) — left empty rather than threading a new organizationCode
        // resolution through this View for a field the cubit doesn't consume.
        organizationCode: '',
        schoolCode: school,
        classroomCode: classroomCode,
        classroomCodes: classroomCodes,
        dateStr: dateStr,
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
    // The fetch is done, so the rows on screen now answer the current scope —
    // an empty list from here on genuinely means "no activities". Set on the
    // error path too: an errored load is still a completed one, and the
    // message branch renders the error rather than the empty text.
    _endFeedLoad();
    if (feedError != null) {
      if (mounted) {
        CoreUtils.logApiError(feedError, showOnScreen: true, context: context);
      }
    } else {
      _scheduleHighlightScroll();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadNextDailyFeedPage(),
      );
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
  void didUpdateWidget(covariant _ActivityDailyTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A deep-link about a DIFFERENT child arriving without a remount — the
    // route key only changes when there IS a highlightCode, so a student-only
    // change (or a link carrying no highlight at all) lands here instead.
    // Routed through the cubit rather than re-scoped locally so the app-bar
    // switcher and the feed stay in step; `_syncWithGlobalChildSelection` picks
    // it up on the next frame and does the re-scope + reload.
    if (_parentHome &&
        widget.deepLinkStudentCode != oldWidget.deepLinkStudentCode) {
      _deepLinkStudentApplied = false;
      final code = (widget.deepLinkStudentCode ?? '').trim();
      if (code.isNotEmpty) {
        context.read<ParentChildCubit>().selectByCode(code);
      }
    }

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
      // The scope just changed under us, so the rows currently on screen answer
      // the PREVIOUS notification's question. Invalidating here — in the same
      // frame the new target is applied — is what stops a reused keep-alive
      // State from rendering its stale (possibly empty) result as
      // "No Activities found" before `_loadDailyFeed` below flips the cubit's
      // `isLoading`.
      _feedResultIsCurrent = false;
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
      _loadDailyFeed(refresh: true);
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
  /// Driven by the DATA (the target's index in [_displayedActivities]), never by the
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
    final displayed = _displayedActivities;
    final index = displayed.indexWhere(
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
      final total = displayed.length;
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

  /// One-shot, like [_deepLinkClassroomApplied]: the deep-link's student is the
  /// subject of the TAP, not a standing override. Without this latch a later
  /// re-bootstrap — the one `_syncWithGlobalChildSelection` triggers when the
  /// user picks a child whose classroom isn't cached yet — would resolve back
  /// to the notification's child and fight the dropdown the user just used.
  bool _deepLinkStudentApplied = false;

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
        color: AppColors.cardColor,
      ),
      alignment: Alignment.center,
      child: const PrimaryCircularLoader(size: 40, strokeWidth: 3.5),
    );

    return Padding(
      padding: ResponsiveHelper(context).contentPadding,
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

  Widget _buildTabBody(BuildContext context) {
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
                    padding: ResponsiveHelper(context).contentPadding,
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
                                      child: buildActivityTabCustomMultiDropdown(
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
                                      child:
                                          buildActivityTabCustomMultiDropdown(
                                            'Select Student',
                                            _availableStudents,
                                            _selectedStudents,
                                            (values) {
                                              setState(() {
                                                _selectedStudents = values;
                                                _selectedStudent =
                                                    values.isNotEmpty
                                                    ? values.first
                                                    : null;
                                              });
                                              _loadDailyFeed();
                                            },
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: AppColors.transparentColor,
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
                                                          const Color.fromRGBO(
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
                if (_showFeedLoadingPlaceholder && _displayedActivities.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: ResponsiveHelper(context).contentPadding,
                      child: SizedBox.expand(
                        child: Container(
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
                if (!_showFeedLoadingPlaceholder &&
                    _displayedActivities.isEmpty)
                  SliverToBoxAdapter(
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
                          child: AppText.title(
                            _displayedFeedError ?? 'No Activities found',
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
                if (_displayedActivities.isNotEmpty)
                  SliverPadding(
                    padding: ResponsiveHelper(context).contentPadding,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final displayedActivities = _displayedActivities;
                          if (index == displayedActivities.length) {
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
                          final activity = displayedActivities[index];
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
                                                    extra: args,
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
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: activityColor
                                                      .withValues(alpha: 0.15),
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
                                                                  child: Container(
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
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: AppTextStyles
                                                                          .activitySmallText,
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
                                                                          color:
                                                                              AppColors.themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        final destinationBuilder =
                                                                            activityRoutes[activity.name];
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
                                                                            await _loadDailyFeed(
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
                                                                            color:
                                                                                AppColors.themeColor,
                                                                          ),
                                                                        ),
                                                                        onTap: () async {
                                                                          final destinationBuilder =
                                                                              editActivityRoutes[activity.name];
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
                                                                              extra: args,
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
                                                                            Icons.check_circle_outline,
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
                                                                            Icons.cancel_outlined,
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
                                                                            Icons.delete,
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
                                                                                AppColors.transparentColor,
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
                                                              fontFamily:
                                                                  Fonts.manrope,
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
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        childCount:
                            _displayedActivities.length +
                            (_displayedLoadingMoreFeed ? 1 : 0),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
            ),
          );
        } else {
          return CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Padding(
                  padding: ResponsiveHelper(context).contentPadding,
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
                                    child: buildActivityTabCustomMultiDropdown(
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
                                        _loadDailyFeed();
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

                if (_showFeedLoadingPlaceholder && _displayedActivities.isEmpty)
                  Expanded(
                    child: _portraitOverscrollFeedWrapper(
                      child: _dailyFeedLoadingSheet(context),
                    ),
                  ),

                if (!_showFeedLoadingPlaceholder &&
                    _displayedActivities.isEmpty)
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
                            child: AppText.title(
                              _displayedFeedError ?? 'No Activities found',
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

                if (_displayedActivities.isNotEmpty)
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
                                  _displayedActivities.length +
                                  (_displayedLoadingMoreFeed ? 1 : 0),
                              itemBuilder: (context, index) {
                                final displayedActivities =
                                    _displayedActivities;
                                if (index == displayedActivities.length) {
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
                                final activity = displayedActivities[index];
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
                                                      final (
                                                        routeName,
                                                        args,
                                                      ) = destinationBuilder(
                                                        activity,
                                                      );
                                                      await context.push(
                                                        routeName,
                                                        extra: args,
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
                                                                : Container(
                                                                    width: 122,
                                                                    height: 76,
                                                                    color: Colors
                                                                        .white,
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
                                                                              style: AppTextStyles.activitySmallText,
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
                                                                                style: AppTextStyles.activityMetaText,
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
                                                                              final (
                                                                                routeName,
                                                                                args,
                                                                              ) = destinationBuilder(
                                                                                activity,
                                                                              );
                                                                              await context.push(
                                                                                routeName,
                                                                                extra: args,
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
                                                                                final (
                                                                                  routeName,
                                                                                  args,
                                                                                ) = destinationBuilder(
                                                                                  activity,
                                                                                );
                                                                                await context.push(
                                                                                  routeName,
                                                                                  extra: args,
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
                                                                                backgroundColor: AppColors.transparentColor,
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
                  selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(selectedDate)
                      : 'Select Date',
                  style: AppTextStyles.activityDropdownValueText(
                    hasValue: selectedDate != null,
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
        Text(title, style: AppTextStyles.activityPopupItemTitle),
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
      return AppColors.activityApprovalStatusNotRequiredColor;
    case 'PENDING_ADMIN_APPROVAL':
      return AppColors.activityApprovalStatusPendingColor;
    case 'APPROVED':
      return AppColors.activityApprovalStatusApprovedColor;
    case 'REJECTED':
      return AppColors.activityApprovalStatusRejectedColor;
    case 'PARENT_ACKNOWLEDGEMENT_PENDING':
      return AppColors.activityApprovalStatusPendingColor;
    case 'ACKNOWLEDGED':
      return AppColors.activityApprovalStatusApprovedColor;
    default:
      return AppColors.activityApprovalStatusDefaultColor;
  }
}

/// Student codes aligned (by index) to [activity.studentList], so feed-card
/// avatars can resolve the real profile photo instead of showing initials.
/// Uses [ActivityItem.studentActivityRefs] (name→code), falling back to the
/// single `studentCode` for single-student activities.
