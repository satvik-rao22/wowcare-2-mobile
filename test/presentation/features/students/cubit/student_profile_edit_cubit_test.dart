import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/domain/features/student/entities/update_student_address_request.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_guardians_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_address_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_profile_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_siblings_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_tags_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_profile_edit_cubit.dart';

StudentGuardian _guardian(String code) => StudentGuardian(
  guardianCode: code,
  userCode: 'U-$code',
  firstName: 'Jane',
  lastName: 'Doe',
  mobile: '5551234567',
  email: 'jane@example.com',
  relationToStudent: 'MOTHER',
  primaryContact: true,
  legalCustody: true,
);

const _emptyPage = StudentPage(
  items: <Student>[],
  page: 0,
  size: 150,
  totalPages: 0,
  totalElements: 0,
  hasMore: false,
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

class _FakeGetGuardiansUseCase extends GetStudentGuardiansUseCase {
  _FakeGetGuardiansUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  List<StudentGuardian> result = const <StudentGuardian>[];
  Object? error;

  @override
  Future<List<StudentGuardian>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeUpdateProfileUseCase extends UpdateStudentProfileUseCase {
  _FakeUpdateProfileUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'profile updated';
  Completer<String>? gate;

  @override
  Future<String> call({
    required String code,
    required Map<String, dynamic> fields,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _FakeUpdateAddressUseCase extends UpdateStudentAddressUseCase {
  _FakeUpdateAddressUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'address updated';
  final List<UpdateStudentAddressRequest> requests =
      <UpdateStudentAddressRequest>[];

  @override
  Future<String> call({
    required String studentCode,
    required UpdateStudentAddressRequest request,
  }) {
    calls++;
    requests.add(request);
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeUpdateTagsUseCase extends UpdateStudentTagsUseCase {
  _FakeUpdateTagsUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'tags updated';

  @override
  Future<String> call({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeUpdateSiblingsUseCase extends UpdateStudentSiblingsUseCase {
  _FakeUpdateSiblingsUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'siblings updated';

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
    required Map<String, dynamic> fields,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _Fakes {
  final getPage = _FakeGetPageUseCase();
  final getGuardians = _FakeGetGuardiansUseCase();
  final updateProfile = _FakeUpdateProfileUseCase();
  final updateAddress = _FakeUpdateAddressUseCase();
  final updateTags = _FakeUpdateTagsUseCase();
  final updateSiblings = _FakeUpdateSiblingsUseCase();
  final updateGuardian = _FakeUpdateGuardianUseCase();

  StudentProfileEditCubit build() => StudentProfileEditCubit(
    getStudentPageUseCase: getPage,
    getStudentGuardiansUseCase: getGuardians,
    updateStudentProfileUseCase: updateProfile,
    updateStudentAddressUseCase: updateAddress,
    updateStudentTagsUseCase: updateTags,
    updateStudentSiblingsUseCase: updateSiblings,
    updateGuardianUseCase: updateGuardian,
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
        status: 'ACTIVE',
        page: 0,
        size: 150,
      );

      expect(fakes.getPage.calls, 1);
      expect(identical(page, _emptyPage), isTrue);
      await cubit.close();
    });

    test('fetchGuardians returns the guardians use-case value', () async {
      final fakes = _Fakes();
      fakes.getGuardians.result = [_guardian('G1'), _guardian('G2')];
      final cubit = fakes.build();

      final guardians = await cubit.fetchGuardians('S1');

      expect(fakes.getGuardians.calls, 1);
      expect(fakes.getGuardians.studentCodes.last, 'S1');
      expect(guardians.map((g) => g.guardianCode), ['G1', 'G2']);
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('updateProfile', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateProfile(
        code: 'S1',
        fields: const {'firstName': 'A'},
      );

      expect(fakes.updateProfile.calls, 1);
      expect(message, 'profile updated');
      await cubit.close();
    });

    test('updateAddress', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateAddress(
        studentCode: 'S1',
        request: const UpdateStudentAddressRequest(
          street: '12 Oak St',
          city: 'Nashua',
          state: 'NH',
          country: 'US',
          postalCode: '03060',
        ),
      );

      expect(fakes.updateAddress.calls, 1);
      expect(fakes.updateAddress.requests.single.city, 'Nashua');
      expect(message, 'address updated');
      await cubit.close();
    });

    test('updateTags', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateTags(
        studentCode: 'S1',
        schoolCode: 'SCH',
        tagCodes: const ['TAG_1'],
      );

      expect(fakes.updateTags.calls, 1);
      expect(message, 'tags updated');
      await cubit.close();
    });

    test('updateSiblings', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateSiblings(
        studentCode: 'S1',
        siblingCodes: const ['S2'],
      );

      expect(fakes.updateSiblings.calls, 1);
      expect(message, 'siblings updated');
      await cubit.close();
    });

    test('updateGuardian', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateGuardian(
        code: 'G1',
        studentCode: 'S1',
        fields: const {'legalCustody': true},
      );

      expect(fakes.updateGuardian.calls, 1);
      expect(message, 'guardian updated');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('updateProfile rethrows', () async {
      final fakes = _Fakes();
      fakes.updateProfile.error = Exception('profile failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateProfile(code: 'S1', fields: const {}),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updateAddress rethrows', () async {
      final fakes = _Fakes();
      fakes.updateAddress.error = Exception('address failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateAddress(
          studentCode: 'S1',
          request: const UpdateStudentAddressRequest(
            street: '',
            city: '',
            state: '',
            country: '',
            postalCode: '',
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updateTags rethrows', () async {
      final fakes = _Fakes();
      fakes.updateTags.error = Exception('tags failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateTags(
          studentCode: 'S1',
          schoolCode: 'SCH',
          tagCodes: const [],
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updateSiblings rethrows', () async {
      final fakes = _Fakes();
      fakes.updateSiblings.error = Exception('siblings failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateSiblings(studentCode: 'S1', siblingCodes: const []),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updateGuardian rethrows', () async {
      final fakes = _Fakes();
      fakes.updateGuardian.error = Exception('guardian failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateGuardian(code: 'G1', studentCode: 'S1', fields: const {}),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent updateProfile() for the same code issue ONE '
    'use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<String>();
      fakes.updateProfile.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.updateProfile(code: 'S1', fields: const {'a': 1});
      final f2 = cubit.updateProfile(code: 'S1', fields: const {'a': 1});

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.updateProfile.calls, 1);

      gate.complete('profile updated');
      await Future.wait<String>([f1, f2]);

      expect(fakes.updateProfile.calls, 1);
      await cubit.close();
    },
  );

  group('profile-edit form model', () {
    test('initial state defaults', () {
      final cubit = _Fakes().build();
      expect(cubit.state.status, isNull);
      expect(cubit.state.selectedTags, isEmpty);
      expect(cubit.state.isTodayStatusLoading, isTrue);
      expect(cubit.state.isSignedInToday, isFalse);
      expect(cubit.state.submitting, isFalse);
      expect(cubit.state.classroomChangedByUser, isFalse);
    });

    test('initialize seeds the simple fields', () {
      final cubit = _Fakes().build()
        ..initialize(
          status: 'Active',
          gender: 'Female',
          classroom: 'Blue-A',
          birthDate: DateTime(2021, 4, 2),
          stateName: 'Texas',
          selectedTags: const ['VIP'],
        );
      expect(cubit.state.status, 'Active');
      expect(cubit.state.gender, 'Female');
      expect(cubit.state.classroom, 'Blue-A');
      expect(cubit.state.birthDate, DateTime(2021, 4, 2));
      expect(cubit.state.stateName, 'Texas');
      expect(cubit.state.selectedTags, const ['VIP']);
      // seeding does NOT flag a user classroom change
      expect(cubit.state.classroomChangedByUser, isFalse);
    });

    test('setClassroom flags a user change; other setters update fields', () {
      final cubit = _Fakes().build()
        ..setStatus('Inactive')
        ..setGender('Male')
        ..setStateSubsidyOption('Yes')
        ..setSelectedSiblings(const ['Sib A'])
        ..setSelectedChildCustody(const ['Guardian X'])
        ..setSubmitting(true)
        ..setClassroom('Red-B');
      expect(cubit.state.status, 'Inactive');
      expect(cubit.state.gender, 'Male');
      expect(cubit.state.stateSubsidyOption, 'Yes');
      expect(cubit.state.selectedSiblings, const ['Sib A']);
      expect(cubit.state.selectedChildCustody, const ['Guardian X']);
      expect(cubit.state.submitting, isTrue);
      expect(cubit.state.classroom, 'Red-B');
      expect(cubit.state.classroomChangedByUser, isTrue);
    });

    test('setTodayStatus resolves the attendance gate', () {
      final cubit = _Fakes().build()..setTodayStatus(isSignedInToday: true);
      expect(cubit.state.isSignedInToday, isTrue);
      expect(cubit.state.isTodayStatusLoading, isFalse);
    });

    test('applyTagsLoaded / applyStudentsLoaded / applyGuardiansLoaded set '
        'options + maps + selection', () {
      final cubit = _Fakes().build()
        ..applyTagsLoaded(
          names: const ['VIP'],
          nameToCode: const {'VIP': 'T1'},
          selectedTags: const ['VIP'],
        )
        ..applyStudentsLoaded(
          names: const ['Sib A'],
          nameToCode: const {'Sib A': 'S9'},
          selectedSiblings: const ['Sib A'],
        )
        ..applyGuardiansLoaded(
          names: const ['Guardian X'],
          nameToCode: const {'Guardian X': 'G1'},
          initialCustody: const {'Guardian X': true},
          rawByCode: const {
            'G1': StudentGuardian(
              guardianCode: 'G1',
              userCode: 'U1',
              firstName: 'Guardian',
              lastName: 'X',
              mobile: '5551234567',
              email: 'gx@x.com',
              relationToStudent: 'MOTHER',
              primaryContact: true,
              legalCustody: true,
            ),
          },
          selectedChildCustody: const ['Guardian X'],
        );
      expect(cubit.state.availableTagNames, const ['VIP']);
      expect(cubit.state.tagNameToCode, const {'VIP': 'T1'});
      expect(cubit.state.studentNameToCode, const {'Sib A': 'S9'});
      expect(cubit.state.guardianInitialCustody, const {'Guardian X': true});
      expect(cubit.state.guardianRawByCode['G1']?.userCode, 'U1');
      expect(cubit.state.guardianRawByCode['G1']?.legalCustody, isTrue);
      expect(cubit.state.selectedChildCustody, const ['Guardian X']);
    });
  });
}
