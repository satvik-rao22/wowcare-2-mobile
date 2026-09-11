import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/domain/features/reports/repositories/reports_repository.dart';
import 'generate_report_usecase.dart';

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetRecentReportsUseCase
    implements UseCase<List<ReportMetadataEntity>, NoParams> {
  GetRecentReportsUseCase(this._repository);

  final ReportsRepository _repository;

  @override
  Future<Either<Failure, List<ReportMetadataEntity>>> call(
    NoParams params,
  ) async {
    try {
      final reports = await _repository.getRecentReports();
      return Right(reports);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Failure _mapExceptionToFailure(dynamic e) {
    if (e is Failure) {
      return e;
    }

    return ServerFailure('Failed to fetch recent reports: ${e.toString()}');
  }
}
