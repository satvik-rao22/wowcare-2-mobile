import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart'
    hide StudentAttendanceTime;
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_data_source.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_query.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_state.dart';
import 'package:wowcare/domain/features/activity/services/activity_parent_feed_merge.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item.dart';
// Reuses the top-level, presentation-agnostic feed helpers that live in the
// daily-tab library (importing them, per the migration plan — the View is NOT
// modified): the row→item mapper, the multi-student grouper, the stable-id
// deduper, and the option-label priming/lookup.
import 'package:wowcare/presentation/features/activities/model/activity_feed_grouping.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item_from_feed_row.dart';

/// Presentation context the page→item mappers need but which is NOT part of the
/// resolved API [ActivityFeedQuery]: viewer display name, school IANA zone,
/// classroom name lookup, and the tag→student-code set that `_withTagFilterOnly`
/// filters against. The migrating View will construct this from its own fields;
/// tests pass a minimal instance. Defaults are inert so the merge/pagination/
/// stale/dedup logic can be exercised without it.
class ActivityFeedPresentation {
  const ActivityFeedPresentation({
    this.viewerStaffDisplayName = '',
    this.schoolIana = '',
    this.classroomNameByCode = const <String, String>{},
    this.tagStudentCodes = const <String>{},
    this.selectedDate,
    this.staffDisplayNameByCode = const <String, String>{},
  });

  /// Logged-in staff display name; used when a feed/attendance row has no
  /// explicit actor (`createdBy`/`signedInBy`/... empty).
  final String viewerStaffDisplayName;

  /// School IANA zone for wall-clock → UTC conversion of attendance/absent rows.
  final String schoolIana;

  /// classroomCode → display name, for attendance/absent card descriptions.
  final Map<String, String> classroomNameByCode;

  /// Student codes resolved for the active tag filter. `_withTagFilterOnly`
  /// keeps only rows whose studentCode is in this set (when a tag is active).
  final Set<String> tagStudentCodes;

  /// The calendar day the feed is for; falls back to parsing the query's
  /// `dateStr`, then `AppTime.now()`.
  final DateTime? selectedDate;

  /// Seed of already-known staff code → display name (grows as rows are primed).
  final Map<String, String> staffDisplayNameByCode;
}

/// Testable, View-free ViewModel for the DAILY activity feed.
///
/// This is the relocation of `activity_daily_tab.dart`'s `_loadDailyFeed`
/// (full tri-source load) and `_loadNextDailyFeedPage` (pagination) — the
/// generation guard, school-at-start snapshot, single-flight, tri-source merge,
/// sort/group/dedupe and `hasMore` computation — into a cubit parameterized by a
/// resolved [ActivityFeedQuery]. Behavior is ported verbatim in spirit; the
/// View is left untouched (this is additive foundation for a later migration).
///
/// Data is fetched through the injected [ActivityFeedDataSource] (the existing
/// [ActivityFeedScopeCubit], which already exposes exactly these calls). The
/// live school for the school-switch guard is read from [StorageService], the
/// same way [StaffCubit] does.
class ActivityFeedCubit extends Cubit<ActivityFeedState> {
  ActivityFeedCubit({
    required ActivityFeedDataSource dataSource,
    required StorageService storageService,
    ActivityFeedPresentation presentation = const ActivityFeedPresentation(),
  }) : _dataSource = dataSource,
       _storage = storageService,
       _presentation = presentation,
       _staffDisplayNameByCode = Map<String, String>.from(
         presentation.staffDisplayNameByCode,
       ),
       super(ActivityFeedState.initial());

  final ActivityFeedDataSource _dataSource;
  final StorageService _storage;
  final ActivityFeedPresentation _presentation;

  /// Grows as feed rows are primed; passed to [activityItemFromFeedRow].
  final Map<String, String> _staffDisplayNameByCode;

  /// Monotonic load generation. Bumped by every [loadDaily]; a response
  /// captured at an older generation is discarded before emit.
  int _generation = 0;

  /// Single-flight guard for [loadNextPage], set synchronously before the first
  /// await so a re-entrant call is a no-op (mirrors `_loadingMoreFeed`).
  bool _loadingMore = false;

  /// Live school as of the most recent storage read; refreshed immediately
  /// before each stale check. See [_isStale].
  String? _liveSchoolCode;

  /// The query the currently-loaded feed belongs to (for [loadNextPage]).
  ActivityFeedQuery? _query;

