import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart'
    as af;
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_data_source.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_query.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

ActivityFeedRow _feedRow(
  String activityCode,
  String studentCode, {
  required String iso,
}) =>
    ActivityFeedRow(
      activityCode: activityCode,
      studentCode: studentCode,
      classroomCode: 'CLS_1',
      activityTypeCode: 'AT_NOTE',
      // 'Notes' maps to the 'Notes' UI label (NOT 'Learning'), so option-label
      // priming is a no-op and never touches the serviceLocator.
      activityTypeName: 'Notes',
      activityDateIso: iso,
      description: 'desc',
      studentFirstName: 'Stud',
      studentLastName: studentCode,
      createdBy: 'Teacher',
      parameterValues: const <Map<String, dynamic>>[],
      attachments: const <Map<String, dynamic>>[],
      students: <Map<String, String>>[
        {'name': 'Stud $studentCode', 'studentCode': studentCode},
      ],
    );

ActivityFeedPage _feedPage(
  List<ActivityFeedRow> rows, {
  required bool last,
  int pageNumber = 0,
}) =>
    ActivityFeedPage(
      content: rows,
      totalElements: rows.length,
      totalPages: last ? pageNumber + 1 : pageNumber + 2,
      pageNumber: pageNumber,
      last: last,
    );

StudentAttendanceDailyItem _attItem(String studentCode, {int hour = 8}) =>
    StudentAttendanceDailyItem(
      studentCode: studentCode,
      studentName: 'Att $studentCode',
      isExpectedToday: true,
      classroomName: 'Room 1',
      classroomCode: 'CLS_1',
      tagCodes: const <String>[],
      tagNames: const <String>[],
      signedInAt: '2026-08-27T0$hour:00:00Z',
      signedInTime: StudentAttendanceTime(hour: hour, minute: 0),
      signedInBy: 'Teacher',
    );

StudentAttendanceDailyPage _attPage(
  List<StudentAttendanceDailyItem> items, {
  bool hasMore = false,
  int page = 0,
}) =>
    StudentAttendanceDailyPage(
      items: items,
      page: page,
      size: 10,
      totalPages: 1,
      totalElements: items.length,
      hasMore: hasMore,
    );

af.StudentAttendanceAbsentFormItem _absItem(String studentCode, {int hour = 9}) =>
    af.StudentAttendanceAbsentFormItem(
      studentCode: studentCode,
      studentName: 'Abs $studentCode',
      classroomCode: 'CLS_1',
      classroomName: 'Room 1',
      absenceDate: '2026-08-27',
      markedAbsentTime: af.StudentAttendanceTime(hour: hour, minute: 0),
      markedAbsentByName: 'Teacher',
      absenceNote: 'sick',
    );

af.StudentAttendanceAbsentFormPage _absPage(
  List<af.StudentAttendanceAbsentFormItem> items, {
  bool hasMore = false,
  int page = 0,
}) =>
    af.StudentAttendanceAbsentFormPage(
      items: items,
      page: page,
      size: 10,
      totalPages: 1,
      totalElements: items.length,
      hasMore: hasMore,
    );

ActivityFeedQuery _query({
  bool includeAttendance = true,
  String? attendanceEvent,
  bool isMarkedAbsent = false,
  int pageSize = 10,
}) =>
    ActivityFeedQuery(
      organizationCode: 'ORG',
      schoolCode: 'SCH-A',
      classroomCode: 'CLS_1',
      classroomCodes: const <String>['CLS_1'],
      dateStr: '2026-08-27',
      includeAttendance: includeAttendance,
      attendanceEvent: attendanceEvent,
      isMarkedAbsentEvent: isMarkedAbsent,
      pageSize: pageSize,
    );

// ---------------------------------------------------------------------------
// Fakes (hand-written, no mocktail)
// ---------------------------------------------------------------------------

class _FakeFeedDataSource implements ActivityFeedDataSource {
  final List<Object> dailyQueue = <Object>[];
  final List<Object> attendanceQueue = <Object>[];
  final List<Object> absentQueue = <Object>[];

