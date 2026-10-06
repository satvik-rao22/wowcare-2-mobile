import '../entities/reg_batch_gate.dart';
import '../entities/reg_batch_result.dart';
import '../entities/reg_edit_input.dart';
import '../entities/reg_page.dart';
import '../entities/reg_raise_input.dart';
import '../entities/regularization_request.dart';

/// `createdAt` ordering. A pending queue reads oldest-first — act on the
/// longest-waiting request — while history reads newest-first.
enum RegSortOrder { oldestFirst, newestFirst }

extension RegSortOrderX on RegSortOrder {
  String get wireValue =>
      this == RegSortOrder.oldestFirst ? 'createdAt,asc' : 'createdAt,desc';
}

/// The seven endpoints. Three serve both personas through one call.
abstract class RegularizationRepository {
  /// `staffCodes` null checks the caller; a list checks that roster.
  Future<RegBatchGate> checkGate({List<String>? staffCodes});

  /// Staff land `PENDING`; an admin is the approver, so theirs is applied.
  /// Read the response `status` rather than guessing from the caller's role.
  ///
  /// Idempotent: a second raise for the same row returns the existing request.
  Future<RegularizationRequest> raise(RegRaiseInput input, {String method});

  /// Admin only. Every item created and applied.
  Future<RegBatchResult> raiseBatch(
    List<RegRaiseInput> items, {
    required String sharedReason,
  });

  /// Own rows for staff, the whole school for an admin. `staffCode` filters,
  /// and is a 403 for a staff member naming anyone else.
  Future<RegPage<RegularizationRequest>> getRequests({
    String? staffCode,
    RegStatus? status,
    int page = 0,
    int size = 20,
    RegSortOrder sort = RegSortOrder.newestFirst,

    /// Inclusive attendance-date window, school-local. Sent as
    /// `fromAttendanceDate`/`toAttendanceDate`; the server filters on it.
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Omitting [signOutLocal] approves as submitted. Idempotent.
  Future<RegularizationRequest> approve(
    String code, {
    DateTime? signOutLocal,
    String note = '',
  });

  Future<RegBatchResult> approveSelected(List<String> codes);

  /// The raiser only, and only while pending. Throws
  /// [RegAlreadyApprovedException] once approved.
  Future<RegularizationRequest> edit(RegEditInput input);
}
