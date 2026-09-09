import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';

/// Real in-memory storage so the repository's real CacheManager can round-trip
/// (no reliance on production SharedPreferences/Firebase/network).
class _InMemoryStorage implements StorageService {
  final Map<String, String> strings = {};
  final Map<String, bool> bools = {};
  final Map<String, Map<String, dynamic>> jsons = {};

  @override
  Future<void> saveString(String key, String value) async =>
      strings[key] = value;
  @override
  Future<String?> getString(String key) async => strings[key];
  @override
  Future<void> saveBool(String key, bool value) async => bools[key] = value;
  @override
  Future<bool?> getBool(String key) async => bools[key];
  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async =>
      jsons[key] = value;
  @override
  Future<Map<String, dynamic>?> getJson(String key) async => jsons[key];
  @override
  Future<void> remove(String key) async {
    strings.remove(key);
    jsons.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Fake datasource: overrides only the methods under test (the interface has
/// ~96 methods — the rest throw via noSuchMethod so an unexpected call is loud).
class _FakeDataSource implements StudentRemoteDataSource {
  // getStudentPage
  StudentPageModel? pageResult;
  Object? pageThrows;
  final List<Map<String, dynamic>> pageCalls = [];

  @override
  Future<StudentPageModel> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
  }) async {
    pageCalls.add({'schoolCode': schoolCode, 'status': status, 'page': page});
    if (pageThrows != null) throw pageThrows!;
    return pageResult ??
        const StudentPageModel(
          items: [],
          page: 0,
          size: 10,
          totalPages: 1,
          totalElements: 0,
          hasMore: false,
        );
  }

  // getStudentHealth
  StudentHealthModel healthResult = const StudentHealthModel();
  @override
  Future<StudentHealthModel> getStudentHealth({required String code}) async =>
      healthResult;

  // getStudentProfile
  StudentProfileModel? profileResult;
  @override
  Future<StudentProfileModel> getStudentProfile(String code) async =>
      profileResult!;

  // getStudentRegularSchedules
  List<Map<String, dynamic>> regularSchedulesResult = const [];
  @override
  Future<List<Map<String, dynamic>>> getStudentRegularSchedules({
    required String studentCode,
  }) async => regularSchedulesResult;

  // getGuardiansBySchool
  List<Map<String, dynamic>> guardiansResult = const [];
  @override
  Future<List<Map<String, dynamic>>> getGuardiansBySchool({
    required String schoolCode,
  }) async => guardiansResult;

  // deleteStudent
  String deleteResult = 'deleted';
  final List<String> deletedCodes = [];
  @override
  Future<String> deleteStudent(String code) async {
    deletedCodes.add(code);
    return deleteResult;
  }

  // updateStudentRegularSchedules
  final List<List<Map<String, dynamic>>> schedulePayloads = [];
  @override
  Future<String> updateStudentRegularSchedules({
    required String schoolCode,
    required String studentCode,
    required List<Map<String, dynamic>> schedule,
  }) async {
    schedulePayloads.add(schedule);
    return 'schedule saved';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  late _FakeDataSource ds;
  late _InMemoryStorage storage;
  late StudentRepositoryImpl repo;

  setUp(() {
    ds = _FakeDataSource();
    storage = _InMemoryStorage();
    repo = StudentRepositoryImpl(ds, storage);
  });

  group('getStudentPage', () {
    test(
      'normalizes status to upper-case, maps items, caches page 0',
      () async {
        ds.pageResult = const StudentPageModel(
          items: [
            StudentListItemModel(
              code: 'S1',
              firstName: 'Ann',
              lastName: 'Lee',
              status: 'ACTIVE',
              classroom: 'Blue',
            ),
          ],
          page: 0,
          size: 10,
          totalPages: 2,
          totalElements: 1,
          hasMore: true,
        );

        final page = await repo.getStudentPage(
          schoolCode: 'SCH',
          status: 'active',
        );

        // status normalized before hitting the datasource
        expect(ds.pageCalls.single['status'], 'ACTIVE');
        // DTO -> domain entity, fields carried
        expect(page.items.single.code, 'S1');
        expect(page.items.single.firstName, 'Ann');
        expect(page.items.single.classroom, 'Blue');
        expect(page.hasMore, isTrue);
        // page 0 was cached (a cache entry now exists in storage)
        expect(storage.jsons, isNotEmpty);
      },
    );

    test('empty datasource page maps to an empty entity page', () async {
      final page = await repo.getStudentPage(
        schoolCode: 'SCH',
        status: 'ACTIVE',
      );
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('a datasource failure propagates', () async {
      ds.pageThrows = Exception('network down');
      expect(
        () => repo.getStudentPage(schoolCode: 'SCH'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getStudentHealth', () {
    test('maps the DTO to the domain entity', () async {
      ds.healthResult = const StudentHealthModel(
        allergy: 'peanuts',
        medications: 'none',
        dietRestrictions: 'vegetarian',
        photoPermission: true,
      );
      final health = await repo.getStudentHealth(studentCode: 'S1');
      expect(health.allergy, 'peanuts');
      expect(health.medications, 'none');
      expect(health.dietRestrictions, 'vegetarian');
      expect(health.photoPermission, isTrue);
    });
  });

  group('getStudentProfile', () {
    test('falls back to code when the model full name is empty', () async {
      ds.profileResult = const StudentProfileModel(
        code: 'STU-9',
        schoolCode: ' SCH ',
        firstName: '',
        lastName: '',
        status: 'ACTIVE',
        classroom: ' Blue Room ',
      );
      final profile = await repo.getStudentProfile(code: 'STU-9');
      expect(profile.fullName, 'STU-9'); // fallback to code
      expect(profile.schoolCode, 'SCH'); // trimmed
      expect(profile.classroomName, 'Blue Room'); // trimmed
    });

    test('uses the composed full name when present', () async {
      ds.profileResult = const StudentProfileModel(
        code: 'STU-9',
        schoolCode: 'SCH',
        firstName: 'Ann',
        lastName: 'Lee',
        status: 'ACTIVE',
      );
      final profile = await repo.getStudentProfile(code: 'STU-9');
      expect(profile.fullName, 'Ann Lee');
    });
  });

  group('getStudentRegularSchedules', () {
    test('parses int and string time fields and upper-cases the day', () async {
      ds.regularSchedulesResult = const [
        {
          'dayOfWeek': 'monday',
          'startTime': {'hour': 7, 'minute': 30},
          'endTime': {'hour': '17', 'minute': '0'},
        },
      ];
      final entries = await repo.getStudentRegularSchedules(studentCode: 'S1');
      final e = entries.single;
      expect(e.dayOfWeek, 'MONDAY');
      expect(e.startHour, 7);
      expect(e.startMinute, 30);
      expect(e.endHour, 17);
      expect(e.endMinute, 0);
    });

    test('missing/malformed time maps default to zero', () async {
      ds.regularSchedulesResult = const [
        {'dayOfWeek': 'tue', 'startTime': null, 'endTime': 'bad'},
      ];
      final e = (await repo.getStudentRegularSchedules(
        studentCode: 'S1',
      )).single;
      expect(e.dayOfWeek, 'TUE');
      expect(e.startHour, 0);
      expect(e.endHour, 0);
    });
  });

  group('getGuardiansRawForSchool', () {
    test('maps raw guardian maps to trimmed domain summaries', () async {
      ds.guardiansResult = const [
        {'code': '  G1  ', 'firstName': '  Ann  ', 'lastName': ' Lee '},
      ];
      final guardians = await repo.getGuardiansRawForSchool(schoolCode: 'SCH');
      expect(guardians.single.code, 'G1');
      expect(guardians.single.firstName, 'Ann');
      expect(guardians.single.lastName, 'Lee');
    });

    test('empty datasource result → empty list', () async {
      ds.guardiansResult = const [];
      expect(await repo.getGuardiansRawForSchool(schoolCode: 'SCH'), isEmpty);
    });
  });

  group('mutations', () {
    test('deleteStudent forwards the code and returns the message', () async {
      ds.deleteResult = 'Student removed';
      final msg = await repo.deleteStudent(code: 'S1', schoolCode: 'SCH');
      expect(ds.deletedCodes.single, 'S1');
      expect(msg, 'Student removed');
    });

    test('updateStudentRegularSchedules forwards the mapped payload', () async {
      final msg = await repo.updateStudentRegularSchedules(
        schoolCode: 'SCH',
        studentCode: 'S1',
        schedule: const [],
      );
      expect(msg, 'schedule saved');
      expect(ds.schedulePayloads, hasLength(1));
    });
  });
}
