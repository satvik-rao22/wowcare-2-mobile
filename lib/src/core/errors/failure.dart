import 'package:equatable/equatable.dart';
import 'exceptions.dart';

abstract class Failure extends Equatable {
  Failure({required this.message, required this.statusCode})
    : assert(
        statusCode is String || statusCode is int,
        'Status code cannot be a ${statusCode.runtimeType}',
      );

  final String message;
  final dynamic statusCode;

  String get errorMessage {
    return message;
  }

  @override
  List<dynamic> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  CacheFailure({required super.message, required super.statusCode});
}

class ServerFailure extends Failure {
  ServerFailure({required super.message, required super.statusCode});

  ServerFailure.fromException(ServerException exeption)
    : this(message: exeption.message, statusCode: exeption.statusCode);
}

class ApiFailure extends Failure {
  ApiFailure({required super.message, required super.statusCode});

  ApiFailure.fromApiException(ApiException exception)
    : this(message: exception.message, statusCode: exception.statusCode);
}
