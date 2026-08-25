import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/auth/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, String>> call(String email) {
    return _repository.forgotPassword(email);
  }
}
