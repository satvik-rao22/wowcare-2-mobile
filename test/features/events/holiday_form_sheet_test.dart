import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/usecases/create_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_events_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_holidays_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/respond_to_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/save_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/set_holiday_status_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_event_usecase.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_form_sheet.dart';

import 'helpers/event_test_fakes.dart';

void main() {
  late FakeEventRepository repo;
  late EventsCubit cubit;

  EventsCubit build() => EventsCubit(
    GetEventsUseCase(repo),
    CreateEventUseCase(repo),
    UpdateEventUseCase(repo),
    DeleteEventUseCase(repo),
    RespondToEventUseCase(repo),
    GetHolidaysUseCase(repo),
    CreateHolidayUseCase(repo),
    UpdateHolidayUseCase(repo),
    SetHolidayStatusUseCase(repo),
    DeleteHolidayUseCase(repo),
    FakeStorageService(),
  );

  setUp(() {
    repo = FakeEventRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  Future<void> openSheet(WidgetTester tester, {Holiday? holiday}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<EventsCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showHolidayFormSheet(context, holiday: holiday),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder addButton() => find.widgetWithText(ElevatedButton, 'Add Holiday');
  Finder nameField() => find.byType(TextField).first;

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<ElevatedButton>(addButton()).onPressed != null;

  testWidgets('opens in create mode with a disabled save until named', (
    tester,
  ) async {
    await openSheet(tester);

    // "Add Holiday" appears as both the sheet title and the save button.
    expect(find.text('Add Holiday'), findsNWidgets(2));
    expect(addButton(), findsOneWidget);
    // Name is required → save disabled initially.
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(nameField(), 'Teacher Workday');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);

    // Whitespace-only is treated as empty.
    await tester.enterText(nameField(), '    ');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('name is hard-capped at 80 characters', (tester) async {
    await openSheet(tester);

    await tester.enterText(nameField(), 'A' * 200);
    await tester.pump();

    final controller = tester.widget<TextField>(nameField()).controller!;
    expect(controller.text.length, 80);
  });

  testWidgets('description is hard-capped at 500 characters', (tester) async {
    await openSheet(tester);

    final descField = find.byType(TextField).last;
    await tester.enterText(descField, 'x' * 900);
    await tester.pump();

    final controller = tester.widget<TextField>(descField).controller!;
    expect(controller.text.length, 500);
  });

  testWidgets('surfaces the character limits via counters', (tester) async {
    await openSheet(tester);
    // Material renders the maxLength counter as "current/max".
    expect(find.text('0/80'), findsOneWidget);
    expect(find.text('0/500'), findsOneWidget);
  });

  testWidgets('offers Single Date and Date Range modes', (tester) async {
    await openSheet(tester);
    expect(find.text('Single Date'), findsOneWidget);
    expect(find.text('Date Range'), findsOneWidget);

    // Switching to range reveals the Starts/Ends tiles.
    await tester.tap(find.text('Date Range'));
    await tester.pump();
    expect(find.textContaining('Starts'), findsOneWidget);
    expect(find.textContaining('Ends'), findsOneWidget);
  });

  testWidgets('tapping Add Holiday creates via the cubit and closes', (
    tester,
  ) async {
    repo.nextCreate = (
      Holiday(
        code: 'SCH-NEW',
        name: 'Thanksgiving Break',
        startDate: DateTime(2026, 11, 26),
        endDate: DateTime(2026, 11, 26),
        type: HolidayType.school,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      'School holiday created successfully',
    );

    await openSheet(tester);
    await tester.enterText(nameField(), 'Thanksgiving Break');
    await tester.pump();

    await tester.tap(addButton());
    await tester.pumpAndSettle();

    expect(repo.lastCreateArgs!['name'], 'Thanksgiving Break');
    expect(repo.lastUpdateArgs, isNull);
    // Sheet dismissed on success.
    expect(addButton(), findsNothing);

    // Flush the transient success banner's delayed removal.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('edit mode pre-fills and routes to update', (tester) async {
    final existing = Holiday(
      code: 'SCH-7',
      name: 'Old Name',
      description: 'old desc',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 1),
      type: HolidayType.school,
      version: 4,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    repo.nextUpdate = (existing.copyWith(name: 'New Name'), 'updated');

    await openSheet(tester, holiday: existing);

    expect(find.text('Edit Holiday'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);
    // Existing values are pre-filled.
    expect(find.text('Old Name'), findsOneWidget);

    await tester.enterText(nameField(), 'New Name');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdateArgs!['code'], 'SCH-7');
    expect(repo.lastUpdateArgs!['version'], 4);
    expect(repo.lastUpdateArgs!['name'], 'New Name');
    expect(repo.lastCreateArgs, isNull);

    await tester.pump(const Duration(seconds: 3));
  });

  Holiday multiDayHoliday() => Holiday(
    code: 'SCH-8',
    name: 'Spring Break',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 3),
    type: HolidayType.school,
    version: 2,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  testWidgets('editing a multi-day holiday opens in Date Range mode', (
    tester,
  ) async {
    await openSheet(tester, holiday: multiDayHoliday());
    // Range mode is pre-selected, so the Starts/Ends tiles are visible.
    expect(find.textContaining('Starts'), findsOneWidget);
    expect(find.textContaining('Ends'), findsOneWidget);
  });

  testWidgets('switching back to Single Date collapses the end date on save', (
    tester,
  ) async {
    final existing = multiDayHoliday();
    repo.nextUpdate = (
      existing.copyWith(endDate: existing.startDate),
      'updated',
    );

    await openSheet(tester, holiday: existing);
    await tester.tap(find.text('Single Date'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdateArgs!['startDate'], DateTime(2026, 5, 1));
    expect(repo.lastUpdateArgs!['endDate'], DateTime(2026, 5, 1));

    await tester.pump(const Duration(seconds: 3));
  });

  // -------------------------------------------- manually typed dates

  // Single-date mode field order: name, date, description.
  Finder dateField() => find.byType(TextField).at(1);

  testWidgets('date field auto-formats typed digits into DD-MM-YYYY', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.enterText(dateField(), '25122026');
    await tester.pump();

    final controller = tester.widget<TextField>(dateField()).controller!;
    expect(controller.text, '25-12-2026');

    // Non-digit garbage is stripped at the keyboard.
    await tester.enterText(dateField(), '25/12.2026abc');
    await tester.pump();
    expect(controller.text, '25-12-2026');
  });

  testWidgets('a manually typed date is what gets saved', (tester) async {
    repo.nextCreate = (
      Holiday(
        code: 'SCH-NEW',
        name: 'Christmas',
        startDate: DateTime(2026, 12, 25),
        endDate: DateTime(2026, 12, 25),
        type: HolidayType.school,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      'School holiday created successfully',
    );

    await openSheet(tester);
    await tester.enterText(nameField(), 'Christmas');
    await tester.enterText(dateField(), '25-12-2026');
    await tester.pump();

    await tester.tap(addButton());
    await tester.pumpAndSettle();

    expect(repo.lastCreateArgs!['startDate'], DateTime(2026, 12, 25));
    expect(repo.lastCreateArgs!['endDate'], DateTime(2026, 12, 25));

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('incomplete or impossible typed dates disable save', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(nameField(), 'Holiday');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);

    // Partial input.
    await tester.enterText(dateField(), '2512');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
    expect(find.text('Use DD-MM-YYYY'), findsOneWidget);

    // Well-formed but not a real calendar date (Feb 31).
    await tester.enterText(dateField(), '31-02-2026');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);

    // Cleared entirely.
    await tester.enterText(dateField(), '');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
    expect(find.text('Required'), findsOneWidget);

    // Valid again.
    await tester.enterText(dateField(), '25-12-2026');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('a typed end date before the start disables save', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(nameField(), 'Break');
    await tester.tap(find.text('Date Range'));
    await tester.pump();

    // Range mode field order: name, starts, ends, description.
    final startField = find.byType(TextField).at(1);
    final endField = find.byType(TextField).at(2);

    await tester.enterText(startField, '10-05-2026');
    await tester.enterText(endField, '05-05-2026');
    await tester.pump();

    expect(saveEnabled(tester), isFalse);
    expect(find.text("Can't be before start date"), findsOneWidget);

    await tester.enterText(endField, '11-05-2026');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('trailing calendar icon opens the date picker', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined).first);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
