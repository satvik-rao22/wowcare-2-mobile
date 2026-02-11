import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/create_school_user_result.dart';
import '../../../../domain/features/staff/usecases/create_school_user_usecase.dart';

part 'create_school_user_state.dart';

class CreateSchoolUserCubit extends Cubit<CreateSchoolUserState> {
  CreateSchoolUserCubit({
    required CreateSchoolUserUseCase createSchoolUserUseCase,
    required StorageService storageService,
  })  : _createSchoolUserUseCase = createSchoolUserUseCase,
        super(const CreateSchoolUserState.initial());

  final CreateSchoolUserUseCase _createSchoolUserUseCase;

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
    emit(const CreateSchoolUserState.loading());

    // TEMP: Always use default org + school constants for all staff creation.
    final resolvedOrganizationCode = StorageKeys.defaultOrganizationCode;
    final resolvedSchoolCode = StorageKeys.defaultSchoolCode;

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

    result.fold(
      (failure) => emit(CreateSchoolUserState.error(
        failure.message ?? 'Failed to create user',
      )),
      (result) => emit(CreateSchoolUserState.success(result)),
    );
  }

  void reset() => emit(const CreateSchoolUserState.initial());
}


