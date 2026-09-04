import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_schedule_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';

import 'harness.dart';

void main() {
  StaffScheduleCubit build({StaffLens lens = adminLens}) => StaffScheduleCubit(
    source: const PreviewStaffSource(),
    staffId: 'dana',
    lens: lens,
  );

  test('loads the week and names whose it is', () async {
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, StaffScheduleStatus.editing);
    expect(cubit.state.week, hasLength(5));
    expect(cubit.state.name, 'Dana');
    expect(cubit.state.workedMinutes, greaterThan(0));
  });

  test('refuses a staff member before it fetches anything', () async {
    final cubit = StaffScheduleCubit(
      source: const FailingStaffSource(),
      staffId: 'dana',
      lens: staffLens,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isDenied, isTrue);
    expect(cubit.state.week, isEmpty);
  });

  test('a refused viewer cannot save either', () async {
    final cubit = build(lens: staffLens);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.submit();

    expect(cubit.state.isSaved, isFalse);
  });

  test('a shift that ends before it starts is refused', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setShift(
      cubit.state.week.first.copyWith(startMinutes: 1020, endMinutes: 510),
    );
    await cubit.submit();

    expect(cubit.state.error, isNotNull);
    expect(cubit.state.isSaved, isFalse);
  });

  test('editing a day clears the error the last save raised', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();
    cubit.setShift(
      cubit.state.week.first.copyWith(startMinutes: 1020, endMinutes: 510),
    );
    await cubit.submit();
    expect(cubit.state.error, isNotNull);

    cubit.setShift(
      cubit.state.week.first.copyWith(startMinutes: 510, endMinutes: 1020),
    );

    expect(cubit.state.error, isNull);
  });

  test('copy to all days keeps each day on its own date', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();
    final dates = cubit.state.week.map((day) => day.date).toList();

    cubit.copyToAllDays(cubit.state.week.first.weekday);

    expect(cubit.state.week.map((day) => day.date).toList(), dates);
    expect(
      cubit.state.week.every(
        (day) => day.startMinutes == cubit.state.week.first.startMinutes,
      ),
      isTrue,
    );
  });

  test('a valid week saves', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.submit();

    expect(cubit.state.isSaved, isTrue);
  });
}
