import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_gate_cubit.dart';

class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeFormList extends GetStaffSignInFormListUseCase {
  _FakeFormList() : super(_UnusedRepo());
}

/// Storage that returns configured values by key.
class _FakeStorage implements StorageService {
  final Map<String, String?> values;
  _FakeStorage([this.values = const {}]);

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('StaffSignInGateCubit', () {
    late StaffSignInGateCubit cubit;

    setUp(() {
      cubit = StaffSignInGateCubit(
        getStaffSignInFormList: _FakeFormList(),
        storageService: _FakeStorage(),
        apiClient: _FakeApiClient(),
      );
    });

    tearDown(() => cubit.close());

    test('setSelectedDate / setSelectedTime update state', () {
      final d = DateTime(2026, 8, 27);
      cubit.setSelectedDate(d);
      cubit.setSelectedTime(const TimeOfDay(hour: 8, minute: 15));
      expect(cubit.state.selectedDate, d);
      expect(cubit.state.selectedTime, const TimeOfDay(hour: 8, minute: 15));
    });

    test('acknowledgeUnexpected sets flag + comment', () {
      cubit.acknowledgeUnexpected('cover shift');
      expect(cubit.state.unexpectedSignInAcknowledged, isTrue);
      expect(cubit.state.notExpectedComment, 'cover shift');
    });

    test('isExpectedTodayForStaffCode: API value wins, else default true', () {
      expect(cubit.isExpectedTodayForStaffCode('STF-1', {'STF-1': false}), isFalse);
      expect(cubit.isExpectedTodayForStaffCode('STF-1', {'STF-1': true}), isTrue);
      // not in API + not in (empty) selection -> default true
      expect(cubit.isExpectedTodayForStaffCode('STF-9', const {}), isTrue);
      // empty code -> true
      expect(cubit.isExpectedTodayForStaffCode('  ', const {}), isTrue);
    });

    test('requestBodyIsExpectedToday: common value if all agree, else true', () {
      // all expected
      expect(
        cubit.requestBodyIsExpectedToday(
          staffCodes: ['A', 'B'],
          fromApi: {'A': true, 'B': true},
        ),
        isTrue,
      );
      // all NOT expected -> common false
      expect(
        cubit.requestBodyIsExpectedToday(
          staffCodes: ['A', 'B'],
          fromApi: {'A': false, 'B': false},
        ),
        isFalse,
      );
      // mixed -> defaults to true (API can't express per-row)
      expect(
        cubit.requestBodyIsExpectedToday(
          staffCodes: ['A', 'B'],
          fromApi: {'A': true, 'B': false},
        ),
        isTrue,
      );
      // empty -> true
      expect(
        cubit.requestBodyIsExpectedToday(staffCodes: const [], fromApi: const {}),
        isTrue,
      );
    });

    test('resolveExpectedToday: empty staff -> acknowledged, no dialog', () async {
      final outcome = await cubit.resolveExpectedToday();
      expect(outcome.needsDialog, isFalse);
      expect(cubit.state.unexpectedSignInAcknowledged, isTrue);
      expect(cubit.state.unexpectedGateLoading, isFalse);
    });

    test('loadCurrentStaffCode: kiosk code wins; else storage', () async {
      await cubit.loadCurrentStaffCode(isKiosk: true, kioskStaffCode: 'KIOSK-1');
      expect(cubit.state.currentStaffCode, 'KIOSK-1');

      final storageCubit = StaffSignInGateCubit(
        getStaffSignInFormList: _FakeFormList(),
        storageService: _FakeStorage({'staffCode': 'STORE-1'}),
        apiClient: _FakeApiClient(),
      );
      await storageCubit.loadCurrentStaffCode(isKiosk: false);
      expect(storageCubit.state.currentStaffCode, 'STORE-1');
      await storageCubit.close();
    });
  });
}
