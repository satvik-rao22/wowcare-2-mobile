import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_roster_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';

import 'harness.dart';

void main() {
  StaffRosterCubit build({
    StaffLens lens = adminLens,
    StaffSource source = const PreviewStaffSource(),
  }) => StaffRosterCubit(source: source, lens: lens);

  group('load', () {
    test('lands on a ready roster with the school figures', () async {
      final cubit = StaffRosterCubit(
        source: const PreviewStaffSource(),
        lens: adminLens,
      );
      addTearDown(cubit.close);

      expect(cubit.state.status, StaffRosterStatus.loading);
      await cubit.load();

      expect(cubit.state.status, StaffRosterStatus.ready);
      expect(cubit.state.roster.members, isNotEmpty);
      expect(cubit.state.roster.activeCount, greaterThan(0));
      expect(cubit.state.roster.upcomingCount, 1);
    });

    test('refuses a guardian before it fetches anything', () async {
      final cubit = StaffRosterCubit(
        source: const FailingStaffSource(),
        lens: guardianLens,
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, StaffRosterStatus.denied);
      expect(cubit.state.isDenied, isTrue);
    });

    test('fails outright when nothing has ever been reached', () async {
      final cubit = StaffRosterCubit(
        source: const FailingStaffSource(),
        lens: adminLens,
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, StaffRosterStatus.failed);
    });

    test('keeps the team it has and marks it cached', () async {
      final cubit = StaffRosterCubit(
        source: _FlakyStaffSource(),
        lens: adminLens,
      );
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, StaffRosterStatus.ready);

      await cubit.refresh();
      expect(cubit.state.status, StaffRosterStatus.cached);
      expect(cubit.state.roster.members, isNotEmpty);
    });
  });

  group('the roster the filters leave', () {
    test('opens on the active staff, upcoming listed separately', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state.visible.every((member) => member.isActive), isTrue);
      expect(cubit.state.startingSoon.single.name, 'Lena Fontaine');
    });

    test('search matches a name and a designation', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      cubit.search('dana');
      expect(cubit.state.visible.single.name, 'Dana Whitfield');

      cubit.search('cook');
      expect(cubit.state.visible.single.designation, 'Cook');

      cubit.clearSearch();
      expect(cubit.state.visible.length, greaterThan(1));
    });

    test(
      'a designation filter narrows, and its chip takes it back off',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.load();

        cubit.applyFilters(
          const StaffFilters(designations: <String>{'Teacher'}),
        );
        expect(
          cubit.state.visible.every(
            (member) => member.designation == 'Teacher',
          ),
          isTrue,
        );

        final chip = cubit.state.chips.firstWhere(
          (chip) => chip.group == StaffChipGroup.designation,
        );
        cubit.removeChip(chip);
        expect(cubit.state.filters.designations, isEmpty);
      },
    );

    test('an attendance filter narrows to that state only', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      cubit.applyFilters(
        const StaffFilters(
          attendance: <AttendanceStatus>{AttendanceStatus.absent},
        ),
      );

      expect(cubit.state.visible, isNotEmpty);
      expect(
        cubit.state.visible.every(
          (member) => member.attendance == AttendanceStatus.absent,
        ),
        isTrue,
      );
    });

    test('Z to A reverses the order', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      final aToZ = cubit.state.visible.map((member) => member.name).toList();
      cubit.applyFilters(const StaffFilters(order: StaffOrder.zToA));
      final zToA = cubit.state.visible.map((member) => member.name).toList();

      expect(zToA, aToZ.reversed.toList());
    });

    test(
      'a filter that matches nobody is a no-match, not an empty school',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.load();

        cubit.search('nobody at all');
        expect(cubit.state.hasNoMatches, isTrue);
        expect(cubit.state.hasNoStaff, isFalse);
      },
    );
  });

  group('the read boundary', () {
    test(
      'a teacher sees their own record and their classroom colleagues',
      () async {
        final cubit = StaffRosterCubit(
          source: const PreviewStaffSource(),
          lens: staffLens,
        );
        addTearDown(cubit.close);
        await cubit.load();

        expect(cubit.state.isViewOnly, isTrue);
        expect(cubit.state.ownRecord?.name, 'Dana Whitfield');
        expect(cubit.state.team, isNotEmpty);
        expect(
          cubit.state.team.every(
            (member) => member.sharesClassroomWith('Sunflower'),
          ),
          isTrue,
        );
        expect(
          cubit.state.team.any((member) => member.id == 'dana'),
          isFalse,
          reason: 'the viewer is not their own colleague',
        );
      },
    );

    test('a teacher with no classroom on the session sees nobody', () async {
      final cubit = StaffRosterCubit(
        source: const PreviewStaffSource(),
        lens: const StaffLens(persona: Persona.staff, viewerId: 'dana'),
      );
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state.team, isEmpty);
    });

    test('deactivating is refused for anybody but an Admin', () async {
      final cubit = StaffRosterCubit(
        source: const PreviewStaffSource(),
        lens: staffLens,
      );
      addTearDown(cubit.close);
      await cubit.load();

      final ok = await cubit.setActive(id: 'tomas', isActive: false);
      expect(ok, isFalse);
    });
  });

  group('select mode', () {
    test('picks and clears, and closes the open row', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      cubit.toggleExpanded('dana');
      expect(cubit.state.expandedId, 'dana');

      cubit.toggleSelectMode();
      expect(cubit.state.isSelectMode, isTrue);
      expect(cubit.state.expandedId, isNull);

      cubit
        ..toggleSelected('dana')
        ..toggleSelected('priya');
      expect(cubit.state.selectedIds, <String>{'dana', 'priya'});

      cubit.toggleSelected('dana');
      expect(cubit.state.selectedIds, <String>{'priya'});

      cubit.clearSelection();
      expect(cubit.state.selectedIds, isEmpty);
    });
  });

  test('deactivating patches the row and the counts in place', () async {
    final cubit = StaffRosterCubit(
      source: const PreviewStaffSource(),
      lens: adminLens,
    );
    addTearDown(cubit.close);
    await cubit.load();

    final before = cubit.state.roster.activeCount;
    final ok = await cubit.setActive(id: 'tomas', isActive: false);

    expect(ok, isTrue);
    expect(cubit.state.roster.activeCount, before - 1);
    expect(
      cubit.state.roster.members
          .firstWhere((member) => member.id == 'tomas')
          .status,
      StaffStatus.inactive,
    );
  });
}

/// Reachable once, then not: the roster it already has must stay up.
class _FlakyStaffSource extends PreviewStaffSource {
  _FlakyStaffSource();

  bool _hasAnswered = false;

  @override
  Future<StaffRoster> loadRoster() async {
    if (_hasAnswered) throw Exception('offline');
    _hasAnswered = true;
    return super.loadRoster();
  }
}
