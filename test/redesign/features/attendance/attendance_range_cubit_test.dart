import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_range_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

import 'attendance_test_doubles.dart';

void main() {
  late FakeAttendanceSource source;

  final range = DateRange(
    from: DateTime(DemoData.today.year, DemoData.today.month),
    to: DemoData.today,
  );

  AttendanceRangeCubit build() =>
      AttendanceRangeCubit(source: source, range: range);

  setUp(() => source = FakeAttendanceSource());

  group('AttendanceRangeCubit', () {
    test('loads the first page and the classroom options with it', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, RangeStatus.ready);
      expect(cubit.state.entries, hasLength(2));
      expect(cubit.state.totalElements, 3);
      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.classroomOptions, contains('Acorn'));
      await cubit.close();
    });

    test('the next page is appended, not swapped in', () async {
      final cubit = build();
      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.entries, hasLength(3));
      expect(cubit.state.entries.last.fullName, 'Tomas Berg');
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });

    test('there is no next page to ask for once it has run out', () async {
      final cubit = build();
      await cubit.load();
      await cubit.loadMore();
      final calls = source.loadRangeCalls;

      await cubit.loadMore();
      expect(source.loadRangeCalls, calls);
      await cubit.close();
    });

    test('a failed fetch is failed, and keeps nothing', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, RangeStatus.failed);
      expect(cubit.state.entries, isEmpty);
      await cubit.close();
    });

    test('Clear all drops the classrooms and the search together', () async {
      final cubit = build();
      await cubit.load();
      await cubit.setClassrooms(<String>{'Bluebell'});
      await cubit.search('rum');
      expect(cubit.state.isNarrowed, isTrue);

      await cubit.clearAll();
      expect(cubit.state.classrooms, isEmpty);
      expect(cubit.state.query, isEmpty);
      expect(cubit.state.isNarrowed, isFalse);
      await cubit.close();
    });

    test('changing the range refetches from the first page', () async {
      final cubit = build();
      await cubit.load();
      await cubit.loadMore();

      await cubit.setRange(
        DateRange(from: range.from, to: range.to.add(const Duration(days: 1))),
      );
      expect(cubit.state.page, 0);
      expect(cubit.state.entries, hasLength(2));
      await cubit.close();
    });

    test('an empty range is empty rather than failed', () async {
      source.range = const RangePage(
        entries: <RangeEntry>[],
        page: 0,
        totalElements: 0,
        hasMore: false,
      );
      final cubit = build();
      await cubit.load();

      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.isFailed, isFalse);
      await cubit.close();
    });

    test('only one row is open at a time', () async {
      final cubit = build();
      await cubit.load();

      cubit.toggleExpanded('dana');
      expect(cubit.state.expandedId, 'dana');
      cubit.toggleExpanded('dana');
      expect(cubit.state.expandedId, isNull);
      await cubit.close();
    });
  });
}
