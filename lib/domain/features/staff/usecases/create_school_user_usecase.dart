import 'package:wowcare/core/observability/app_events.dart';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../entities/create_school_user_result.dart';
import '../repositories/staff_repository.dart';

class CreateSchoolUserUseCase {
  CreateSchoolUserUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, CreateSchoolUserResult>> call({
    required bool isAdmin,
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String organizationCode,
    required String schoolCode,
    required String role,
    required String designation,
    String? userCode,
    String? status,
    String? primaryClassroomCode,
    List<String>? allowedClassroomCodes,
  }) async {
    try {
      final result = await AppEvents.track(AppEvent.staffCreate, () {
        if (isAdmin) {
          return _repository.createSchoolAdminUser(
            userCode: userCode,
            firstName: firstName,
            lastName: lastName,
            displayName: displayName,
            mobile: mobile,
            email: email,
            organizationCode: organizationCode,
            schoolCode: schoolCode,
            role: role,
            designation: designation,
          );
        }

        // Always send status in uppercase as expected by backend (e.g. ACTIVE)
        final resolvedStatus = (status ?? 'Active').toUpperCase();
        final resolvedPrimary = primaryClassroomCode ?? '';
        final resolvedAllowed = allowedClassroomCodes ?? const <String>[];

        return _repository.createStaffUser(
          userCode: userCode,
          firstName: firstName,
          lastName: lastName,
          displayName: displayName,
          mobile: mobile,
          email: email,
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          role: role,
          designation: designation,
          status: resolvedStatus,
          primaryClassroomCode: resolvedPrimary,
          allowedClassroomCodes: resolvedAllowed,
        );
      });
      return Right(result);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}


