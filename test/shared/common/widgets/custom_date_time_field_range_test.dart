import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_themes.dart';
import 'package:wowcare/core/utils/date_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

/// Pins the range-mode contract the attendance profiles rely on for Clear
/// All: an owner-held start/end pair is shown on first build and followed
/// when the owner changes it.
void main() {
  Widget host(DateTime start, DateTime end) => MaterialApp(
    theme: lightTheme,
    home: Scaffold(
      body: CustomDateTimeField(
        hasLabel: false,
        isRangePicker: true,
        // No DI in tests; the owner supplies the range.
        fetchInitialTime: false,
        initialDate: start,
        initialEndDate: end,
      ),
    ),
  );

  String label(DateTime s, DateTime e) =>
      '${DateUtilsNew.formatToReadableDate(s)} - '
      '${DateUtilsNew.formatToReadableDate(e)}';

  testWidgets('shows the owner range on first build', (tester) async {
    final s = DateTime(2026, 9, 1);
    final e = DateTime(2026, 9, 30);
    await tester.pumpWidget(host(s, e));
    await tester.pumpAndSettle();
    expect(find.text(label(s, e)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follows an owner-driven range change (Clear All)', (
    tester,
  ) async {
    final s1 = DateTime(2026, 9, 3);
    final e1 = DateTime(2026, 9, 10, 23, 59, 59);
    await tester.pumpWidget(host(s1, e1));
    await tester.pumpAndSettle();
    expect(find.text(label(s1, e1)), findsOneWidget);

    final s2 = DateTime(2026, 9, 1);
    final e2 = DateTime(2026, 9, 30);
    await tester.pumpWidget(host(s2, e2));
    await tester.pumpAndSettle();
    expect(find.text(label(s2, e2)), findsOneWidget);
    expect(find.text(label(s1, e1)), findsNothing);
  });
}
