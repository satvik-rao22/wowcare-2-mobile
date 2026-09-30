import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/view_model/events_cubit.dart';

Holiday _h({
  required String code,
  required DateTime start,
  DateTime? end,
  required HolidayType type,
  HolidayStatus? status,
}) => Holiday(
  code: code,
  name: code,
  startDate: start,
  endDate: end ?? start,
  type: type,
  status: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // A representative mix, deliberately unsorted, spanning two years.
  final schoolLate = _h(
    code: 'SCH-DEC',
    start: DateTime(2026, 12, 20),
    end: DateTime(2026, 12, 24),
    type: HolidayType.school,
  );
  final schoolEarly = _h(
    code: 'SCH-MAR',
    start: DateTime(2026, 3, 16),
    type: HolidayType.school,
  );
  final fedPending = _h(
    code: 'FED-PENDING',
    start: DateTime(2026, 10, 12),
    type: HolidayType.federal,
    status: HolidayStatus.pending,
  );
  final fedConsidered = _h(
    code: 'FED-OK',
    start: DateTime(2026, 7, 4),
    type: HolidayType.federal,
    status: HolidayStatus.considered,
  );
  final fedRejected = _h(
    code: 'FED-NO',
    start: DateTime(2026, 6, 14),
    type: HolidayType.federal,
    status: HolidayStatus.rejected,
  );
  final nextYearSchool = _h(
    code: 'SCH-2027',
    start: DateTime(2027, 1, 5),
    type: HolidayType.school,
  );

  EventsState stateFor(List<Holiday> holidays, {int year = 2026}) =>
      EventsState.initial().copyWith(
        holidays: holidays,
        selectedYear: year,
        isLoading: false,
      );

  final state = stateFor([
    schoolLate,
    fedPending,
    nextYearSchool,
    fedConsidered,
    schoolEarly,
    fedRejected,
  ]);

  test('schoolHolidays returns only in-year school holidays, sorted', () {
    expect(state.schoolHolidays.map((h) => h.code).toList(), [
      'SCH-MAR',
      'SCH-DEC',
    ]);
  });

  test('activeHolidays = school + considered federal, sorted by start', () {
    expect(state.activeHolidays.map((h) => h.code).toList(), [
      'SCH-MAR', // Mar 16
      'FED-OK', // Jul 4
      'SCH-DEC', // Dec 20
    ]);
  });

  test('pendingFederalHolidays isolates pending federal', () {
    expect(state.pendingFederalHolidays.map((h) => h.code).toList(), [
      'FED-PENDING',
    ]);
  });

  test('rejectedFederalHolidays isolates rejected federal', () {
    expect(state.rejectedFederalHolidays.map((h) => h.code).toList(), [
      'FED-NO',
    ]);
  });

  test('year filter excludes holidays from other years', () {
    expect(
      state.schoolHolidays.any((h) => h.code == 'SCH-2027'),
      isFalse,
    );
    // Switching the selected year surfaces it instead.
    final next = stateFor([nextYearSchool, schoolEarly], year: 2027);
    expect(next.schoolHolidays.map((h) => h.code).toList(), ['SCH-2027']);
  });

  group('calendar predicates', () {
    test('holidaysOn returns observed holidays covering the day', () {
      // Dec 22 is inside the school winter break (observed).
      expect(
        state.holidaysOn(DateTime(2026, 12, 22)).map((h) => h.code).toList(),
        ['SCH-DEC'],
      );
      // Jul 4 is a considered federal holiday (observed).
      expect(
        state.holidaysOn(DateTime(2026, 7, 4)).map((h) => h.code).toList(),
        ['FED-OK'],
      );
    });

    test('holidaysOn ignores non-observed federal holidays', () {
      // Oct 12 pending and Jun 14 rejected are NOT observed.
      expect(state.holidaysOn(DateTime(2026, 10, 12)), isEmpty);
      expect(state.holidaysOn(DateTime(2026, 6, 14)), isEmpty);
    });

    test('isHoliday reflects observance', () {
      expect(state.isHoliday(DateTime(2026, 12, 22)), isTrue);
      expect(state.isHoliday(DateTime(2026, 10, 12)), isFalse); // pending
      expect(state.isHoliday(DateTime(2026, 8, 1)), isFalse); // nothing
    });
  });

  test('holidayByCode finds a holiday or returns null', () {
    expect(state.holidayByCode('FED-OK'), fedConsidered);
    expect(state.holidayByCode('NOPE'), isNull);
  });
}
