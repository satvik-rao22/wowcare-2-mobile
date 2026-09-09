/// Unit tests for [RecipientSelectionCubit] — the bulk-messaging recipient
/// picker's selection/filter state extracted from `setState` (Mandate 2/5).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/cubit/recipient_selection_cubit.dart';

void main() {
  late RecipientSelectionCubit cubit;
  setUp(() => cubit = RecipientSelectionCubit());
  tearDown(() => cubit.close());

  test('defaults to Active status and empty selections', () {
    expect(cubit.state.selectedStatus, 'Active');
    expect(cubit.state.selectedStaffCodes, isEmpty);
    expect(cubit.state.selectedStudentCodes, isEmpty);
    expect(cubit.state.selectedClassrooms, isEmpty);
  });

  test('toggleStaff adds then removes', () {
    cubit
      ..toggleStaff('S1', true)
      ..toggleStaff('S2', true);
    expect(cubit.state.selectedStaffCodes, {'S1', 'S2'});
    cubit.toggleStaff('S1', false);
    expect(cubit.state.selectedStaffCodes, {'S2'});
  });

  test('toggleStudent is independent of staff selection', () {
    cubit
      ..toggleStaff('S1', true)
      ..toggleStudent('ST1', true);
    expect(cubit.state.selectedStaffCodes, {'S1'});
    expect(cubit.state.selectedStudentCodes, {'ST1'});
  });

  test('setStatus clears both picked sets', () {
    cubit
      ..toggleStaff('S1', true)
      ..toggleStudent('ST1', true)
      ..setStatus('Upcoming');
    expect(cubit.state.selectedStatus, 'Upcoming');
    expect(cubit.state.selectedStaffCodes, isEmpty);
    expect(cubit.state.selectedStudentCodes, isEmpty);
  });

  test('setStatus(null) clears the status', () {
    cubit.setStatus(null);
    expect(cubit.state.selectedStatus, isNull);
  });

  test('setTagData prunes selected tags no longer offered', () {
    cubit
      ..setTags(['Allergy', 'VIP'])
      ..setTagData(['VIP', 'New'], {'VIP': 'T2', 'New': 'T3'});
    expect(cubit.state.tagOptions, ['VIP', 'New']);
    expect(cubit.state.selectedTags, ['VIP']); // 'Allergy' pruned
    expect(cubit.state.tagNameToCode, {'VIP': 'T2', 'New': 'T3'});
  });

  test('clearAll resets filters/picks and restores Active status', () {
    cubit
      ..setClassrooms(['Rose'])
      ..setDesignations(['TEACHER'])
      ..setTags(['VIP'])
      ..setStatus('Upcoming')
      ..toggleStaff('S1', true)
      ..toggleStudent('ST1', true)
      ..clearAll();
    expect(cubit.state.selectedClassrooms, isEmpty);
    expect(cubit.state.selectedDesignations, isEmpty);
    expect(cubit.state.selectedTags, isEmpty);
    expect(cubit.state.selectedStatus, 'Active');
    expect(cubit.state.selectedStaffCodes, isEmpty);
    expect(cubit.state.selectedStudentCodes, isEmpty);
  });

  test('setStaffSelection / setStudentSelection replace wholesale', () {
    cubit
      ..toggleStaff('S0', true)
      ..setStaffSelection({'S1', 'S2', 'S3'});
    expect(cubit.state.selectedStaffCodes, {'S1', 'S2', 'S3'});

    cubit.setStudentSelection({'ST1'});
    expect(cubit.state.selectedStudentCodes, {'ST1'});
  });

  test('setSelectingAll toggles the loading flag', () {
    cubit.setSelectingAll(true);
    expect(cubit.state.isSelectingAll, isTrue);
    cubit.setSelectingAll(false);
    expect(cubit.state.isSelectingAll, isFalse);
  });

  test('filter setters do not disturb picked recipients', () {
    cubit
      ..toggleStaff('S1', true)
      ..setClassrooms(['Rose'])
      ..setDesignations(['TEACHER'])
      ..setTags(['VIP']);
    expect(cubit.state.selectedStaffCodes, {'S1'});
    expect(cubit.state.selectedClassrooms, ['Rose']);
    expect(cubit.state.selectedDesignations, ['TEACHER']);
    expect(cubit.state.selectedTags, ['VIP']);
  });
}
