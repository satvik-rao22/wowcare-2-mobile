import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reports_repository.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class DownloadReportUseCase implements UseCase<List<int>, String> {
  const DownloadReportUseCase(this._repository);

  final ReportsRepository _repository;

  @override
  Future<Either<Failure, List<int>>> call(String assetCode) async {
    try {
      // Step 1: Resolve asset to get download URL
      final downloadUrl = await _repository.getReportDownloadUrl(assetCode);

      // Step 2: Download file from the resolved URL
      final fileData = await _repository.downloadReportFile(downloadUrl);
      return Right(fileData);
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      return Left(ServerFailure('Failed to download report: ${e.toString()}'));
    }
  }
}
