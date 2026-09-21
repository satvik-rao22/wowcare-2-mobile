/// How a correction reached the server.
abstract final class RegMethod {
  const RegMethod._();

  static const String app = 'APP';
  static const String web = 'WEB';
  static const String kiosk = 'KIOSK';
}

abstract final class RegConfig {
  const RegConfig._();

  static const int inboxPageSize = 20;
  static const int myRequestsPageSize = 20;
  static const String method = RegMethod.app;

  /// Check before a single sign-in rather than relying on the server's
  /// `409 REGULARIZATION_REQUIRED` alone. Costs a round trip; puts the sheet in
  /// front of the user before anything is attempted.
  static bool preCheckSingleSignIn = true;

  /// Check the roster before signing anyone in, so the admin sees the
  /// consequence first and *Skip* genuinely skips. When false, the server's
  /// `{signedIn, blocked}` response drives the sheet instead.
  static bool preCheckBulkSignIn = true;

  /// The gate must never be why attendance is slow — past this, the sign-in
  /// proceeds and the server's guard holds the line.
  static const Duration gateCheckTimeout = Duration(seconds: 8);
}
