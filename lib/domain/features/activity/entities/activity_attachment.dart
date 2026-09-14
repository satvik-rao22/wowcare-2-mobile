import 'package:equatable/equatable.dart';

/// Typed model for an OUTBOUND activity attachment row, used when building the
/// CREATE and SHARED-create request payloads.
///
/// Replaces the raw `List<Map<String, dynamic>>` the photo/incident Views used
/// to build by hand. The maps had exactly two shapes:
///
///  * SHARED:       `{'assetCode': code}`
///  * PER_STUDENT:  `{'assetCode': code, 'studentCode': owner, 'bindingMode': mode}`
///
/// [toPayload] reproduces both shapes key-for-key: [studentCode] and
/// [bindingMode] are null/absent for the SHARED shape and are conditionally
/// omitted exactly as the old Map literals were, so the JSON on the wire stays
/// byte-for-byte identical.
///
/// Scope note: this is the OUTBOUND create payload only. The UPDATE/PATCH path
/// works on rich server RESPONSE rows and stays `Map<String, dynamic>` — call
/// [toPayload] at those sites to feed the Map-based merge helpers.
class ActivityAttachment extends Equatable {
  const ActivityAttachment({
    required this.assetCode,
    this.studentCode,
    this.bindingMode,
  });

  final String assetCode;
  final String? studentCode; // null/absent for SHARED
  final String? bindingMode; // null/absent for SHARED

  /// Reproduces the exact Map the old code built: `assetCode` is always
  /// present; `studentCode` and `bindingMode` are included only when non-null
  /// AND non-empty, matching the prior SHARED-vs-PER_STUDENT branch.
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'assetCode': assetCode,
    if ((studentCode ?? '').isNotEmpty) 'studentCode': studentCode,
    if ((bindingMode ?? '').isNotEmpty) 'bindingMode': bindingMode,
  };

  @override
  List<Object?> get props => [assetCode, studentCode, bindingMode];
}
