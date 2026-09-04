import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';

import 'harness.dart';

void main() {
  StaffProfileCubit build({
    String staffId = 'dana',
    StaffLens lens = adminLens,
  }) => StaffProfileCubit(
    source: const PreviewStaffSource(),
    staffId: staffId,
    lens: lens,
  );

  test('lands on a record with every tab filled', () async {
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, StaffProfileStatus.ready);
    final profile = cubit.state.profile!;
    expect(profile.name, 'Dana Whitfield');
    expect(profile.week, hasLength(5));
    expect(profile.days, hasLength(6));
    expect(profile.documents, hasLength(4));
    expect(profile.dates.hireDate, isNotNull);
    expect(profile.member.signInPin, isNotEmpty);
  });

  test('fails when the record cannot be reached', () async {
    final cubit = StaffProfileCubit(
      source: const FailingStaffSource(),
      staffId: 'dana',
      lens: adminLens,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isFailed, isTrue);
    expect(cubit.state.profile, isNull);
  });

  group('what a viewer gets', () {
    test('an Admin reads the whole record and may change it', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state.seesDetails, isTrue);
      expect(cubit.state.tabs, StaffProfileTab.values);
      expect(cubit.state.canEdit, isTrue);
      expect(cubit.state.canEditSchedule, isTrue);
      expect(cubit.state.canDeactivate, isTrue);
    });

    test(
      'a teacher reads their own record whole but cannot set the week',
      () async {
        final cubit = build(lens: staffLens);
        addTearDown(cubit.close);
        await cubit.load();

        expect(cubit.state.isSelf, isTrue);
        expect(cubit.state.seesDetails, isTrue);
        expect(cubit.state.canEdit, isTrue);
        expect(
          cubit.state.canEditSchedule,
          isFalse,
          reason: 'a work schedule is Admin-only',
        );
        expect(cubit.state.canDeactivate, isFalse);
      },
    );

    test("a colleague's record stops at the profile tab", () async {
      final cubit = build(staffId: 'priya', lens: staffLens);
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state.seesDetails, isFalse);
      expect(cubit.state.tabs, <StaffProfileTab>[StaffProfileTab.profile]);
      expect(cubit.state.canEdit, isFalse);
    });
  });

  test('selecting a tab moves without refetching', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.selectTab(StaffProfileTab.documents);

    expect(cubit.state.tab, StaffProfileTab.documents);
    expect(cubit.state.profile, isNotNull);
  });

  test('deactivating flips the status on the record', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setActive(isActive: false);

    expect(cubit.state.profile!.member.status, StaffStatus.inactive);
  });

  test('a teacher cannot deactivate anybody', () async {
    final cubit = build(staffId: 'priya', lens: staffLens);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setActive(isActive: false);

    expect(cubit.state.profile!.member.status, StaffStatus.active);
  });

  test('a document lands at the top of the list', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();
    final before = cubit.state.profile!.documents.length;

    await cubit.addDocument(name: 'DBS check', type: 'Certificate');

    expect(cubit.state.profile!.documents, hasLength(before + 1));
    expect(cubit.state.profile!.documents.first.name, 'DBS check');
  });
}
