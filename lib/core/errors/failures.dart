import 'package:equatable/equatable.dart';

import '../utils/api_error_handler.dart';

abstract class Failure extends Equatable {
  const Failure([this.rawMessage]);

  /// The raw message passed in (often a raw exception via `e.toString()`).
  /// Use this ONLY for logging/debugging — never show it to the user.
  final String? rawMessage;

  /// User-facing message. Always sanitized so raw exception / stack-trace text
  /// (e.g. `DioException [bad response]: …`) can never reach the UI. Every
  /// screen that reads `failure.message` therefore gets a friendly string for
  /// free — no per-screen handling required.
  String? get message =>
      rawMessage == null ? null : ApiErrorHandler.sanitizeMessage(rawMessage);

  @override
  List<Object?> get props => [rawMessage];
}

class ServerFailure extends Failure {
  const ServerFailure([super.rawMessage]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.rawMessage]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.rawMessage]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.rawMessage]);
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure([super.rawMessage]);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure([super.rawMessage]);
}
