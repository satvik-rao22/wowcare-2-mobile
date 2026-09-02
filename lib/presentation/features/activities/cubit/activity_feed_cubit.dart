import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart'
    hide StudentAttendanceTime;
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/presentation/features/activities/cubit/activity_feed_data_source.dart';
import 'package:wowcare/presentation/features/activities/cubit/activity_feed_query.dart';
import 'package:wowcare/presentation/features/activities/cubit/activity_feed_state.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';
// Reuses the top-level, presentation-agnostic feed helpers that live in the
// daily-tab library (importing them, per the migration plan — the View is NOT
// modified): the row→item mapper, the multi-student grouper, the stable-id
// deduper, and the option-label priming/lookup.
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart'
    show
        activityFeedOptionLabelsForType,
        activityItemFromFeedRow,
        dedupeActivitiesByStableId,
        groupMultiStudentFeedItems,
        primeActivityFeedOptionLabelsFromRows;

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
  })  : _dataSource = dataSource,
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
  Future<void> loadDaily(ActivityFeedQuery query, {bool refresh = false}) async {
    _query = query;

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

      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._withTagFilterOnly(
            _mapAttendanceDailyPageToItems(sub.attendance!, query),
          ),
        if (sub.absent != null)
          ..._withTagFilterOnly(_mapAbsentRecordsPageToItems(sub.absent!)),
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
      final hasMore = (sub.attendance?.hasMore ?? false) ||
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
          error: e.toString(),
        ),
      );
    }
  }

  /// Pagination — port of `_loadNextDailyFeedPage`. Single-flight on
  /// [ActivityFeedState.isLoadingMore]; captures the generation WITHOUT bumping;
  /// appends the next page, regroups + dedupes against the existing items,
  /// advances `nextPage`, updates `hasMore`; DISCARDS the response if it went
  /// stale (a refresh bumped the generation / school switched) before emitting.
  Future<void> loadNextPage() async {
    final query = _query;
    if (query == null) return;
    if (_loadingMore || !state.hasMore || state.isLoading) return;
    if (query.schoolCode.isEmpty ||
        query.classroomCode.isEmpty ||
        query.dateStr.isEmpty) {
      return;
    }

    _loadingMore = true;
    final feedGen = _generation; // capture WITHOUT bumping
    final schoolAtStart = await _readLiveSchool();
    final pageIndex = state.nextPage;
    if (!isClosed) emit(state.copyWith(isLoadingMore: true));

    try {
      final activityFeedPage = await _dataSource.getDailyActivityFeed(
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

      final sub = await _fetchAttendanceSubPages(query, page: pageIndex);

      await _primeStaffDisplayNames(activityFeedPage.content);
      await primeActivityFeedOptionLabelsFromRows(activityFeedPage.content);

      final items = <ActivityItem>[
        if (sub.attendance != null)
          ..._withTagFilterOnly(
            _mapAttendanceDailyPageToItems(sub.attendance!, query),
          ),
        if (sub.absent != null)
          ..._withTagFilterOnly(_mapAbsentRecordsPageToItems(sub.absent!)),
        ..._mapDailyFeedPageToItems(activityFeedPage, query),
      ]..sort(_compareActivityItemsByTimeDesc);

      await _refreshLiveSchool();
      if (_isStale(feedGen, schoolAtStart)) return;

      final merged = dedupeActivitiesByStableId(
        groupMultiStudentFeedItems(
          <ActivityItem>[...state.items, ...items],
          attendanceRequireDateAndTimeMatch: false,
        )..sort(_compareActivityItemsByTimeDesc),
      );
      final hasMore = (sub.attendance?.hasMore ?? false) ||
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
  // Tri-source attendance/absent sub-fetch (verbatim conditional structure)
  // --------------------------------------------------------------------------

  Future<_AttendanceSubPages> _fetchAttendanceSubPages(
    ActivityFeedQuery query, {
    required int page,
  }) async {
    if (!query.includeAttendance) return const _AttendanceSubPages();

    final classroomCodes = query.classroomCodes;
    final ccForAttendance = classroomCodes.isNotEmpty
        ? classroomCodes
        : <String>[query.classroomCode];

    if (query.isMarkedAbsentEvent) {
      final absent = await _dataSource.getStudentAbsentRecordsActivity(
        fromAbsenceDate: query.dateStr,
        toAbsenceDate: query.dateStr,
        classroomCodes: ccForAttendance,
        studentCodes: query.studentCodes,
        page: page,
        size: query.pageSize,
      );
      return _AttendanceSubPages(absent: absent);
    }

    if (query.attendanceEvent == null) {
      final dailyAbsent = await Future.wait([
        _dataSource.getStudentAttendanceDaily(
          attendanceDate: query.dateStr,
          classroomCodes: ccForAttendance,
          studentCodes: query.studentCodes,
          signInAtFilter: null,
          signOutAtFilter: null,
          page: page,
          size: query.pageSize,
        ),
        _dataSource.getStudentAbsentRecordsActivity(
          fromAbsenceDate: query.dateStr,
          toAbsenceDate: query.dateStr,
          classroomCodes: ccForAttendance,
          studentCodes: query.studentCodes,
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
      classroomCodes: ccForAttendance,
      studentCodes: query.studentCodes,
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
    _liveSchoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
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
        final pName =
            (p['parameterName'] ?? '').toString().trim().toLowerCase();
        if (pName != 'staff present') continue;
        final raw = (p['selectedOptionCode'] ??
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
        .where(
          (a) => a.studentCode != null && allowed.contains(a.studentCode),
        )
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
            viewerDisplayName:
                query.guardianPersona ? null : _presentation.viewerStaffDisplayName,
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
    final day = _dayForQuery(query);
    final selectedClassroomCode = query.classroomCode;
    final out = <ActivityItem>[];
    for (final row in page.items) {
      final studentName =
          row.studentName.trim().isEmpty ? 'Student' : row.studentName.trim();
      final studentCode = row.studentCode?.trim();
      final baseClassName = _displayClassroomName(
        classroomCode: row.classroomCode,
        classroomName: row.classroomName,
      );
      if (row.isTransfer == true) {
        if (eventFilter == null || eventFilter == 'Transfer') {
          final at = _attendanceClockToDateTime(row.transferTime, day) ??
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
          final bool viewingFromClassroom = selectedCode.isNotEmpty &&
              fromCode.isNotEmpty &&
              selectedCode == fromCode;
          final bool viewingToClassroom = selectedCode.isNotEmpty &&
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
        recordDay =
            src.isEmpty ? (_presentation.selectedDate ?? AppTime.now()) : DateTime.parse(src);
      } catch (_) {
        recordDay = _presentation.selectedDate ?? AppTime.now();
      }
      final at =
          _absentClockToDateTime(row.markedAbsentTime, recordDay) ?? recordDay;
      final studentName =
          row.studentName.trim().isEmpty ? 'Student' : row.studentName.trim();
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
    final byTime = _activityItemSortDateTime(b)
        .compareTo(_activityItemSortDateTime(a));
    if (byTime != 0) return byTime;
    return b.name.compareTo(a.name);
  }

  DateTime _activityItemSortDateTime(ActivityItem item) {
    final iso = (item.activityDateIso ?? '').trim();
    if (iso.isNotEmpty) {
      try {
        return DateTime.parse(iso);
      } catch (_) {}
    }
    final parsedDisplay = _tryParseDisplayDateTime(item.date, item.time);
    if (parsedDisplay != null) return parsedDisplay;

    final date = item.date.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (date.isNotEmpty) {
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
    } catch (_) {}
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