  /// When non-null, the currently-loaded feed is a GUARDIAN/PARENT fan-out
  /// (one feed call per student, each in its own classroom) — set by
  /// [loadDailyForGuardian]/[loadRangeForGuardian] and consulted by
  /// [loadNextPage] to continue the same fan-out for the next page. Cleared
  /// back to `null` by a subsequent plain [loadDaily]/[loadRange] so
  /// pagination doesn't stay in guardian fan-out mode after a non-guardian
  /// load. Maps studentCode -> that student's classroomCode.
  Map<String, String>? _guardianClassroomByCode;

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Full daily-feed load — port of `_loadDailyFeed`. Bumps the generation,
  /// snapshots the live school, runs the tri-source merge (activity feed +
  /// optional attendance + optional absent records keyed off
  /// [ActivityFeedQuery.includeAttendance]/`attendanceEvent`/`isMarkedAbsentEvent`),
  /// maps + tag-filters + sorts + groups + dedupes, computes `hasMore`, and
  /// DISCARDS the whole response if it went stale (closed / newer generation /
  /// live school changed) before emitting.
  Future<void> loadDaily(
    ActivityFeedQuery query, {
    bool refresh = false,
  }) async {
    _query = query;
    _guardianClassroomByCode = null;

    if (query.schoolCode.isEmpty ||
        query.classroomCode.isEmpty ||
        query.dateStr.isEmpty) {
      // Mirrors the View's early-return: clear the feed when the request isn't
      // ready (no school / classroom / date resolved yet).
      if (!isClosed) {
        emit(
          state.copyWith(
            items: const <ActivityItem>[],
            isLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            nextPage: 0,
            query: query,
          ),
        );
      }
      return;
    }

    final feedGen = ++_generation;
    final schoolAtStart = await _readLiveSchool();

    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: !refresh,
          isRefreshing: refresh,
          isLoadingMore: false,
          hasMore: true,
          error: null,
          generation: feedGen,
          query: query,
        ),
      );
    }

    try {
      final activityFeedPage = await _dataSource.getDailyActivityFeed(
        classroomCode: query.classroomCode,
        date: query.dateStr,
        studentCode: query.studentCode,
        classroomCodes: query.classroomCodes,
        studentCodes: query.studentCodes,
        activityTypeCodes: query.typeCodes,
        approvalStatuses: query.approvalStatuses,
        guardianPersona: query.guardianPersona,
        page: 0,
        size: query.pageSize,
      );

      final sub = await _fetchAttendanceSubPages(query, page: 0);

      await _primeStaffDisplayNames(activityFeedPage.content);
      await primeActivityFeedOptionLabelsFromRows(activityFeedPage.content);

      // Attendance/absent rows are already tag-filtered server-side (see
      // _fetchAttendanceSubPages's `tagCodes`) — no client-side re-filter here.
      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._mapAttendanceDailyPageToItems(sub.attendance!, query),
        if (sub.absent != null) ..._mapAbsentRecordsPageToItems(sub.absent!),
        ..._mapDailyFeedPageToItems(activityFeedPage, query),
      ]..sort(_compareActivityItemsByTimeDesc);

      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;

      final grouped = dedupeActivitiesByStableId(
        groupMultiStudentFeedItems(
          items,
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc),
      );
      final hasMore =
          (sub.attendance?.hasMore ?? false) ||
          (sub.absent?.hasMore ?? false) ||
          !activityFeedPage.last;

      emit(
        state.copyWith(
          items: grouped,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          hasMore: hasMore,
          nextPage: hasMore ? 1 : 0,
          generation: feedGen,
          query: query,
        ),
      );
    } catch (e) {
      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: false,
          error: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Full range-feed load — the date-RANGE counterpart of [loadDaily], port
  /// of `activity_custom_tab.dart`'s `_loadRangeFeed`. Structurally identical
  /// to [loadDaily] (same generation guard, same live-school snapshot, same
  /// emit-loading/emit-result/emit-error shape) except: it additionally
  /// requires [ActivityFeedQuery.endDateStr] to be non-empty before it will
  /// run, it calls [ActivityFeedDataSource.getRangeActivityFeed] instead of
  /// `getDailyActivityFeed` (start/end bound instead of a single date), and it
  /// threads `query.endDateStr` through to [_fetchAttendanceSubPages] so the
  /// attendance/absent sub-fetches are range-bound too.
  Future<void> loadRange(
    ActivityFeedQuery query, {
    bool refresh = false,
  }) async {
    _query = query;
    _guardianClassroomByCode = null;

    if (query.schoolCode.isEmpty ||
        query.classroomCode.isEmpty ||
        query.dateStr.isEmpty ||
        (query.endDateStr ?? '').isEmpty) {
      // Mirrors the View's early-return: clear the feed when the request isn't
      // ready (no school / classroom / start date / end date resolved yet).
      if (!isClosed) {
        emit(
          state.copyWith(
            items: const <ActivityItem>[],
            isLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            nextPage: 0,
            query: query,
          ),
        );
      }
      return;
    }

    final endDateStr = query.endDateStr!;
    final feedGen = ++_generation;
    final schoolAtStart = await _readLiveSchool();

    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: !refresh,
          isRefreshing: refresh,
          isLoadingMore: false,
          hasMore: true,
          error: null,
          generation: feedGen,
          query: query,
        ),
      );
    }

    try {
      final activityFeedPage = await _dataSource.getRangeActivityFeed(
        classroomCode: query.classroomCode,
        startDate: query.dateStr,
        endDate: endDateStr,
        studentCode: query.studentCode,
        classroomCodes: query.classroomCodes,
        studentCodes: query.studentCodes,
        activityTypeCodes: query.typeCodes,
        approvalStatuses: query.approvalStatuses,
        guardianPersona: query.guardianPersona,
        page: 0,
        size: query.pageSize,
      );

      final sub = await _fetchAttendanceSubPages(
        query,
        page: 0,
        endDateStr: endDateStr,
      );

      await _primeStaffDisplayNames(activityFeedPage.content);
      await primeActivityFeedOptionLabelsFromRows(activityFeedPage.content);

      // Attendance/absent rows are already tag-filtered server-side (see
      // _fetchAttendanceSubPages's `tagCodes`) — no client-side re-filter here.
      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._mapAttendanceDailyPageToItems(sub.attendance!, query),
        if (sub.absent != null) ..._mapAbsentRecordsPageToItems(sub.absent!),
        ..._mapDailyFeedPageToItems(activityFeedPage, query),
      ]..sort(_compareActivityItemsByTimeDesc);

      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;

      // Range queries require date+time match when grouping same-time,
      // same-classroom attendance events — otherwise same-time sign-ins on
      // DIFFERENT days would incorrectly merge into one card and silently
      // drop a day. Mirrors `_loadRangeFeed`'s `attendanceRequireDateAndTimeMatch:
      // true` (the daily path passes `false`, safe there because every row in
      // a daily page already shares one day).
      final grouped = dedupeActivitiesByStableId(
        groupMultiStudentFeedItems(
          items,
          attendanceRequireDateAndTimeMatch: true,
        )..sort(_compareActivityItemsByTimeDesc),
      );
      final hasMore =
          (sub.attendance?.hasMore ?? false) ||
          (sub.absent?.hasMore ?? false) ||
          !activityFeedPage.last;

      emit(
        state.copyWith(
          items: grouped,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          hasMore: hasMore,
          nextPage: hasMore ? 1 : 0,
          generation: feedGen,
          query: query,
        ),
      );
    } catch (e) {
      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: false,
          error: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// GUARDIAN/PARENT fan-out daily load — port of `activity_daily_tab.dart`'s
  /// `_loadParentHomeDailyFeed`. A guardian can have multiple children in
  /// DIFFERENT classrooms, so unlike [loadDaily] (one feed call, one
  /// classroom) this issues ONE `getDailyActivityFeed` call PER STUDENT in
  /// [studentClassroomByCode] (studentCode -> that student's classroomCode),
  /// merges the resulting pages via [mergeActivityFeedPages], and otherwise
  /// mirrors [loadDaily]'s generation guard / live-school snapshot / tri-source
  /// assembly / grouping (`attendanceRequireDateAndTimeMatch: false`, same as
  /// [loadDaily]) / emit shape. [baseQuery] carries every filter EXCEPT the
  /// per-student classroom scoping (its `classroomCode`/`studentCode`/
  /// `studentCodes` are not used for the fan-out); it must have
  /// `guardianPersona: true` set by the caller. The attendance/absent
  /// sub-fetch is guardian-scoped via [_fetchAttendanceSubPages]'s
  /// `studentCodesOverride` — see that method's doc for why `classroomCodes`
  /// is omitted entirely in that mode. Stores [studentClassroomByCode] so
  /// [loadNextPage] can continue the fan-out.
  Future<void> loadDailyForGuardian(
    ActivityFeedQuery baseQuery,
    Map<String, String> studentClassroomByCode, {
    bool refresh = false,
  }) async {
    _query = baseQuery;
    _guardianClassroomByCode = studentClassroomByCode;

    if (baseQuery.schoolCode.isEmpty ||
        baseQuery.dateStr.isEmpty ||
        studentClassroomByCode.isEmpty) {
      // Mirrors `_loadParentHomeDailyFeed`'s `_parentAllowedStudentCodes.isEmpty`
      // (plus school/date) early-return: clear the feed when the request isn't
      // ready.
      if (!isClosed) {
        emit(
          state.copyWith(
            items: const <ActivityItem>[],
            isLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            nextPage: 0,
            query: baseQuery,
          ),
        );
      }
      return;
    }

    final feedGen = ++_generation;
    final schoolAtStart = await _readLiveSchool();

    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: !refresh,
          isRefreshing: refresh,
          isLoadingMore: false,
          hasMore: true,
          error: null,
          generation: feedGen,
          query: baseQuery,
        ),
      );
    }

    try {
      final sub = await _fetchAttendanceSubPages(
        baseQuery,
        page: 0,
        studentCodesOverride: studentClassroomByCode.keys.toList(),
      );

      final merged = await _fetchGuardianFeedPage(
        studentClassroomByCode,
        baseQuery,
        isRange: false,
        page: 0,
      );

      await _primeStaffDisplayNames(merged.content);
      await primeActivityFeedOptionLabelsFromRows(merged.content);

      // Attendance/absent rows are already tag-filtered server-side (see
      // _fetchAttendanceSubPages's `tagCodes`) — no client-side re-filter here.
      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._mapAttendanceDailyPageToItems(sub.attendance!, baseQuery),
        if (sub.absent != null) ..._mapAbsentRecordsPageToItems(sub.absent!),
        ..._mapDailyFeedPageToItems(merged, baseQuery),
      ]..sort(_compareActivityItemsByTimeDesc);

      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;

      final grouped = dedupeActivitiesByStableId(
        groupMultiStudentFeedItems(
          items,
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc),
      );
      final hasMore =
          (sub.attendance?.hasMore ?? false) ||
          (sub.absent?.hasMore ?? false) ||
          !merged.last;

      emit(
        state.copyWith(
          items: grouped,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          hasMore: hasMore,
          nextPage: hasMore ? 1 : 0,
          generation: feedGen,
          query: baseQuery,
        ),
      );
    } catch (e) {
      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: false,
          error: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// GUARDIAN/PARENT fan-out range load — the date-RANGE counterpart of
  /// [loadDailyForGuardian], port of `activity_custom_tab.dart`'s
  /// `_loadParentHomeRangeFeed`. Same fan-out shape (one
  /// `getRangeActivityFeed` call per student, merged via
  /// [mergeActivityFeedPages]) except it additionally requires
  /// [ActivityFeedQuery.endDateStr] to be non-empty before it will run, and it
  /// groups with `attendanceRequireDateAndTimeMatch: true` (matching
  /// [loadRange], for the same reason: a range page's same-time attendance
  /// rows can span different days and must not collapse).
  Future<void> loadRangeForGuardian(
    ActivityFeedQuery baseQuery,
    Map<String, String> studentClassroomByCode, {
    bool refresh = false,
  }) async {
    _query = baseQuery;
    _guardianClassroomByCode = studentClassroomByCode;

    if (baseQuery.schoolCode.isEmpty ||
        baseQuery.dateStr.isEmpty ||
        (baseQuery.endDateStr ?? '').isEmpty ||
        studentClassroomByCode.isEmpty) {
      // Mirrors `_loadParentHomeRangeFeed`'s early-return.
      if (!isClosed) {
        emit(
          state.copyWith(
            items: const <ActivityItem>[],
            isLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            nextPage: 0,
            query: baseQuery,
          ),
        );
      }
      return;
    }

    final endDateStr = baseQuery.endDateStr!;
    final feedGen = ++_generation;
    final schoolAtStart = await _readLiveSchool();

    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: !refresh,
          isRefreshing: refresh,
          isLoadingMore: false,
          hasMore: true,
          error: null,
          generation: feedGen,
          query: baseQuery,
        ),
      );
    }

    try {
      final sub = await _fetchAttendanceSubPages(
        baseQuery,
        page: 0,
        endDateStr: endDateStr,
        studentCodesOverride: studentClassroomByCode.keys.toList(),
      );

      final merged = await _fetchGuardianFeedPage(
        studentClassroomByCode,
        baseQuery,
        isRange: true,
        page: 0,
      );

      await _primeStaffDisplayNames(merged.content);
      await primeActivityFeedOptionLabelsFromRows(merged.content);

      // Attendance/absent rows are already tag-filtered server-side (see
      // _fetchAttendanceSubPages's `tagCodes`) — no client-side re-filter here.
      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._mapAttendanceDailyPageToItems(sub.attendance!, baseQuery),
        if (sub.absent != null) ..._mapAbsentRecordsPageToItems(sub.absent!),
        ..._mapDailyFeedPageToItems(merged, baseQuery),
      ]..sort(_compareActivityItemsByTimeDesc);

      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;

      final grouped = dedupeActivitiesByStableId(
        groupMultiStudentFeedItems(
          items,
          attendanceRequireDateAndTimeMatch: true,
        )..sort(_compareActivityItemsByTimeDesc),
      );
      final hasMore =
          (sub.attendance?.hasMore ?? false) ||
          (sub.absent?.hasMore ?? false) ||
          !merged.last;

      emit(
        state.copyWith(
          items: grouped,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          hasMore: hasMore,
          nextPage: hasMore ? 1 : 0,
          generation: feedGen,
          query: baseQuery,
        ),
      );
    } catch (e) {
      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: false,
          error: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Pagination — port of `_loadNextDailyFeedPage`/`_loadNextRangeFeedPage`
  /// (staff) and `_loadNextParentHomeDailyFeedPage`/
  /// `_loadNextParentHomeRangeFeedPage` (guardian). Single-flight on
  /// [ActivityFeedState.isLoadingMore]; captures the generation WITHOUT
  /// bumping; appends the next page, regroups + dedupes against the existing
  /// items, advances `nextPage`, updates `hasMore`; DISCARDS the response if
  /// it went stale (a refresh bumped the generation / school switched) before
  /// emitting. Branches the FETCH step two ways — [_guardianClassroomByCode]
  /// non-null selects the guardian fan-out (further branching daily-vs-range
  /// internally, via [_fetchGuardianFeedPage]) vs. the single-classroom call
  /// (branching daily-vs-range on whether the active query's `endDateStr` is
  /// set) — while the single-flight guard, generation capture, staleness
  /// check, and emit shape below stay shared/unduplicated across both.
  Future<void> loadNextPage() async {
    final query = _query;
    if (query == null) return;
    if (_loadingMore || !state.hasMore || state.isLoading) return;
    final endDateStr = query.endDateStr;
    final isRange = (endDateStr ?? '').isNotEmpty;
    final guardianClassroomByCode = _guardianClassroomByCode;
    final isGuardian = guardianClassroomByCode != null;

    if (isGuardian) {
      if (query.schoolCode.isEmpty ||
          query.dateStr.isEmpty ||
          guardianClassroomByCode.isEmpty ||
          (isRange && (endDateStr ?? '').isEmpty)) {
        return;
      }
    } else if (query.schoolCode.isEmpty ||
        query.classroomCode.isEmpty ||
        query.dateStr.isEmpty ||
        (isRange && (endDateStr ?? '').isEmpty)) {
      return;
    }

    _loadingMore = true;
    final feedGen = _generation; // capture WITHOUT bumping
    final schoolAtStart = await _readLiveSchool();
    final pageIndex = state.nextPage;
    if (!isClosed) emit(state.copyWith(isLoadingMore: true));

    try {
      final activityFeedPage = isGuardian
          ? await _fetchGuardianFeedPage(
              guardianClassroomByCode,
              query,
              isRange: isRange,
              page: pageIndex,
            )
          : isRange
          ? await _dataSource.getRangeActivityFeed(
              classroomCode: query.classroomCode,
              startDate: query.dateStr,
              endDate: endDateStr!,
              studentCode: query.studentCode,
              classroomCodes: query.classroomCodes,
              studentCodes: query.studentCodes,
              activityTypeCodes: query.typeCodes,
              // Pagination intentionally omits approvalStatuses (mirrors the View).
              guardianPersona: query.guardianPersona,
              page: pageIndex,
              size: query.pageSize,
            )
          : await _dataSource.getDailyActivityFeed(
              classroomCode: query.classroomCode,
              date: query.dateStr,
              studentCode: query.studentCode,
              classroomCodes: query.classroomCodes,
              studentCodes: query.studentCodes,
              activityTypeCodes: query.typeCodes,
              // Pagination intentionally omits approvalStatuses (mirrors the View).
              guardianPersona: query.guardianPersona,
              page: pageIndex,
              size: query.pageSize,
            );

      final sub = await _fetchAttendanceSubPages(
        query,
        page: pageIndex,
        endDateStr: isRange ? endDateStr : null,
        studentCodesOverride: isGuardian
            ? guardianClassroomByCode.keys.toList()
            : null,
      );

      await _primeStaffDisplayNames(activityFeedPage.content);
      await primeActivityFeedOptionLabelsFromRows(activityFeedPage.content);

      // Attendance/absent rows are already tag-filtered server-side (see
      // _fetchAttendanceSubPages's `tagCodes`) — no client-side re-filter here.
      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._mapAttendanceDailyPageToItems(sub.attendance!, query),
        if (sub.absent != null) ..._mapAbsentRecordsPageToItems(sub.absent!),
        ..._mapDailyFeedPageToItems(activityFeedPage, query),
      ]..sort(_compareActivityItemsByTimeDesc);

      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;

      final merged = dedupeActivitiesByStableId(
        groupMultiStudentFeedItems(
          <ActivityItem>[...state.items, ...items],
          // See loadRange's comment: range pages need the date+time match to
          // avoid merging same-time attendance events across different days.
          attendanceRequireDateAndTimeMatch: isRange,
        )..sort(_compareActivityItemsByTimeDesc),
      );
      final hasMore =
          (sub.attendance?.hasMore ?? false) ||
          (sub.absent?.hasMore ?? false) ||
          !activityFeedPage.last;

      emit(
        state.copyWith(
          items: merged,
          hasMore: hasMore,
          nextPage: hasMore ? pageIndex + 1 : 0,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;
      emit(state.copyWith(hasMore: false, isLoadingMore: false));
    } finally {
      _loadingMore = false;
    }
  }

  // --------------------------------------------------------------------------
  // Guardian/parent fan-out feed fetch (one call per student, merged)
  // --------------------------------------------------------------------------

  /// Issues one `getDailyActivityFeed`/`getRangeActivityFeed` call PER STUDENT
  /// in [studentClassroomByCode] (studentCode -> that student's classroomCode)
  /// and merges the results via [mergeActivityFeedPages] — the fan-out shared
  /// by [loadDailyForGuardian]/[loadRangeForGuardian]'s first-page load and
  /// [loadNextPage]'s guardian branch. A student whose resolved classroom code
  /// is empty contributes an empty page (mirrors the View's `cc.isEmpty` guard)
  /// rather than erroring. [isRange] selects `getRangeActivityFeed` (using
  /// `query.dateStr`/`query.endDateStr!` as start/end) vs. `getDailyActivityFeed`
  /// (using `query.dateStr` as the single date). `approvalStatuses` is passed
  /// on EVERY call, including pagination — this mirrors the View's guardian
  /// pagination functions (`_loadNextParentHomeDailyFeedPage`/
  /// `_loadNextParentHomeRangeFeedPage`), which, unlike the staff path,
  /// recompute and pass `approvalStatuses` on every page, not just the first.
  Future<ActivityFeedPage> _fetchGuardianFeedPage(
    Map<String, String> studentClassroomByCode,
    ActivityFeedQuery query, {
    required bool isRange,
    required int page,
  }) async {
    final pages = await Future.wait(
      studentClassroomByCode.entries.map((entry) async {
        final cc = entry.value.trim();
        if (cc.isEmpty) {
          return const ActivityFeedPage(
            content: [],
            totalElements: 0,
            totalPages: 0,
            pageNumber: 0,
            last: true,
          );
        }
        return isRange
            ? _dataSource.getRangeActivityFeed(
                classroomCode: cc,
                startDate: query.dateStr,
                endDate: query.endDateStr!,
                studentCode: entry.key,
                activityTypeCodes: query.typeCodes,
                approvalStatuses: query.approvalStatuses,
                guardianPersona: true,
                page: page,
                size: query.pageSize,
              )
            : _dataSource.getDailyActivityFeed(
                classroomCode: cc,
                date: query.dateStr,
                studentCode: entry.key,
                activityTypeCodes: query.typeCodes,
                approvalStatuses: query.approvalStatuses,
                guardianPersona: true,
                page: page,
                size: query.pageSize,
              );
      }),
    );
    return mergeActivityFeedPages(pages);
  }

  // --------------------------------------------------------------------------
  // Tri-source attendance/absent sub-fetch (verbatim conditional structure)
  // --------------------------------------------------------------------------

  /// Fetches the optional attendance/absent sub-pages for a daily or range
  /// load. [endDateStr] is `null` for a daily load (byte-for-byte identical
  /// to the pre-range behavior) or the range end date for a range load — when
  /// non-null it is threaded through as `toAbsenceDate`/`toAttendanceDate`
  /// alongside `query.dateStr` as the start, mirroring
  /// `activity_custom_tab.dart`'s `_loadRangeFeed`/`_loadNextRangeFeedPage`
  /// (which also keeps passing `attendanceDate: startStr` alongside
  /// `fromAttendanceDate`/`toAttendanceDate` — preserved verbatim here, not
  /// "cleaned up", since the backend may need all three).
  ///
  /// [studentCodesOverride], when non-null, switches this into GUARDIAN mode:
  /// every `studentCodes:` argument uses [studentCodesOverride] instead of
  /// `query.studentCodes`, and `classroomCodes` is OMITTED entirely (passed as
  /// `null`, equivalent to not passing the argument) rather than falling back
  /// to `[query.classroomCode]` — mirroring `_loadParentHomeDailyFeed`/
  /// `_loadParentHomeRangeFeed`, which scope these sub-fetches purely by the
  /// guardian's student codes (a guardian's children can be in different
  /// classrooms, so no single `classroomCode` is correct here). When `null`
  /// (the default), behavior is byte-for-byte identical to before this
  /// parameter existed — every existing call site is unaffected.
  Future<_AttendanceSubPages> _fetchAttendanceSubPages(
    ActivityFeedQuery query, {
    required int page,
    String? endDateStr,
    List<String>? studentCodesOverride,
  }) async {
    if (!query.includeAttendance) return const _AttendanceSubPages();

    final isGuardianFanOut = studentCodesOverride != null;
    final classroomCodes = query.classroomCodes;
    final ccForAttendance = classroomCodes.isNotEmpty
        ? classroomCodes
        : <String>[query.classroomCode];
    final effectiveClassroomCodes = isGuardianFanOut ? null : ccForAttendance;
    final effectiveStudentCodes = studentCodesOverride ?? query.studentCodes;
    final toAbsenceDate = endDateStr ?? query.dateStr;

    // Real server-side tag filter (the attendance/absent endpoints accept
    // `tagCodes` directly — confirmed against the actual API contract, unlike
    // the activity-feed endpoint below, which has no such parameter and stays
    // on the client-side `_withTagFilterOnly` filter for that reason alone).
    final effectiveTagCodes = query.tagCodes.isEmpty ? null : query.tagCodes;

    if (query.isMarkedAbsentEvent) {
      final absent = await _dataSource.getStudentAbsentRecordsActivity(
        fromAbsenceDate: query.dateStr,
        toAbsenceDate: toAbsenceDate,
        classroomCodes: effectiveClassroomCodes,
        studentCodes: effectiveStudentCodes,
        tagCodes: effectiveTagCodes,
        page: page,
        size: query.pageSize,
      );
      return _AttendanceSubPages(absent: absent);
    }

    if (query.attendanceEvent == null) {
      final dailyAbsent = await Future.wait([
        _dataSource.getStudentAttendanceDaily(
          attendanceDate: query.dateStr,
          fromAttendanceDate: endDateStr != null ? query.dateStr : null,
          toAttendanceDate: endDateStr,
          classroomCodes: effectiveClassroomCodes,
          studentCodes: effectiveStudentCodes,
          tagCodes: effectiveTagCodes,
          signInAtFilter: null,
          signOutAtFilter: null,
          page: page,
          size: query.pageSize,
        ),
        _dataSource.getStudentAbsentRecordsActivity(
          fromAbsenceDate: query.dateStr,
          toAbsenceDate: toAbsenceDate,
          classroomCodes: effectiveClassroomCodes,
          studentCodes: effectiveStudentCodes,
          tagCodes: effectiveTagCodes,
          page: page,
          size: query.pageSize,
        ),
      ]);
      return _AttendanceSubPages(
        attendance: dailyAbsent[0] as StudentAttendanceDailyPage,
        absent: dailyAbsent[1] as StudentAttendanceAbsentFormPage,
      );
    }

    final attendance = await _dataSource.getStudentAttendanceDaily(
      attendanceDate: query.dateStr,
      fromAttendanceDate: endDateStr != null ? query.dateStr : null,
      toAttendanceDate: endDateStr,
      classroomCodes: effectiveClassroomCodes,
      studentCodes: effectiveStudentCodes,
      tagCodes: effectiveTagCodes,
      signInAtFilter: query.signInAtFilter,
      signOutAtFilter: query.signOutAtFilter,
      page: page,
      size: query.pageSize,
    );
    return _AttendanceSubPages(attendance: attendance);
  }

  // --------------------------------------------------------------------------
  // Staleness guard (mirrors _isStaleFeedResponse)
  // --------------------------------------------------------------------------

  Future<String> _readLiveSchool() async {
    _liveSchoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    return _liveSchoolCode!;
  }

  Future<void> _refreshLiveSchool() => _readLiveSchool();

  /// A response captured at [gen] under [schoolAtStart] must be discarded when
  /// the cubit closed, a newer load superseded it, or the live school changed
  /// mid-flight. Callers must return without emitting when this is true.
  bool _isStale(int gen, String? schoolAtStart) =>
      isClosed || gen != _generation || _liveSchoolCode != schoolAtStart;

  // --------------------------------------------------------------------------
  // Priming (routed through the injected data source, as the View does)
  // --------------------------------------------------------------------------

  Future<void> _primeStaffDisplayNames(Iterable<ActivityFeedRow> rows) async {
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
    final resolved = await _dataSource.resolveStaffDisplayNames(missingCodes);
    _staffDisplayNameByCode.addAll(resolved);
  }

  // --------------------------------------------------------------------------
  // Mappers (moved verbatim; View filter reads swapped for query/presentation)
  // --------------------------------------------------------------------------

  /// Tag-only client filter for attendance/absent-derived items. Gated on
  /// `query.tagCodes` (was `_filterTags`); membership uses the resolved
  /// `presentation.tagStudentCodes` (was `_studentCodesForTagFilter`).
  List<ActivityItem> _withTagFilterOnly(List<ActivityItem> items) {
    if (_query?.tagCodes.isEmpty ?? true) return items;
    final allowed = _presentation.tagStudentCodes;
    return items
        .where((a) => a.studentCode != null && allowed.contains(a.studentCode))
        .toList();
  }

  List<ActivityItem> _mapDailyFeedPageToItems(
    ActivityFeedPage page,
    ActivityFeedQuery query,
  ) {
    final raw = page.content
        .map(
          (row) => activityItemFromFeedRow(
            row,
            // Guardian feed should not fall back to the guardian display name
            // as "created by" when the API returns system/staff placeholders.
            viewerDisplayName: query.guardianPersona
                ? null
                : _presentation.viewerStaffDisplayName,
            schoolIana: _presentation.schoolIana,
            staffDisplayNameByCode: _staffDisplayNameByCode,
            activityTypeOptionCodeToLabel: activityFeedOptionLabelsForType(
              row.activityTypeCode,
            ),
          ),
        )
        .toList();
    // NOTE: the View additionally runs `_withClientFilters` here (multi-select
    // activity-type narrowing + approval-status re-filter). Those depend on
    // View-only label/settings state (`_filterActivityTypes`,
    // `_classroomActivitySettings`) that is NOT part of the resolved query — the
    // server already scopes type/approval via query.typeCodes/approvalStatuses,
    // so only the tag filter is applied here. See RETURN notes.
    return _withTagFilterOnly(raw);
  }

  List<ActivityItem> _mapAttendanceDailyPageToItems(
    StudentAttendanceDailyPage page,
    ActivityFeedQuery query,
  ) {
    if (!query.includeAttendance) return const <ActivityItem>[];
    final eventFilter = query.attendanceEvent;
    final selectedClassroomCode = query.classroomCode;
    final out = <ActivityItem>[];
    for (final row in page.items) {
      // Per-row day reconstruction — ported verbatim from
      // `activity_custom_tab.dart`'s `_itemsFromAttendancePage`. Required for
      // range queries, where a single page's rows can span multiple calendar
      // days: `row.attendanceDate` first, then `row.signedInAt`/`signedOutAt`
      // converted from a school-wall-clock instant, falling back to
      // `_dayForQuery(query)` only on absence/parse failure. Safe for daily
      // queries too since every row's own day already equals `_dayForQuery`.
      DateTime day;
      try {
        final attendanceDateSrc = (row.attendanceDate ?? '').trim();
        if (attendanceDateSrc.isNotEmpty) {
          day = DateTime.parse(attendanceDateSrc);
        } else {
          final src = (row.signedInAt ?? row.signedOutAt ?? '').trim();
          day = src.isEmpty
              ? _dayForQuery(query)
              : SchoolZoneDateTime.dateTimeFromInstantInSchool(
                  DateTime.parse(src),
                  _presentation.schoolIana,
                );
        }
      } catch (_) {
        day = _dayForQuery(query);
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

          final selectedCode = selectedClassroomCode.trim();
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
                  ? _presentation.viewerStaffDisplayName
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
        // Backend may return the final sign-out time on the last transfer row
        // (`isTransfer: true`). Render sign-out from transfer rows too.
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
                  ? _presentation.viewerStaffDisplayName
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
                ? _presentation.viewerStaffDisplayName
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
                ? _presentation.viewerStaffDisplayName
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
    // Intentionally NOT sorted here — the caller merges all three sources into
    // one list first and sorts exactly once over the full set.
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
            ? (_presentation.selectedDate ?? AppTime.now())
            : DateTime.parse(src);
      } catch (_) {
        recordDay = _presentation.selectedDate ?? AppTime.now();
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
              ? _presentation.viewerStaffDisplayName
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
    // Intentionally NOT sorted here (see attendance mapper note).
    return out;
  }

  // --------------------------------------------------------------------------
  // Sort comparator + helpers (moved verbatim)
  // --------------------------------------------------------------------------

  int _compareActivityItemsByTimeDesc(ActivityItem a, ActivityItem b) {
    final byTime = _activityItemSortDateTime(
      b,
    ).compareTo(_activityItemSortDateTime(a));
    if (byTime != 0) return byTime;
    return b.name.compareTo(a.name);
  }

  DateTime _activityItemSortDateTime(ActivityItem item) {
    final iso = (item.activityDateIso ?? '').trim();
    if (iso.isNotEmpty) {
      // Silent by design, not an oversight: this comparator runs on every
      // pairwise sort comparison, so logging a parse miss here would spam
      // the log on every malformed row instead of once. Falls through to
      // the display-string parse below, then the epoch fallback.
      try {
        return DateTime.parse(iso);
      } catch (_) {}
    }
    final parsedDisplay = _tryParseDisplayDateTime(item.date, item.time);
    if (parsedDisplay != null) return parsedDisplay;

    final date = item.date.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (date.isNotEmpty) {
      // Same hot-path rationale as above — silent on purpose.
      try {
        return DateFormat('MMMM d, yyyy').parseStrict(date);
      } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
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

  DateTime _dayForQuery(ActivityFeedQuery query) {
    if (_presentation.selectedDate != null) return _presentation.selectedDate!;
    try {
      final s = query.dateStr.trim();
      if (s.isNotEmpty) return DateTime.parse(s);
    } catch (e) {
      AppLogger.d('_dayForQuery: unparsable dateStr "${query.dateStr}", defaulting to now: $e');
    }
    return AppTime.now();
  }

  String _displayClassroomName({String? classroomCode, String? classroomName}) {
    final n = (classroomName ?? '').trim();
    if (n.isNotEmpty && !n.startsWith('CLS_')) return n;
    final c = (classroomCode ?? '').trim();
    if (c.isEmpty) return n;
    return _presentation.classroomNameByCode[c] ?? c;
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

  String _wallClockToUtcIso(DateTime schoolWallClock) {
    return SchoolZoneDateTime.utcFromSchoolWallClockDateTime(
      schoolWallClock,
      _presentation.schoolIana,
    ).toIso8601String();
  }
}

/// The two optional attendance sub-pages a daily load may carry.
class _AttendanceSubPages {
  const _AttendanceSubPages({this.attendance, this.absent});
  final StudentAttendanceDailyPage? attendance;
  final StudentAttendanceAbsentFormPage? absent;
}
