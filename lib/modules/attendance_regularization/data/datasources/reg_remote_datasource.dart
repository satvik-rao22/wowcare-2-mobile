/// The seam that makes this module buildable before the API exists.
///
/// Two implementations — `RegHttpDataSource` (real Dio) and
/// `RegMockDataSource` (stateful, in-memory) — and **one line** in
/// `regularization_di.dart` chooses between them. Nothing above this interface
/// knows which is behind it, so the cutover touches no other file and the mock
/// can then be deleted outright.
///
/// Methods return the **raw response body**, not entities, deliberately: the
/// mock therefore produces the same JSON the server will, which means
/// `RegMappers` is exercised on the mock path too. Mapping bugs surface during
/// development rather than on cutover day.
///
/// There are 8 methods for 9 operations because §9.3 (staff list) and §9.5
/// (admin list) are the same endpoint with different query parameters.
abstract class RegRemoteDataSource {
  /// §9.1 — `GET /open-sessions?staffCode=`
  Future<Map<String, dynamic>> getOpenSessions({required String staffCode});

  /// §9.1b — `POST /open-sessions/batch`
  Future<Map<String, dynamic>> getOpenSessionsBatch({
    required Map<String, dynamic> body,
  });

  /// §9.2 — `POST /`
  Future<Map<String, dynamic>> raise({required Map<String, dynamic> body});

  /// §9.2b — `POST /raise-batch`
  Future<Map<String, dynamic>> raiseBatch({
    required Map<String, dynamic> body,
  });

  /// §9.4 — `PATCH /{code}`. Throws on `409` once the request is approved.
  Future<Map<String, dynamic>> edit({
    required String code,
    required Map<String, dynamic> body,
  });

  /// §9.3 / §9.5 — `GET /` with `staffCode` or `schoolCode` plus filters.
  Future<Map<String, dynamic>> list({
    required Map<String, dynamic> query,
  });

  /// §9.6 — `POST /{code}/approve`
  Future<Map<String, dynamic>> approve({
    required String code,
    required Map<String, dynamic> body,
  });

  /// §9.7 — `POST /approve-selected`
  Future<Map<String, dynamic>> approveSelected({
    required Map<String, dynamic> body,
  });
}
