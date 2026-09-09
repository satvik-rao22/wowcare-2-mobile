import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_address_update.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile_update.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/activate_organization_admin_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/activate_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/change_user_email_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/deactivate_organization_admin_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/deactivate_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_staff_address_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_staff_allowed_classrooms_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_staff_primary_classroom_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_profile_edit_cubit.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_uploader.dart';
import 'package:wowcare/shared/services/image_upload/staff_photo_background_upload_service.dart';

/// Never invoked by these tests — the cubit only forwards to it from
/// `uploadProfilePhotoInBackground`, which none of them call.
class _FakePhotoUploader implements ProfilePhotoUploader {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeUpdateProfileUseCase extends UpdateStaffProfileUseCase {
  _FakeUpdateProfileUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'profile updated';
  Completer<String>? gate;

  @override
  Future<String> call({
    required String staffCode,
    required StaffProfileUpdate fields,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _FakeUpdateAddressUseCase extends UpdateStaffAddressUseCase {
  _FakeUpdateAddressUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'address updated';

  @override
  Future<String> call({
    required String staffCode,
    required StaffAddressUpdate fields,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeUpdateAllowedClassroomsUseCase
    extends UpdateStaffAllowedClassroomsUseCase {
  _FakeUpdateAllowedClassroomsUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'allowed updated';

  @override
  Future<String> call({
    required String staffCode,
    required List<String> classroomCodes,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeUpdatePrimaryClassroomUseCase
    extends UpdateStaffPrimaryClassroomUseCase {
  _FakeUpdatePrimaryClassroomUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'primary updated';

  @override
  Future<String> call({
    required String staffCode,
    required String classroomCode,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeChangeUserEmailUseCase extends ChangeUserEmailUseCase {
  _FakeChangeUserEmailUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'email changed';

  @override
  Future<String> call({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeActivateOrgAdminUseCase extends ActivateOrganizationAdminUseCase {
  _FakeActivateOrgAdminUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'org admin activated';

  @override
  Future<String> call({
    required String userCode,
    required String organizationCode,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeDeactivateOrgAdminUseCase
    extends DeactivateOrganizationAdminUseCase {
  _FakeDeactivateOrgAdminUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'org admin deactivated';

  @override
  Future<String> call({
    required String userCode,
    required String organizationCode,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeActivateSchoolUserUseCase extends ActivateSchoolUserUseCase {
  _FakeActivateSchoolUserUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'school user activated';

  @override
  Future<String> call({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _FakeDeactivateSchoolUserUseCase extends DeactivateSchoolUserUseCase {
  _FakeDeactivateSchoolUserUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'school user deactivated';

  @override
  Future<String> call({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

class _Fakes {
  final updateProfile = _FakeUpdateProfileUseCase();
  final updateAddress = _FakeUpdateAddressUseCase();
  final updateAllowed = _FakeUpdateAllowedClassroomsUseCase();
  final updatePrimary = _FakeUpdatePrimaryClassroomUseCase();
  final changeEmail = _FakeChangeUserEmailUseCase();
  final activateOrgAdmin = _FakeActivateOrgAdminUseCase();
  final deactivateOrgAdmin = _FakeDeactivateOrgAdminUseCase();
  final activateSchoolUser = _FakeActivateSchoolUserUseCase();
  final deactivateSchoolUser = _FakeDeactivateSchoolUserUseCase();

  StaffProfileEditCubit build() => StaffProfileEditCubit(
    updateStaffProfileUseCase: updateProfile,
    updateStaffAddressUseCase: updateAddress,
    updateStaffAllowedClassroomsUseCase: updateAllowed,
    updateStaffPrimaryClassroomUseCase: updatePrimary,
    changeUserEmailUseCase: changeEmail,
    activateOrganizationAdminUseCase: activateOrgAdmin,
    deactivateOrganizationAdminUseCase: deactivateOrgAdmin,
    activateSchoolUserUseCase: activateSchoolUser,
    deactivateSchoolUserUseCase: deactivateSchoolUser,
    getStaffProfileUseCase: GetStaffProfileUseCase(_FakeRepo()),
    photoBackgroundUploadService: StaffPhotoBackgroundUploadService(
      _FakePhotoUploader(),
    ),
  );
}

void main() {
  group('mutations call the right use case', () {
    test('updateProfile', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateProfile(
        staffCode: 'ST1',
        fields: const StaffProfileUpdate(
          firstName: 'A',
          lastName: '',
          status: '',
          phoneNumber: '',
          designation: '',
        ),
      );

      expect(fakes.updateProfile.calls, 1);
      expect(message, 'profile updated');
      await cubit.close();
    });

    test('updateAddress', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateAddress(
        staffCode: 'ST1',
        fields: const StaffAddressUpdate(
          addressStreet: '',
          addressLine2: '',
          addressCity: 'Nashua',
          addressState: '',
          addressZipCode: '',
          addressCountry: '',
        ),
      );

      expect(fakes.updateAddress.calls, 1);
      expect(message, 'address updated');
      await cubit.close();
    });

    test('updateAllowedClassrooms', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateAllowedClassrooms(
        staffCode: 'ST1',
        classroomCodes: const ['C1'],
      );

      expect(fakes.updateAllowed.calls, 1);
      expect(message, 'allowed updated');
      await cubit.close();
    });

    test('updatePrimaryClassroom', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updatePrimaryClassroom(
        staffCode: 'ST1',
        classroomCode: 'C1',
      );

      expect(fakes.updatePrimary.calls, 1);
      expect(message, 'primary updated');
      await cubit.close();
    });

    test('changeUserEmail', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.changeUserEmail(
        userCode: 'U1',
        oldEmail: 'a@b.com',
        newEmail: 'c@d.com',
        organizationCode: 'ORG',
        schoolCode: 'SCH',
      );

      expect(fakes.changeEmail.calls, 1);
      expect(message, 'email changed');
      await cubit.close();
    });

    test('activateOrganizationAdmin', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.activateOrganizationAdmin(
        userCode: 'U1',
        organizationCode: 'ORG',
      );

      expect(fakes.activateOrgAdmin.calls, 1);
      expect(message, 'org admin activated');
      await cubit.close();
    });

    test('deactivateOrganizationAdmin', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.deactivateOrganizationAdmin(
        userCode: 'U1',
        organizationCode: 'ORG',
      );

      expect(fakes.deactivateOrgAdmin.calls, 1);
      expect(message, 'org admin deactivated');
      await cubit.close();
    });

    test('activateSchoolUser', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.activateSchoolUser(
        userCode: 'U1',
        organizationCode: 'ORG',
        schoolCode: 'SCH',
        role: 'STAFF',
      );

      expect(fakes.activateSchoolUser.calls, 1);
      expect(message, 'school user activated');
      await cubit.close();
    });

    test('deactivateSchoolUser', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.deactivateSchoolUser(
        userCode: 'U1',
        organizationCode: 'ORG',
        schoolCode: 'SCH',
        role: 'STAFF',
      );

      expect(fakes.deactivateSchoolUser.calls, 1);
      expect(message, 'school user deactivated');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('updateProfile rethrows', () async {
      final fakes = _Fakes();
      fakes.updateProfile.error = Exception('profile failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateProfile(
          staffCode: 'ST1',
          fields: const StaffProfileUpdate(
            firstName: '',
            lastName: '',
            status: '',
            phoneNumber: '',
            designation: '',
          ),
        ),
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
          staffCode: 'ST1',
          fields: const StaffAddressUpdate(
            addressStreet: '',
            addressLine2: '',
            addressCity: '',
            addressState: '',
            addressZipCode: '',
            addressCountry: '',
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updateAllowedClassrooms rethrows', () async {
      final fakes = _Fakes();
      fakes.updateAllowed.error = Exception('allowed failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateAllowedClassrooms(
          staffCode: 'ST1',
          classroomCodes: const [],
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updatePrimaryClassroom rethrows', () async {
      final fakes = _Fakes();
      fakes.updatePrimary.error = Exception('primary failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updatePrimaryClassroom(staffCode: 'ST1', classroomCode: 'C1'),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('changeUserEmail rethrows', () async {
      final fakes = _Fakes();
      fakes.changeEmail.error = Exception('email failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.changeUserEmail(
          userCode: 'U1',
          oldEmail: 'a@b.com',
          newEmail: 'c@d.com',
          organizationCode: 'ORG',
          schoolCode: 'SCH',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('activateOrganizationAdmin rethrows', () async {
      final fakes = _Fakes();
      fakes.activateOrgAdmin.error = Exception('activate org failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.activateOrganizationAdmin(
          userCode: 'U1',
          organizationCode: 'ORG',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('deactivateOrganizationAdmin rethrows', () async {
      final fakes = _Fakes();
      fakes.deactivateOrgAdmin.error = Exception('deactivate org failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.deactivateOrganizationAdmin(
          userCode: 'U1',
          organizationCode: 'ORG',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('activateSchoolUser rethrows', () async {
      final fakes = _Fakes();
      fakes.activateSchoolUser.error = Exception('activate school failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.activateSchoolUser(
          userCode: 'U1',
          organizationCode: 'ORG',
          schoolCode: 'SCH',
          role: 'STAFF',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('deactivateSchoolUser rethrows', () async {
      final fakes = _Fakes();
      fakes.deactivateSchoolUser.error = Exception('deactivate school failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.deactivateSchoolUser(
          userCode: 'U1',
          organizationCode: 'ORG',
          schoolCode: 'SCH',
          role: 'STAFF',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent updateProfile() for the same staffCode issue '
    'ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<String>();
      fakes.updateProfile.gate = gate;
      final cubit = fakes.build();

      const fields = StaffProfileUpdate(
        firstName: 'A',
        lastName: '',
        status: '',
        phoneNumber: '',
        designation: '',
      );
      final f1 = cubit.updateProfile(staffCode: 'ST1', fields: fields);
      final f2 = cubit.updateProfile(staffCode: 'ST1', fields: fields);

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.updateProfile.calls, 1);

      gate.complete('profile updated');
      await Future.wait<String>([f1, f2]);

      expect(fakes.updateProfile.calls, 1);
      await cubit.close();
    },
  );
}
