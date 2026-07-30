import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_assignee_scope.dart';

/// PRD §5.2 "Create Task": an admin persona may assign a task to any active
/// staff member, while a Staff/Teacher persona may only "assign to staff in
/// allowed classes only". These tests pin the classroom scope the assignee
/// picker is loaded with, per persona, from cached session state only (no
/// network, no service locator).
class _FakeStorage implements StorageService {
  _FakeStorage(this._data);

  final Map<String, String> _data;

  @override
  Future<String?> getString(String key) async => _data[key];
  @override
  Future<void> saveString(String key, String value) async => _data[key] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

StorageService _storage({
  required String activeRole,
  String staffType = '',
  List<String> allowedClassrooms = const [],
}) =>
    _FakeStorage({
      StorageKeys.activeSchoolRole: activeRole,
      if (staffType.isNotEmpty) StorageKeys.staffType: staffType,
      if (allowedClassrooms.isNotEmpty)
        StorageKeys.staffAllowedClassroomCodes: jsonEncode(allowedClassrooms),
    });

void main() {
  group('assignableStaffClassroomScope', () {
    test('school admin may assign to any active staff (no restriction)',
        () async {
      final codes = await assignableStaffClassroomScope(
        storage: _storage(activeRole: 'SCHOOL_ADMIN'),
      );
      expect(codes, isEmpty);
    });

    test('org admin may assign to any active staff (no restriction)', () async {
      final codes = await assignableStaffClassroomScope(
        storage: _storage(activeRole: 'ORGANIZATION_ADMIN'),
      );
      expect(codes, isEmpty);
    });

    test('teacher is restricted to their allowed classrooms', () async {
      final codes = await assignableStaffClassroomScope(
        storage: _storage(
          activeRole: 'STAFF',
          staffType: 'TEACHER',
          allowedClassrooms: ['CLS_1', 'CLS_2'],
        ),
      );
      expect(codes, ['CLS_1', 'CLS_2']);
    });

    test('a staff member whose staffType is an admin type is unrestricted',
        () async {
      final codes = await assignableStaffClassroomScope(
        storage: _storage(
          activeRole: 'STAFF',
          staffType: 'SCHOOL_ADMIN',
          allowedClassrooms: ['CLS_1'],
        ),
      );
      expect(codes, isEmpty);
    });

    test('guardian persona is never classroom-scoped (and has no task access)',
        () async {
      final codes = await assignableStaffClassroomScope(
        storage: _storage(
          activeRole: 'GUARDIAN',
          allowedClassrooms: ['CLS_1'],
        ),
      );
      expect(codes, isEmpty);
    });
  });
}
