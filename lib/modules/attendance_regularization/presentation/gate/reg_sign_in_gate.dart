import 'reg_gate_outcome.dart';

/// The narrow contract the sign-in interceptor depends on.
///
/// [RegGateCoordinator] implements it, but the interceptor is typed to this
/// instead of the concrete class for two reasons: it states exactly which
/// three things the network layer is allowed to ask of the gate, and it makes
/// the interceptor unit-testable — a fake here needs no widgets, no navigator
/// and no datasource.
abstract class RegSignInGate {
  /// Gate one staff. [byAdmin] is derived from the sign-in URL, never a
  /// client flag, so it cannot disagree with the role the server sees.
  Future<RegGateOutcome> guardSingle(
    String staffCode, {
    required bool byAdmin,
    String staffName,
  });

  /// Gate many staff, returning who may be signed in now (§9.1b, §5.1c).
  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes);

  /// Handle a `409 REGULARIZATION_REQUIRED`; true means retry the sign-in.
  Future<bool> handleConflict(
    Object error, {
    required bool byAdmin,
    String staffCode,
  });
}
