import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/pages/attendance_range_page.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/loading_more_row.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/range_row.dart';

import 'attendance_test_doubles.dart';
import 'attendance_widget_harness.dart';

void main() {
  late FakeAttendanceSource source;

  final range = DateRange(
    from: DateTime(DemoData.today.year, DemoData.today.month),
    to: DemoData.today,
  );

  Widget page() => AttendanceRangePage(range: range, today: DemoData.today);

  setUp(() async {
    source = FakeAttendanceSource();
    await registerAttendanceWith(source);
  });

  group('AttendanceRangePage · 4f', () {
    testWidgets('draws the range, its rows and the next page marker', (
      tester,
    ) async {
      await pumpScreen(tester, page());

      expect(find.text('1 Aug – 20 Aug'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
      expect(find.byType(RangeRow), findsNWidgets(2));
      expect(find.text('Dana Whitfield'), findsOneWidget);
      expect(find.byType(LoadingMoreRow), findsOneWidget);
    });

    testWidgets('a row opens onto the two totals and the View key', (
      tester,
    ) async {
      await pumpScreen(tester, page());
      await tester.tap(find.text('Dana Whitfield'));
      await settle(tester);

      expect(find.text('Attended Time'), findsOneWidget);
      expect(find.text('128 Hrs 40 Mins'), findsOneWidget);
      expect(find.text('Attended Days'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('an empty range says so and offers Clear all', (tester) async {
      source.range = const RangePage(
        entries: <RangeEntry>[],
        page: 0,
        totalElements: 0,
        hasMore: false,
      );
      await pumpScreen(tester, page());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Nothing attended in this range'), findsOneWidget);
    });

    testWidgets('a failed range is a Try again', (tester) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, page());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(RangeRow), findsNothing);
    });
  });
}
