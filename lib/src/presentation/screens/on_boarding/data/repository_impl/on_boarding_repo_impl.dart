// import 'package:dartz/dartz.dart';
// import 'package:wowcare/src/core/Common/errors/exceptions.dart';
// import 'package:wowcare/src/core/util/typedefs.dart';
// import 'package:wowcare/src/presentation/screens/on_boarding/data/datasources/on_boarding_local_datasource.dart';
// import 'package:wowcare/src/presentation/screens/on_boarding/domain/repository/on_boarding_repo.dart';

// import '../../../../../core/common/errors/failure.dart';

// class OnBoardingRepoImpl implements OnBoardingRepo {
//   const OnBoardingRepoImpl(this._localDatatSource);

//   final OnBoardingLocalDatasource _localDatatSource;

//   @override
//   ResultFuture<void> cacheFirstTimer() async {
//     try {
//       await _localDatatSource.cacheFirstTimer();

//       return const Right(null);
//     } on CacheException catch (e) {
//       return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
//     }
//   }

//   @override
//   ResultFuture<bool> checkIfUserIsFirstTimer() async {
//     try {
//       final result = await _localDatatSource.checkIfUserIsFirstTimer();

//       return Right(result);
//     } on CacheException catch (e) {
//       return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
//     }
//   }
// }
