import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reports_repository.dart';
import 'generate_report_usecase.dart';
import 'get_recent_reports_usecase.dart';

class GetStudentTagsUseCase implements UseCase<List<String>, NoParams> {
  GetStudentTagsUseCase(this._repository);

  final ReportsRepository _repository;

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    try {
      final tags = await _repository.getStudentTags();
      return Right(tags);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Failure _mapExceptionToFailure(dynamic e) {
    if (e is Failure) {
      return e;
    }

    return ServerFailure('Failed to fetch student tags: ${e.toString()}');
  }
}
