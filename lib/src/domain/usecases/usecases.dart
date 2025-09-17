import '../../core/util/typedefs.dart';

abstract class UseCaseWithParams<Type, Params> {
  const UseCaseWithParams();

  ResultFuture<Type> call(Params params);
}

abstract class UseCaseWithoutParams<Type> {
  const UseCaseWithoutParams();

  ResultFuture<Type> call();
}

abstract class UseCaseWithOutParams<T> {
  const UseCaseWithOutParams();
  ResultFuture<T> call();
}