  int dailyCalls = 0;
  int attendanceCalls = 0;
  int absentCalls = 0;

  @override
  Future<ActivityFeedPage> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  }) {
    dailyCalls++;
    final r =
        dailyQueue.isNotEmpty ? dailyQueue.removeAt(0) : _feedPage(const [], last: true);
    if (r is Completer<ActivityFeedPage>) return r.future;
    return Future<ActivityFeedPage>.value(r as ActivityFeedPage);
  }

  @override
  Future<ActivityFeedPage> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  }) {
    dailyCalls++;
    final r =
        dailyQueue.isNotEmpty ? dailyQueue.removeAt(0) : _feedPage(const [], last: true);
    if (r is Completer<ActivityFeedPage>) return r.future;
    return Future<ActivityFeedPage>.value(r as ActivityFeedPage);
  }

  @override
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    attendanceCalls++;
    final r = attendanceQueue.isNotEmpty
        ? attendanceQueue.removeAt(0)
        : _attPage(const []);
    if (r is Completer<StudentAttendanceDailyPage>) return r.future;
    return Future<StudentAttendanceDailyPage>.value(
      r as StudentAttendanceDailyPage,
    );
  }

  @override
  Future<af.StudentAttendanceAbsentFormPage> getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    absentCalls++;
    final r =
        absentQueue.isNotEmpty ? absentQueue.removeAt(0) : _absPage(const []);
    if (r is Completer<af.StudentAttendanceAbsentFormPage>) return r.future;
    return Future<af.StudentAttendanceAbsentFormPage>.value(
      r as af.StudentAttendanceAbsentFormPage,
    );
  }

  @override
  Future<Map<String, String>> resolveStaffDisplayNames(
    Iterable<String> staffCodes,
  ) async =>
      const <String, String>{};
}

class _FakeStorage implements StorageService {
  _FakeStorage(this.schoolCode);
  String schoolCode;

  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? schoolCode : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

// A couple of microtask/event-loop turns so a parked async load can advance
// past its `await`s (storage read + fetch dispatch) before the test proceeds.
Future<void> _pump([int times = 3]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() {
    // Attendance/absent rows convert school wall-clock → UTC via the timezone
    // DB; load it once for the whole suite.
    tzdata.initializeTimeZones();
  });

  late _FakeFeedDataSource ds;
  late _FakeStorage storage;
  late ActivityFeedCubit cubit;

  setUp(() {
    ds = _FakeFeedDataSource();
    storage = _FakeStorage('SCH-A');
    cubit = ActivityFeedCubit(
      dataSource: ds,
      storageService: storage,
      presentation: const ActivityFeedPresentation(schoolIana: 'UTC'),
    );
  });

  tearDown(() => cubit.close());

