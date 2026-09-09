/// Which datasource backs the module.
enum RegSource {
  /// In-memory [RegMockDataSource] — the whole feature runs, and is
  /// demoable, before any endpoint exists.
  mock,

  /// Real HTTP via the host app's Dio.
  live,
}

/// Module-level knobs.
///
/// [source] is the **only** switch between mock and real data. It is read once,
/// in `regularization_di.dart`; no repository, cubit, screen or widget ever
/// looks at it. That is what makes the cutover a one-line change and lets
/// `reg_mock_datasource.dart` be deleted afterwards without touching anything
/// else.
abstract final class RegConfig {
  const RegConfig._();

  /// Flip to [RegSource.live] when the endpoints ship.
  static RegSource source = RegSource.mock;

  /// Admin inbox page size — matches the server default for
  /// `/staff-overtime-records/profile` (spec §9.5).
  static const int inboxPageSize = 10;

  /// Staff "my requests" page size (spec §9.3).
  static const int myRequestsPageSize = 20;

  /// Recorded as the raise `method` when submitted from the app (spec §9.2).
  static const String method = 'APP';

  /// Whether a **single** sign-in is pre-checked with `GET /open-sessions`
  /// before the request goes out (§9.1).
  ///
  /// Keep it `true` while BE-5 is outstanding — it is the only thing enforcing
  /// the gate. Once the server returns `409 REGULARIZATION_REQUIRED`, this can
  /// go `false` to save a round trip on every sign-in: the `onError` backstop
  /// then opens the same sheet from the 409 payload.
  ///
  /// Bulk sign-in always pre-checks, regardless — it needs the blocked/clear
  /// split to know who it may sign in (§9.1b).
  static bool preCheckSingleSignIn = true;

  /// Artificial latency for the mock, so loading states are visible while
  /// developing against it. Ignored by the live datasource.
  static Duration mockLatency = const Duration(milliseconds: 350);
}
