import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/auth/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, String>> call(String email) {
    return AppEvents.track(
      AppEvent.authForgotPassword,
      () => _repository.forgotPassword(email),
      failureOf: AppEvents.leftFailure,
    );
  }
}

