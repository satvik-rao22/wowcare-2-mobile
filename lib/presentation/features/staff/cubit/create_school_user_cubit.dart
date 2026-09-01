import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/create_school_user_result.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/usecases/create_school_user_usecase.dart';
import '../../../../domain/features/staff/usecases/get_all_staff_usecase.dart';

part 'create_school_user_state.dart';

class CreateSchoolUserCubit extends Cubit<CreateSchoolUserState> {
  CreateSchoolUserCubit({
    required CreateSchoolUserUseCase createSchoolUserUseCase,
    required GetAllStaffUseCase getAllStaffUseCase,
    required StorageService storageService,
  }) : _createSchoolUserUseCase = createSchoolUserUseCase,
       _getAllStaffUseCase = getAllStaffUseCase,
       _storageService = storageService,
       super(const CreateSchoolUserState.initial());

  final CreateSchoolUserUseCase _createSchoolUserUseCase;
  final GetAllStaffUseCase _getAllStaffUseCase;
  final StorageService _storageService;

  /// Thin one-shot fetch of the full staff list via the use case, for the
  /// add-staff duplicate check that previously read
  /// `StaffRepository.getAllStaff(...)` directly. Returns the entities for the
  /// caller to consume, preserving the original repository-read behavior.
  Future<List<StaffMember>> fetchAllStaff({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  }) {
    return _getAllStaffUseCase(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      statuses: statuses,
      size: size,
    );
  }

  /// Re-entrancy guard: a second [create] call while the first is still in
  /// flight (a double-tap) is ignored, so the cubit enforces single-flight
  /// independently of any UI button-disabling — a create is non-idempotent.
  bool _inFlight = false;

  Future<void> create({
    required bool isAdmin,
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String role,
    required String designation,
    String? status,
    String? primaryClassroomCode,
    List<String>? allowedClassroomCodes,
    String? userCode,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      emit(const CreateSchoolUserState.loading());

      // Take org/school from login-context API (saved in storage) only.
      final resolvedOrganizationCode =
          await _storageService.getString(StorageKeys.organizationCode) ?? '';
      final resolvedSchoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final result = await _createSchoolUserUseCase(
        isAdmin: isAdmin,
        userCode: userCode,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        mobile: mobile,
        email: email,
        organizationCode: resolvedOrganizationCode,
        schoolCode: resolvedSchoolCode,
        role: role,
        designation: designation,
        status: status,
        primaryClassroomCode: primaryClassroomCode,
        allowedClassroomCodes: allowedClassroomCodes,
      );

      // The add-staff screen owning this cubit may have been popped while the
      // create was in flight; skip the emit so we don't mutate a closed cubit.
      if (isClosed) return;

      result.fold(
        (failure) => emit(
          CreateSchoolUserState.error(
            failure.message ?? 'Failed to create user',
          ),
        ),
        (result) => emit(CreateSchoolUserState.success(result)),
      );
    } finally {
      _inFlight = false;
    }
  }

  void reset() => emit(const CreateSchoolUserState.initial());
}
