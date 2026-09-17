import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/load_cached_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_settings_usecase.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_profile_cubit.dart';

StaffProfile _profile(String staffCode) => StaffProfile(
  staffCode: staffCode,
  userCode: 'U1',
  organizationCode: 'ORG-A',
  schoolCode: 'SCH-A',
  firstName: 'Sam',
  lastName: 'Staff',
  fullName: 'Sam Staff',
  email: 'sam@example.com',
  phoneNumber: '000',
  staffType: 'STAFF',
  status: 'ACTIVE',
  designation: 'TEACHER',
  allowedClassroomCodes: const <String>[],
  address: const StaffProfileAddress(),
  workSchedules: const <StaffProfileWorkSchedule>[],
  breakSchedules: const <StaffProfileBreakSchedule>[],
);

/// Records the args getStaffProfile was called with and returns a fixed
/// profile, so we can assert fetchProfile forwards through the use case.
class _RecordingRepo implements StaffRepository {
  String? lastStaffCode;
  bool? lastForEditStaff;

  @override
  Future<StaffProfile> getStaffProfile({
    required String staffCode,
    bool forEditStaff = false,
    bool forceRefresh = false,
  }) async {
    lastStaffCode = staffCode;
    lastForEditStaff = forEditStaff;
    return _profile(staffCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Neither existing test exercises settings-fetching, so this fake never
/// expects a call — it exists only to satisfy StaffProfileCubit's
/// constructor.
class _UnusedStudentRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test(
    'fetchProfile returns the use-case value and forwards staffCode',
    () async {
      final repo = _RecordingRepo();
      final cubit = StaffProfileCubit(
        getStaffProfileUseCase: GetStaffProfileUseCase(repo),
        loadCachedStaffProfileUseCase: LoadCachedStaffProfileUseCase(repo),
        getStudentSettingsUseCase: GetStudentSettingsUseCase(
          _UnusedStudentRepo(),
        ),
      );

      final result = await cubit.fetchProfile(staffCode: 'S9');

      expect(result.staffCode, 'S9');
      expect(repo.lastStaffCode, 'S9');
      // Default mirrors StaffRepository.getStaffProfile (forEditStaff: false).
      expect(repo.lastForEditStaff, isFalse);
      await cubit.close();
    },
  );

  test('fetchProfile forwards forEditStaff:true when requested', () async {
    final repo = _RecordingRepo();
    final cubit = StaffProfileCubit(
      getStaffProfileUseCase: GetStaffProfileUseCase(repo),
      loadCachedStaffProfileUseCase: LoadCachedStaffProfileUseCase(repo),
      getStudentSettingsUseCase: GetStudentSettingsUseCase(
        _UnusedStudentRepo(),
      ),
    );

    await cubit.fetchProfile(staffCode: 'S9', forEditStaff: true);

    expect(repo.lastForEditStaff, isTrue);
    await cubit.close();
  });
}
