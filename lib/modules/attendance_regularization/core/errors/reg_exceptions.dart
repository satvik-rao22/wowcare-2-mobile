import 'package:dio/dio.dart';

/// Error codes the backend returns for this feature.
abstract final class RegErrorCodes {
  const RegErrorCodes._();

  /// Sign-in refused because the staff has an unresolved past day (spec §8.3).
  static const String regularizationRequired = 'REGULARIZATION_REQUIRED';
}

/// Raised when an edit loses a race with an approval (spec §9.4, §10.3).
///
/// Approval is terminal, so `PATCH /{code}` on an already-approved request
/// returns `409`. The UI must say so rather than showing a silent no-op —
/// the user's change genuinely did not apply, and they need to know their
/// correction was superseded.
class RegAlreadyApprovedException implements Exception {
  const RegAlreadyApprovedException(this.code);

  /// The `SREG_…` code that could not be edited.
  final String code;

  String get message =>
      'This request was already approved, so it can no longer be edited.';

  @override
  String toString() => 'RegAlreadyApprovedException($code)';
}

/// Thrown by the module when the module itself cannot proceed — as opposed to
/// a transport failure. Kept minimal on purpose: everything else surfaces
/// through the host's `ApiErrorHandler`.
class RegException implements Exception {
  const RegException(this.message);

  final String message;

  @override
  String toString() => 'RegException($message)';
}

/// Helpers for recognising this feature's HTTP failures.
abstract final class RegHttpErrors {
  const RegHttpErrors._();

  /// True when [error] is the sign-in guard rejecting the request (§8.3).
  ///
  /// Matches on the status **and** the error code, because a `409` on the
  /// sign-in path could also be an unrelated conflict (e.g. already signed
  /// in), and opening a regularization sheet for that would be wrong.
  static bool isRegularizationRequired(Object? error) {
    if (error is! DioException) return false;
    final response = error.response;
    if (response?.statusCode != 409) return false;
    return _bodyText(response?.data)
        .contains(RegErrorCodes.regularizationRequired);
  }

  /// True when [error] is a `409` from `PATCH /{code}` — the request was
  /// approved while the user was editing it (§9.4).
  static bool isAlreadyApproved(Object? error) {
    if (error is! DioException) return false;
    return error.response?.statusCode == 409;
  }

  /// Extracts the open sessions carried by a `409 REGULARIZATION_REQUIRED`
  /// body, so the client can open the gate sheet with **no second call**
  /// (§8.3). Returns `[]` when the payload does not carry them, which is the
  /// signal to fall back to a `GET /open-sessions`.
  ///
  /// Tolerates the three shapes the body could reasonably take:
  /// `{openSessions: [...]}`, `{data: {openSessions: [...]}}` and
  /// `{data: [...]}`.
  static List<Map<String, dynamic>> openSessionsFrom(Object? error) {
    if (error is! DioException) return const [];
    final data = error.response?.data;
    if (data is! Map) return const [];

    final direct = data['openSessions'];
    if (direct is List) return _asMaps(direct);

    final inner = data['data'];
    if (inner is Map && inner['openSessions'] is List) {
      return _asMaps(inner['openSessions'] as List);
    }
    if (inner is List) return _asMaps(inner);

    return const [];
  }

  static List<Map<String, dynamic>> _asMaps(List raw) => raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  static String _bodyText(Object? data) {
    if (data == null) return '';
    if (data is String) return data;
    return data.toString();
  }
}
