import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';
import 'report_params.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class GenerateReportUseCase implements UseCase<ReportEntity, ReportParams> {
  GenerateReportUseCase(this._repository);

  final ReportsRepository _repository;

  @override
  Future<Either<Failure, ReportEntity>> call(ReportParams params) async {
    // Validate params based on report type
    final validationError = _validateParams(params);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    try {
      final report = await _repository.generateReport(params);
      return Right(report);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Validate request parameters.
  String? _validateParams(ReportParams params) {
    // Validation logic is delegated to individual parameter classes
    // No global validation needed at this level
    return null;
  }

  /// Map exceptions to failures.
  Failure _mapExceptionToFailure(dynamic e) {
    if (e is Failure) {
      return e;
    }

    return ServerFailure(ApiErrorHandler.extractErrorMessage(e));
  }
}
