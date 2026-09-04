import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/staff/cubit/edit_staff_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';

import 'harness.dart';

void main() {
  EditStaffCubit build({String staffId = 'dana', StaffLens lens = adminLens}) =>
      EditStaffCubit(
        source: const PreviewStaffSource(),
        staffId: staffId,
        lens: lens,
      );

  test('seeds the form from the record', () async {
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, EditStaffStatus.editing);
    expect(cubit.state.draft.firstName, 'Dana');
    expect(cubit.state.draft.lastName, 'Whitfield');
    expect(cubit.state.draft.phone, isNotEmpty);
    expect(cubit.state.draft.city, 'Nashua');
  });

  test('fails when the record cannot be reached', () async {
    final cubit = EditStaffCubit(
      source: const FailingStaffSource(),
      staffId: 'dana',
      lens: adminLens,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isFailed, isTrue);
  });

  test('refuses a blank name, a bad email and a short phone number', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    cubit
      ..setFirstName('')
      ..setLastName('')
      ..setEmail('not-an-address')
      ..setPhone('123');
    await cubit.submit();

    expect(cubit.state.errorFor(StaffField.firstName), isNotNull);
    expect(cubit.state.errorFor(StaffField.lastName), isNotNull);
    expect(cubit.state.errorFor(StaffField.email), isNotNull);
    expect(cubit.state.errorFor(StaffField.phone), isNotNull);
    expect(cubit.state.isSaved, isFalse);
  });

  test('typing clears the last error', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();
    cubit.setPhone('123');
    await cubit.submit();
    expect(cubit.state.errors, isNotEmpty);

    cubit.setPhone('(603) 555-0113');

    expect(cubit.state.errors, isEmpty);
  });

  test('saves the name, the contact and the address', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    cubit
      ..setPhone('(603) 555-0999')
      ..setStreet('12 Birch Lane');
    await cubit.submit();

    expect(cubit.state.isSaved, isTrue);
    expect(cubit.state.profile!.member.phone, '(603) 555-0999');
    expect(cubit.state.profile!.address.street, '12 Birch Lane');
  });

  test('a teacher may edit their own record and nobody else', () async {
    final own = build(lens: staffLens);
    addTearDown(own.close);
    await own.load();
    expect(own.state.canEdit, isTrue);

    final other = build(staffId: 'priya', lens: staffLens);
    addTearDown(other.close);
    await other.load();
    expect(other.state.canEdit, isFalse);
  });
}
