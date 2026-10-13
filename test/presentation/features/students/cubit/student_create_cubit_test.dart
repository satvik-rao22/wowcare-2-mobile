import 'dart:async';
import 'dart:io';
import 'package:wowcare/shared/services/asset/profile_photo_background_uploader.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule_input.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/entities/update_guardian_request.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_sibling_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/create_guardian_user_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/create_student_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/link_existing_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_regular_schedules_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_create_cubit.dart';

const _emptyPage = StudentPage(
  items: <Student>[],
  page: 0,
  size: 150,
  totalPages: 0,
  totalElements: 0,
  hasMore: false,
);

const _student = Student(
  code: 'STU1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  status: 'ACTIVE',
);

const _profile = StudentProfile(
  code: 'STU1',
  schoolCode: 'SCH',
  fullName: 'Ada Lovelace',
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetPageUseCase extends GetStudentPageUseCase {
  _FakeGetPageUseCase() : super(_FakeRepo());

  int calls = 0;
  StudentPage result = _emptyPage;
  Object? error;

  @override
  Future<StudentPage> call({
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
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGetProfileUseCase extends GetStudentProfileUseCase {
  _FakeGetProfileUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> codes = <String>[];
  StudentProfile result = _profile;
  Object? error;

  @override
  Future<StudentProfile> call({required String code}) async {
    calls++;
    codes.add(code);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGuardianNameCodeMapUseCase
    extends GetGuardianNameCodeMapForSchoolUseCase {
  _FakeGuardianNameCodeMapUseCase() : super(_FakeRepo());

  int calls = 0;
  Map<String, String> result = const <String, String>{};
  Object? error;

  @override
  Future<Map<String, String>> call({required String schoolCode}) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeCreateStudentUseCase extends CreateStudentUseCase {
  _FakeCreateStudentUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  Student result = _student;
  Completer<Student>? gate;

  @override
  Future<Student> call({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _FakeCreateGuardianUserUseCase extends CreateGuardianUserUseCase {
  _FakeCreateGuardianUserUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  ({String message, String? guardianCode}) result =
      (message: 'guardian created', guardianCode: 'G1');

  @override
  Future<({String message, String? guardianCode})> call({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeLinkExistingGuardianUseCase extends LinkExistingGuardianUseCase {
  _FakeLinkExistingGuardianUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'guardian linked';

  @override
  Future<String> call({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeAddStudentSiblingUseCase extends AddStudentSiblingUseCase {
  _FakeAddStudentSiblingUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'siblings linked';

  @override
  Future<String> call({
    required String studentCode,
    required List<String> siblingCodes,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeUpdateGuardianUseCase extends UpdateGuardianUseCase {
  _FakeUpdateGuardianUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'guardian updated';

  @override
  Future<String> call({
    required String code,
    required String studentCode,
    required UpdateGuardianRequest request,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeUpdateSchedulesUseCase extends UpdateStudentRegularSchedulesUseCase {
  _FakeUpdateSchedulesUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'schedule updated';

  @override
  Future<String> call({
    required String schoolCode,
    required String studentCode,
    required List<StudentRegularScheduleInput> schedule,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _Fakes {
  final getPage = _FakeGetPageUseCase();
  final getProfile = _FakeGetProfileUseCase();
  final guardianNameCodeMap = _FakeGuardianNameCodeMapUseCase();
  final createStudent = _FakeCreateStudentUseCase();
  final createGuardian = _FakeCreateGuardianUserUseCase();
  final linkGuardian = _FakeLinkExistingGuardianUseCase();
  final addSibling = _FakeAddStudentSiblingUseCase();
  final updateGuardian = _FakeUpdateGuardianUseCase();
  final updateSchedules = _FakeUpdateSchedulesUseCase();

  StudentCreateCubit build() => StudentCreateCubit(
    profilePhotoBackgroundUploader: _NoopProfilePhotoBackgroundUploader(),
    getStudentPageUseCase: getPage,
    getStudentProfileUseCase: getProfile,
    getGuardianNameCodeMapForSchoolUseCase: guardianNameCodeMap,
    createStudentUseCase: createStudent,
    createGuardianUserUseCase: createGuardian,
    linkExistingGuardianUseCase: linkGuardian,
    addStudentSiblingUseCase: addSibling,
    updateGuardianUseCase: updateGuardian,
    updateStudentRegularSchedulesUseCase: updateSchedules,
  );
}

void main() {
  group('reads', () {
    test('fetchStudentPage returns the get-page use-case value', () async {
      final fakes = _Fakes();
      fakes.getPage.result = _emptyPage;
      final cubit = fakes.build();

      final page = await cubit.fetchStudentPage(
        schoolCode: 'SCH',
        firstName: 'Ada',
        lastName: 'Lovelace',
        page: 0,
        size: 25,
      );

      expect(fakes.getPage.calls, 1);
      expect(identical(page, _emptyPage), isTrue);
      await cubit.close();
    });

    test('fetchStudentProfile returns the get-profile use-case value', () async {
      final fakes = _Fakes();
      fakes.getProfile.result = _profile;
      final cubit = fakes.build();

      final profile = await cubit.fetchStudentProfile('STU1');

      expect(fakes.getProfile.calls, 1);
      expect(fakes.getProfile.codes.last, 'STU1');
      expect(identical(profile, _profile), isTrue);
      await cubit.close();
    });

    test('fetchGuardianNameCodeMapForSchool returns the use-case value',
        () async {
      final fakes = _Fakes();
      fakes.guardianNameCodeMap.result = const {'Jane Doe': 'G1'};
      final cubit = fakes.build();

      final map =
          await cubit.fetchGuardianNameCodeMapForSchool(schoolCode: 'SCH');

      expect(fakes.guardianNameCodeMap.calls, 1);
      expect(map, const {'Jane Doe': 'G1'});
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('createStudent', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final student = await cubit.createStudent(
        schoolCode: 'SCH',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: 'ACTIVE',
        classroom: 'CR1',
      );

      expect(fakes.createStudent.calls, 1);
      expect(identical(student, _student), isTrue);
      await cubit.close();
    });

    test('createGuardianUser', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final result = await cubit.createGuardianUser(
        schoolCode: 'SCH',
        studentCode: 'STU1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        mobile: '5551234567',
        relationToStudent: 'MOTHER',
        primaryContact: true,
        legalCustody: true,
      );

      expect(fakes.createGuardian.calls, 1);
      expect(result.message, 'guardian created');
      expect(result.guardianCode, 'G1');
      await cubit.close();
    });

    test('linkExistingGuardian', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.linkExistingGuardian(
        guardianCode: 'G1',
        studentCode: 'STU1',
        relation: 'MOTHER',
      );

      expect(fakes.linkGuardian.calls, 1);
      expect(message, 'guardian linked');
      await cubit.close();
    });

    test('addStudentSibling', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.addStudentSibling(
        studentCode: 'STU1',
        siblingCodes: const ['STU2'],
      );

      expect(fakes.addSibling.calls, 1);
      expect(message, 'siblings linked');
      await cubit.close();
    });

    test('updateGuardian', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateGuardian(
        code: 'G1',
        studentCode: 'STU1',
        request: const UpdateGuardianRequest(
          userCode: 'U1',
          schoolCode: 'SCH',
          studentCode: 'STU1',
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane@x.com',
          mobile: '5551234567',
          relationToStudent: 'MOTHER',
          primaryContact: true,
          legalCustody: true,
        ),
      );

      expect(fakes.updateGuardian.calls, 1);
      expect(message, 'guardian updated');
      await cubit.close();
    });

    test('updateStudentRegularSchedules', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateStudentRegularSchedules(
        schoolCode: 'SCH',
        studentCode: 'STU1',
        schedule: const [
          StudentRegularScheduleInput(
            dayOfWeek: 'MONDAY',
            startTime: '08:00:00',
            halfDay: '12:00:00',
            endTime: '16:00:00',
          ),
        ],
      );

      expect(fakes.updateSchedules.calls, 1);
      expect(message, 'schedule updated');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('createStudent rethrows', () async {
      final fakes = _Fakes();
      fakes.createStudent.error = Exception('create failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.createStudent(
          schoolCode: 'SCH',
          firstName: 'Ada',
          lastName: 'Lovelace',
          status: 'ACTIVE',
          classroom: 'CR1',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('createGuardianUser rethrows', () async {
      final fakes = _Fakes();
      fakes.createGuardian.error = Exception('guardian failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.createGuardianUser(
          schoolCode: 'SCH',
          studentCode: 'STU1',
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane@example.com',
          mobile: '5551234567',
          relationToStudent: 'MOTHER',
          primaryContact: true,
          legalCustody: true,
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('linkExistingGuardian rethrows', () async {
      final fakes = _Fakes();
      fakes.linkGuardian.error = Exception('link failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.linkExistingGuardian(guardianCode: 'G1', studentCode: 'STU1'),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('addStudentSibling rethrows', () async {
      final fakes = _Fakes();
      fakes.addSibling.error = Exception('sibling failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.addStudentSibling(studentCode: 'STU1', siblingCodes: const []),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent createStudent() with identical params issue '
    'ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<Student>();
      fakes.createStudent.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.createStudent(
        schoolCode: 'SCH',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: 'ACTIVE',
        classroom: 'CR1',
      );
      final f2 = cubit.createStudent(
        schoolCode: 'SCH',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: 'ACTIVE',
        classroom: 'CR1',
      );

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.createStudent.calls, 1);

      gate.complete(_student);
      await Future.wait<Student>([f1, f2]);

      expect(fakes.createStudent.calls, 1);
      await cubit.close();
    },
  );

  group('step 1 form model', () {
    test('initial fields are unset', () {
      final cubit = _Fakes().build();
      expect(cubit.state.step1Status, isNull);
      expect(cubit.state.step1Classroom, isNull);
      expect(cubit.state.step1Birthdate, isNull);
      expect(cubit.state.step1ProfilePhoto, isNull);
      expect(cubit.state.step1Submitting, isFalse);
    });

    test('initializeStep1 defaults status to Active and derives age label', () {
      final cubit = _Fakes().build()
        ..initializeStep1(birthdate: DateTime(2022, 1, 1));
      expect(cubit.state.step1Status, 'Active');
      expect(cubit.state.step1AgeLabel, isNotNull);
      expect(cubit.state.step1AgeLabel, contains('year'));
    });

    test('initializeStep1 respects an explicit status', () {
      final cubit = _Fakes().build()..initializeStep1(status: 'Upcoming');
      expect(cubit.state.step1Status, 'Upcoming');
      expect(cubit.state.step1AgeLabel, isNull);
    });

    test('setters update each field', () {
      final cubit = _Fakes().build()
        ..setStep1Status('Upcoming')
        ..setStep1Classroom('Blue-A')
        ..setStep1SchoolStartDate(DateTime(2027, 9, 1));
      expect(cubit.state.step1Status, 'Upcoming');
      expect(cubit.state.step1Classroom, 'Blue-A');
      expect(cubit.state.step1SchoolStartDate, DateTime(2027, 9, 1));
    });

    test('setStep1Birthdate also derives the age label; null clears it', () {
      final cubit = _Fakes().build()..setStep1Birthdate(DateTime(2020, 6, 1));
      expect(cubit.state.step1Birthdate, DateTime(2020, 6, 1));
      expect(cubit.state.step1AgeLabel, isNotNull);
      cubit.setStep1Birthdate(null);
      expect(cubit.state.step1Birthdate, isNull);
      expect(cubit.state.step1AgeLabel, isNull);
    });

    test('setStep1Submitting toggles the flow flag', () {
      final cubit = _Fakes().build()..setStep1Submitting(true);
      expect(cubit.state.step1Submitting, isTrue);
      cubit.setStep1Submitting(false);
      expect(cubit.state.step1Submitting, isFalse);
    });

    test('ageLabelFor formats months-only for infants', () {
      final now = DateTime.now();
      final label = StudentCreateCubit.ageLabelFor(
        DateTime(now.year, now.month - 3 <= 0 ? 1 : now.month - 3, 1),
      );
      expect(label, contains('month'));
    });
  });

  group('step 2 form model', () {
    test('initial defaults (emergency + custody on)', () {
      final cubit = _Fakes().build();
      expect(cubit.state.step2SelectFromExisting, isFalse);
      expect(cubit.state.step2SelectedExistingParents, isEmpty);
      expect(cubit.state.step2IsEmergencyContact, isTrue);
      expect(cubit.state.step2IsChildCustody, isTrue);
      expect(cubit.state.step2Submitting, isFalse);
    });

    test('initializeStep2 seeds provided values', () {
      final cubit = _Fakes().build()
        ..initializeStep2(
          selectFromExisting: true,
          selectedExistingParents: const ['Jane Doe'],
          relation: 'Mother',
          isEmergencyContact: false,
          isChildCustody: false,
        );
      expect(cubit.state.step2SelectFromExisting, isTrue);
      expect(cubit.state.step2SelectedExistingParents, const ['Jane Doe']);
      expect(cubit.state.step2Relation, 'Mother');
      expect(cubit.state.step2IsEmergencyContact, isFalse);
      expect(cubit.state.step2IsChildCustody, isFalse);
    });

    test('setters update each field', () {
      final cubit = _Fakes().build()
        ..setStep2SelectFromExisting(true)
        ..setStep2SelectedExistingParents(const ['A', 'B'])
        ..setStep2Relation('Father')
        ..setStep2IsEmergencyContact(false)
        ..setStep2IsChildCustody(false)
        ..setStep2Submitting(true);
      expect(cubit.state.step2SelectFromExisting, isTrue);
      expect(cubit.state.step2SelectedExistingParents, const ['A', 'B']);
      expect(cubit.state.step2Relation, 'Father');
      expect(cubit.state.step2IsEmergencyContact, isFalse);
      expect(cubit.state.step2IsChildCustody, isFalse);
      expect(cubit.state.step2Submitting, isTrue);
    });

    test('setStep2ExistingParents stores names and prunes a stale selection',
        () {
      final cubit = _Fakes().build()
        ..setStep2SelectedExistingParents(const ['Jane Doe', 'Gone Person'])
        ..setStep2ExistingParents(const ['Jane Doe', 'New Parent']);
      expect(cubit.state.step2ExistingParents,
          const ['Jane Doe', 'New Parent']);
      expect(cubit.state.step2SelectedExistingParents, const ['Jane Doe']);
    });
  });
}

/// The delete/upload photo path isn't exercised in these tests — a no-op so the
/// cubit constructs without a real uploader/network.
class _NoopProfilePhotoBackgroundUploader
    implements ProfilePhotoBackgroundUploader {
  @override
  Future<void> uploadStudentPhoto({
    required String studentCode,
    required File file,
    required String schoolCode,
    required String organizationCode,
  }) async {}

  @override
  Future<void> uploadGuardianPhoto({
    required File file,
    required String guardianCode,
    required String studentCode,
    required String email,
    required String mobile,
    required String schoolCode,
    required String organizationCode,
    required String userCode,
  }) async {}
}
