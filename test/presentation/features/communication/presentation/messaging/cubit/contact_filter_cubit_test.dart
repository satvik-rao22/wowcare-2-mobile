/// Unit tests for [ContactFilterCubit] — the StaffMessagingTab contact
/// filter/search view-state extracted from `setState` (Mandate 2/5).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/contact_filter_cubit.dart';

void main() {
  late ContactFilterCubit cubit;
  setUp(() => cubit = ContactFilterCubit());
  tearDown(() => cubit.close());

  test('defaults to Active status, unread off, no search', () {
    expect(cubit.state.currentFilters, {
      'Status': ['Active'],
    });
    expect(cubit.state.showUnread, isFalse);
    expect(cubit.state.serverSearchResults, isNull);
  });

  test('setShowUnread mirrors into currentFilters[Unread]', () {
    cubit.setShowUnread(true);
    expect(cubit.state.showUnread, isTrue);
    expect(cubit.state.currentFilters['Unread'], ['true']);

    cubit.setShowUnread(false);
    expect(cubit.state.showUnread, isFalse);
    expect(cubit.state.currentFilters['Unread'], isEmpty);
  });

  test('setFilters keeps the unread toggle in sync with the map', () {
    cubit.setFilters({
      'Status': ['Upcoming'],
      'Unread': ['true'],
    });
    expect(cubit.state.currentFilters['Status'], ['Upcoming']);
    expect(cubit.state.showUnread, isTrue);

    cubit.setFilters({
      'Status': ['Active'],
    });
    expect(cubit.state.showUnread, isFalse);
  });

  test('setDefaultClassroom merges without dropping other filters', () {
    cubit
      ..setFilters({
        'Status': ['Upcoming'],
        'Tags': ['VIP'],
      })
      ..setDefaultClassroom('Rose');
    expect(cubit.state.currentFilters['Classroom'], ['Rose']);
    expect(cubit.state.currentFilters['Status'], ['Upcoming']);
    expect(cubit.state.currentFilters['Tags'], ['VIP']);
  });

  test('clearFilters resets to Active-only, unread off, search cleared', () {
    cubit
      ..setFilters({
        'Status': ['Upcoming'],
        'Classroom': ['Rose'],
      })
      ..setShowUnread(true)
      ..setSearchResults(const [])
      ..clearFilters();
    expect(cubit.state.currentFilters, {
      'Status': ['Active'],
      'Unread': <String>[],
    });
    expect(cubit.state.showUnread, isFalse);
    expect(cubit.state.serverSearchResults, isNull);
  });

  test('setSearchResults(null) clears results', () {
    cubit
      ..setSearchResults(const [])
      ..setSearchResults(null);
    expect(cubit.state.serverSearchResults, isNull);
  });

  test('identity and derived contact sets are independent', () {
    cubit
      ..setIdentity(userCode: 'STF_1', accountCode: 'USR_1')
      ..setStaffContactCodes({'USR_2', 'USR_3'})
      ..setStudentContactNames({'ann lee'})
      ..setTagNameToCode({'VIP': 'T1'});
    expect(cubit.state.currentUserCode, 'STF_1');
    expect(cubit.state.currentAccountCode, 'USR_1');
    expect(cubit.state.allContactCodes, {'USR_2', 'USR_3'});
    expect(cubit.state.allContactNames, {'ann lee'});
    expect(cubit.state.tagNameToCode, {'VIP': 'T1'});
  });
}
