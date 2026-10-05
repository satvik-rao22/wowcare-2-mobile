import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_themes.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/model/billing_quick_range.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';

/// Owner stand-in: holds the range the way the Student(s) / Transactions tabs
/// do (in their cubit) and pushes it back into the selector on change.
class _Host extends StatefulWidget {
  const _Host({
    required this.start,
    required this.end,
    this.onRangeChanged,
    this.onClear,
    this.withClear = true,
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTime? start, DateTime? end)? onRangeChanged;
  final VoidCallback? onClear;
  final bool withClear;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late DateTime? _start = widget.start;
  late DateTime? _end = widget.end;

  void push(DateTime? start, DateTime? end) => setState(() {
    _start = start;
    _end = end;
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: AccountingDateRangeSelector(
          initialStartDate: _start,
          initialEndDate: _end,
          onRangeChanged: (s, e) {
            widget.onRangeChanged?.call(s, e);
            push(s, e);
          },
          onClear: widget.withClear ? (widget.onClear ?? () {}) : null,
        ),
      ),
    );
  }
}

String _short(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

String _label(DateTime s, DateTime e) => '${_short(s)} - ${_short(e)}';

void main() {
  setUp(() {
    // Phone width so the row layout is the one users see.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> pump(WidgetTester tester, Widget w) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();
  }

  final start = DateTime(2026, 9, 1);
  final end = DateTime(2026, 9, 30);

  testWidgets('shows the owner range, the Select Range hint and Clear All', (
    tester,
  ) async {
    await pump(tester, _Host(start: start, end: end));
    expect(find.text(_label(start, end)), findsOneWidget);
    expect(find.text(BillingStrings.selectRange), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clear All is hidden when the owner passes no onClear', (
    tester,
  ) async {
    await pump(tester, _Host(start: start, end: end, withClear: false));
    expect(find.text('Clear All'), findsNothing);
  });

  testWidgets('a quick range writes its period into the calendar field', (
    tester,
  ) async {
    DateTime? gotStart;
    DateTime? gotEnd;
    await pump(
      tester,
      _Host(
        start: start,
        end: end,
        onRangeChanged: (s, e) {
          gotStart = s;
          gotEnd = e;
        },
      ),
    );

    await tester.tap(find.text(BillingStrings.selectRange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BillingStrings.thisYear).last);
    await tester.pumpAndSettle();

    final b = BillingQuickRange.thisYear.bounds;
    expect(gotStart, b.start);
    expect(gotEnd, b.end);
    // Calendar field now reads the preset's period; dropdown shows the pick.
    expect(find.text(_label(b.start, b.end)), findsOneWidget);
    expect(find.text(BillingStrings.thisYear), findsOneWidget);
    expect(find.text(BillingStrings.selectRange), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a calendar-driven range that leaves the preset resets it', (
    tester,
  ) async {
    await pump(tester, _Host(start: start, end: end));
    await tester.tap(find.text(BillingStrings.selectRange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BillingStrings.thisMonth).last);
    await tester.pumpAndSettle();
    expect(find.text(BillingStrings.thisMonth), findsOneWidget);

    // The owner applies a custom range (what a calendar pick does).
    final host = tester.state<_HostState>(find.byType(_Host));
    final cs = DateTime(2026, 9, 3);
    final ce = DateTime(2026, 9, 10, 23, 59, 59);
    host.push(cs, ce);
    await tester.pumpAndSettle();

    expect(find.text(_label(cs, ce)), findsOneWidget);
    expect(find.text(BillingStrings.selectRange), findsOneWidget);
    expect(find.text(BillingStrings.thisMonth), findsNothing);
  });

  testWidgets('a quick range survives the owner echoing the same days back', (
    tester,
  ) async {
    await pump(tester, _Host(start: start, end: end));
    await tester.tap(find.text(BillingStrings.selectRange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BillingStrings.thisWeek).last);
    await tester.pumpAndSettle();

    final b = BillingQuickRange.thisWeek.bounds;
    final host = tester.state<_HostState>(find.byType(_Host));
    host.push(
      DateTime(b.start.year, b.start.month, b.start.day),
      DateTime(b.end.year, b.end.month, b.end.day, 23, 59, 59),
    );
    await tester.pumpAndSettle();
    expect(find.text(BillingStrings.thisWeek), findsOneWidget);
  });

  testWidgets('Clear All notifies the owner and resets the dropdown', (
    tester,
  ) async {
    var cleared = 0;
    await pump(tester, _Host(start: start, end: end, onClear: () => cleared++));
    await tester.tap(find.text(BillingStrings.selectRange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BillingStrings.thisYear).last);
    await tester.pumpAndSettle();
    expect(find.text(BillingStrings.thisYear), findsOneWidget);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(cleared, 1);
    // Even though this owner did not push new dates, the preset is gone.
    expect(find.text(BillingStrings.selectRange), findsOneWidget);
    expect(find.text(BillingStrings.thisYear), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
