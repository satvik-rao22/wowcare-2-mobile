import 'package:dio/dio.dart';

abstract final class RegErrorCodes {
  const RegErrorCodes._();

  /// 409 on sign-in; `rejectedValue` carries the blocked day(s).
  static const String regularizationRequired = 'REGULARIZATION_REQUIRED';

  /// 409 on `PATCH /{code}`; approval is terminal.
  static const String alreadyApproved = 'REGULARIZATION_ALREADY_APPROVED';
}

/// An edit that lost a race with an approval. The UI must say so — a silent
/// no-op would leave the user believing their change applied.
class RegAlreadyApprovedException implements Exception {
  const RegAlreadyApprovedException(this.code);

  final String code;

  String get message =>
      'This request was already approved, so it can no longer be edited.';

  @override
  String toString() => 'RegAlreadyApprovedException($code)';
}

class RegException implements Exception {
  const RegException(this.message);

  final String message;

  @override
  String toString() => 'RegException($message)';
}

/// Reads this feature's failures out of a Dio error.
///
/// Matches on `error.code`, never the status alone: a 409 on sign-in could just
/// as easily be "already signed in", and opening a sheet for that is wrong.
abstract final class RegHttpErrors {
  const RegHttpErrors._();

  static String codeOf(Object? error) {
    final body = _body(error);
    if (body == null) return '';
    final err = body['error'];
    if (err is Map) return (err['code'] ?? '').toString().trim();
    return (body['code'] ?? '').toString().trim();
  }

  static String messageOf(Object? error) =>
      (_body(error)?['message'] ?? '').toString().trim();

  static bool isRegularizationRequired(Object? error) =>
      codeOf(error) == RegErrorCodes.regularizationRequired;

  /// Falls back to a bare 409 when the body carried no code, so a gateway that
  /// strips the envelope still surfaces the right message.
  static bool isAlreadyApproved(Object? error) {
    final code = codeOf(error);
    if (code.isNotEmpty) return code == RegErrorCodes.alreadyApproved;
    return _status(error) == 409;
  }

  /// The blocked day(s) from a 409, so the sheet opens with no second call.
  /// Empty means fall back to a fresh gate check.
  static List<Map<String, dynamic>> blockedSessionsFrom(Object? error) {
    final rejected = rejectedValueOf(error);
    if (rejected is List) return _asMaps(rejected);
    if (rejected is Map) return [Map<String, dynamic>.from(rejected)];
    return const [];
  }

  static Object? rejectedValueOf(Object? error) {
    final body = _body(error);
    if (body == null) return null;
    final err = body['error'];
    if (err is Map && err.containsKey('rejectedValue')) {
      return err['rejectedValue'];
    }
    return body['rejectedValue'];
  }

  static int? _status(Object? error) =>
      error is DioException ? error.response?.statusCode : null;

  static Map<String, dynamic>? _body(Object? error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static List<Map<String, dynamic>> _asMaps(List raw) => raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}
