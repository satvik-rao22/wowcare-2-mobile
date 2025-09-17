import '../../../../../core/Common/usecases/usecases.dart';
import '../../../../../core/util/typedefs.dart';
import '../repository/on_boarding_repo.dart';

class CacheFirstTimer extends UseCaseWithoutParams<void> {
  const CacheFirstTimer(this._repo);

  final OnBoardingRepo _repo;

  @override
  ResultFuture<void> call() async => _repo.cacheFirstTimer();
}
