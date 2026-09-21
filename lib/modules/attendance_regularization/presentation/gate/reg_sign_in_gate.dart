import 'reg_gate_outcome.dart';

/// What the sign-in interceptor may ask of the gate. Narrow on purpose: it
/// states the network layer's whole surface, and a fake needs no widgets,
/// navigator or datasource.
abstract class RegSignInGate {
  Future<RegGateOutcome> guardSingle(
    String staffCode, {
    required bool byAdmin,
    String staffName,
  });

  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes);

  /// True means retry the sign-in.
  Future<bool> handleConflict(
    Object error, {
    required bool byAdmin,
    String staffCode,
  });

  /// The `blocked` entries a sign-in response came back with. Returns the staff
  /// codes now cleared, so the caller can sign just those in.
  Future<List<String>> resolveBlocked(
    List<Map<String, dynamic>> blocked, {
    required bool byAdmin,
  });
}
