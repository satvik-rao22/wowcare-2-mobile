import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/activity/datasources/activity_remote_datasource.dart';
import 'package:wowcare/data/features/activity/models/activity_settings_models.dart';
import 'package:wowcare/data/features/activity/repositories/activity_repository_impl.dart';

/// Captures the create request / shared payload so we can assert the
/// repository de-duplicated the student codes before dispatch.
class _CapturingDataSource implements ActivityRemoteDataSource {
  ActivityCreateRequestModel? capturedRequest;
  Map<String, dynamic>? capturedSharedPayload;

  @override
  Future<String> createActivity({required ActivityCreateRequestModel request}) async {
    capturedRequest = request;
    return 'ok';
  }

  @override
  Future<List<Map<String, dynamic>>> createSharedActivities({
    required Map<String, dynamic> payload,
  }) async {
    capturedSharedPayload = payload;
    return const <Map<String, dynamic>>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Minimal storage: only the revision int used by ActivityFeedInvalidation.
class _FakeStorage implements StorageService {
  int _rev = 0;
  @override
  Future<int?> getInt(String key) async => _rev;
  @override
  Future<void> saveInt(String key, int value) async => _rev = value;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  late _CapturingDataSource ds;
  late ActivityRepositoryImpl repo;

  setUp(() {
    ds = _CapturingDataSource();
    repo = ActivityRepositoryImpl(ds, _FakeStorage());
  });

  test('createActivity de-dupes student codes and keeps PER_STUDENT for one', () async {
    await repo.createActivity(
      activityTypeCode: 'T',
      classroomCode: 'C',
      studentCodes: const ['STU-1', ' STU-1 ', '', 'STU-1'], // one real student
      staffCode: 'STAFF-1',
      schoolCode: 'SCH-1',
      organizationCode: 'ORG-1',
      activityDate: '2026-01-01T00:00:00Z',
      description: 'd',
    );
    expect(ds.capturedRequest!.studentCodes, ['STU-1']);
    // A duplicated single student must NOT flip to SHARED.
    expect(ds.capturedRequest!.bindingMode, 'PER_STUDENT');
  });

  test('createActivity keeps SHARED for genuinely distinct students, order preserved', () async {
    await repo.createActivity(
      activityTypeCode: 'T',
      classroomCode: 'C',
      studentCodes: const ['STU-2', 'STU-1', 'STU-2'],
      staffCode: 'STAFF-1',
      schoolCode: 'SCH-1',
      organizationCode: 'ORG-1',
      activityDate: '2026-01-01T00:00:00Z',
      description: 'd',
    );
    expect(ds.capturedRequest!.studentCodes, ['STU-2', 'STU-1']);
    expect(ds.capturedRequest!.bindingMode, 'SHARED');
  });

  test('createSharedActivities de-dupes and derives bindingMode from the deduped set', () async {
    await repo.createSharedActivities(
      activityTypeCode: 'T',
      classroomCode: 'C',
      studentCodes: const ['STU-9', 'STU-9'], // duplicate of one student
      staffCode: 'STAFF-1',
      schoolCode: 'SCH-1',
      organizationCode: 'ORG-1',
      activityDate: '2026-01-01T00:00:00Z',
      description: 'd',
      attachments: const <Map<String, dynamic>>[],
    );
    expect(ds.capturedSharedPayload!['studentCodes'], ['STU-9']);
    expect(ds.capturedSharedPayload!['bindingMode'], 'PER_STUDENT');
  });
}
