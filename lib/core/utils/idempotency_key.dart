import 'package:uuid/uuid.dart';

/// Generates opaque idempotency keys for mutating attendance requests.
///
/// The key is sent as the `Idempotency-Key` header so the backend can dedupe a
/// retried/replayed POST (a user double-tap, a manual retry after a failure, or
/// the automatic 401-refresh replay in [SessionExpiredInterceptor], which reuses
/// the same RequestOptions and therefore the same header). A submit cubit
/// generates ONE key per logical submission and keeps it stable across retries,
/// rotating it only after a successful result.
class IdempotencyKey {
  const IdempotencyKey._();

  static const Uuid _uuid = Uuid();

  /// HTTP header name for the idempotency key.
  static const String headerName = 'Idempotency-Key';

  /// A fresh v4 (random) idempotency key.
  static String generate() => _uuid.v4();
}