  test('1. loadDaily happy path: tri-source merge, sorted desc, hasMore false',
      () async {
    ds.dailyQueue.add(
      _feedPage([_feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z')], last: true),
    );
    ds.attendanceQueue.add(_attPage([_attItem('S2', hour: 8)]));
    ds.absentQueue.add(_absPage([_absItem('S3', hour: 9)]));

    await cubit.loadDaily(_query());

    // All three sources present, sorted by time DESC: 10:00 > 09:00 > 08:00.
    expect(
      cubit.state.items.map((i) => i.name).toList(),
      ['Notes', 'Marked Absent', 'Sign-in'],
    );
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.nextPage, 0);
    expect(cubit.state.isLoading, isFalse);
    // includeAttendance + null event => both attendance and absent fetched.
    expect(ds.attendanceCalls, 1);
    expect(ds.absentCalls, 1);
  });

  test(
      '2. a slow older loadDaily completing after a newer refresh is DISCARDED '
      '(stale generation)', () async {
    // Baseline load.
    ds.dailyQueue.add(
      _feedPage([_feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z')], last: true),
    );
    await cubit.loadDaily(_query());
    expect(cubit.state.items.map((i) => i.activityCode), ['A1']);

    // Start a slow (older) load, gated on its daily page.
    final gate = Completer<ActivityFeedPage>();
    ds.dailyQueue.add(gate);
    final slow = cubit.loadDaily(_query());
    await _pump();

    // A newer refresh supersedes it (bumps generation) and completes first.
    ds.dailyQueue.add(
      _feedPage([_feedRow('B2', 'S9', iso: '2026-08-27T11:00:00Z')], last: true),
    );
    await cubit.loadDaily(_query(), refresh: true);
    expect(cubit.state.items.map((i) => i.activityCode), ['B2']);

    // The stale response now returns — it must be dropped.
    gate.complete(
      _feedPage([_feedRow('OLD', 'S1', iso: '2026-08-27T09:00:00Z')], last: true),
    );
    await slow;

    expect(cubit.state.items.map((i) => i.activityCode), ['B2']);
  });

  test('3. school-switch: a response whose school-at-start != live is DISCARDED',
      () async {
    final gate = Completer<ActivityFeedPage>();
    ds.dailyQueue.add(gate);

    final future = cubit.loadDaily(_query()); // snapshot school = SCH-A
    await _pump();

    storage.schoolCode = 'SCH-B'; // live switch mid-flight
    gate.complete(
      _feedPage([_feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z')], last: true),
    );
    await future;

    expect(cubit.state.items, isEmpty);
  });

  test(
      '4. loadNextPage: single-flight no-op, appends page-1, dedupes overlap, '
      'advances nextPage', () async {
    // Page 0 with hasMore (last: false).
    ds.dailyQueue.add(
      _feedPage([_feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z')], last: false),
    );
    await cubit.loadDaily(_query());
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.nextPage, 1);
    expect(ds.dailyCalls, 1);

    // Gate page-1 so we can fire a concurrent second call.
    final gate = Completer<ActivityFeedPage>();
    ds.dailyQueue.add(gate);
    final f1 = cubit.loadNextPage();
    final f2 = cubit.loadNextPage(); // must be a no-op (single-flight)
    await f2;

    // Second call did not dispatch another daily fetch and did not mutate items.
    expect(cubit.state.items.map((i) => i.activityCode), ['A1']);
    await _pump();
    expect(ds.dailyCalls, 2); // page0 + page1 (from f1 only)

    // Page-1 overlaps A1 and adds A2.
    gate.complete(
      _feedPage([
        _feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z'),
        _feedRow('A2', 'S2', iso: '2026-08-27T09:00:00Z'),
      ], last: true),
    );
    await f1;

    expect(cubit.state.items.map((i) => i.activityCode), ['A1', 'A2']);
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.nextPage, 0);
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('5. loadNextPage superseded by a refresh (gen bumped) is DISCARDED',
      () async {
    ds.dailyQueue.add(
      _feedPage([_feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z')], last: false),
    );
    await cubit.loadDaily(_query());
    expect(cubit.state.nextPage, 1);

    final gate = Completer<ActivityFeedPage>();
    ds.dailyQueue.add(gate);
    final page = cubit.loadNextPage(); // captures current generation
    await _pump();

    // Refresh bumps the generation and completes first.
    ds.dailyQueue.add(
      _feedPage([_feedRow('R1', 'S1', iso: '2026-08-27T12:00:00Z')], last: true),
    );
    await cubit.loadDaily(_query(), refresh: true);
    expect(cubit.state.items.map((i) => i.activityCode), ['R1']);

    // The paginated page now arrives — it must not be appended.
    gate.complete(
      _feedPage([_feedRow('E', 'S2', iso: '2026-08-27T08:00:00Z')], last: true),
    );
    await page;

    expect(cubit.state.items.map((i) => i.activityCode), ['R1']);
    expect(cubit.state.items.map((i) => i.activityCode), isNot(contains('E')));
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('6. includeAttendance=false skips the attendance and absent calls',
      () async {
    ds.dailyQueue.add(
      _feedPage([_feedRow('A1', 'S1', iso: '2026-08-27T10:00:00Z')], last: true),
    );

    await cubit.loadDaily(_query(includeAttendance: false));

    expect(cubit.state.items.map((i) => i.activityCode), ['A1']);
    expect(ds.attendanceCalls, 0);
    expect(ds.absentCalls, 0);
  });
}
