import '../entities/missed_signout.dart';
import '../entities/reg_batch_gate.dart';
import '../entities/reg_batch_result.dart';
import '../entities/reg_edit_input.dart';
import '../entities/reg_page.dart';
import '../entities/reg_raise_input.dart';
import '../entities/regularization_request.dart';

/// Ordering for the two list endpoints.
///
/// The admin's pending queue and the approved history want **opposite** orders,
/// so this is a parameter rather than a constant: §9.5 documents
/// `sort=createdAt,asc` because acting on the longest-waiting request first is
/// right for a work queue, while a history reads newest-first.
enum RegSortOrder {
  /// `createdAt,asc` — oldest first. The pending work queue (§9.5).
  oldestFirst,

  /// `createdAt,desc` — newest first. History and the staff's own list (§9.3).
  newestFirst,
}

extension RegSortOrderX on RegSortOrder {
  /// Value for the API's `sort` query param.
  String get wireValue {
    switch (this) {
      case RegSortOrder.oldestFirst:
        return 'createdAt,asc';
      case RegSortOrder.newestFirst:
        return 'createdAt,desc';
    }
  }
}

/// The module's entire data surface — 9 operations over §9.
///
/// Implementations convert wall-clock school-local times to UTC and attach
/// `timeZone` (§10.1); nothing above this interface deals with timezones.
abstract class RegularizationRepository {
  /// §9.1 — the gate for one staff.
  ///
  /// Returns **at most one** day: §4 reduces each date to its last session and
  /// §5.1 guarantees a staff can never carry more than one unresolved day. The
  /// wire shape is a JSON array, but the domain answer is 0 or 1 — so callers
  /// handle a nullable value instead of each deciding what a second element
  /// would mean.
  Future<MissedSignout?> getOpenSession(String staffCode);

  /// §9.1b — the gate for many staff in one round trip, for bulk sign-in.
  /// A 50-person sign-in would otherwise mean 50 calls to [getOpenSession].
  Future<RegBatchGate> getOpenSessionsBatch(List<String> staffCodes);

  /// §9.2 — raise a request.
  ///
  /// The server decides the resulting status from the **authenticated role**:
  /// staff land `PENDING`, admins are auto-approved and applied immediately
  /// (§8.2b). Read [RegularizationRequest.status] to know which happened
  /// rather than guessing client-side.
  ///
  /// Idempotent (§8.6): if a `PENDING` request already exists for this
  /// `attendanceCode`, that existing request is returned unchanged.
  Future<RegularizationRequest> raise(RegRaiseInput input);

  /// §9.2b — raise many at once (admin only), for the bulk sign-in sheet.
  ///
  /// [sharedReason] applies to every item; an item's own
  /// [RegRaiseInput.reason] overrides it. Items that already have a request
  /// come back under [RegBatchResult.skipped] rather than failing the batch.
  Future<RegBatchResult> raiseBatch(
    List<RegRaiseInput> items, {
    required String sharedReason,
  });

  /// §9.4 — revise a still-`PENDING` request. The module's only correction
  /// path; there is no cancel (§8.4).
  ///
  /// Throws once the request is `APPROVED` (`409`) — approval is terminal
  /// (§8.6). An edit that races an approval loses, and the caller must surface
  /// that rather than showing a silent no-op (§10.3).
  Future<RegularizationRequest> edit(RegEditInput input);

  /// §9.3 — the staff's own requests. [status] `null` means all.
  Future<RegPage<RegularizationRequest>> getMyRequests({
    required String staffCode,
    RegStatus? status,
    int page = 0,
    int size = 20,
    RegSortOrder sort = RegSortOrder.newestFirst,
  });

  /// §9.5 — the school's requests: the admin's pending queue **and** its
  /// approved history, from the same endpoint.
  ///
  /// [status] `null` means all. Pair `PENDING` with
  /// [RegSortOrder.oldestFirst] for the queue and history with
  /// [RegSortOrder.newestFirst].
  Future<RegPage<RegularizationRequest>> getSchoolRequests({
    required String schoolCode,
    RegStatus? status,
    int page = 0,
    int size = 10,
    RegSortOrder sort = RegSortOrder.oldestFirst,
  });

  /// §9.6 — approve one request, optionally modifying the time.
  ///
  /// [signOutLocal] `null` approves as submitted; supplying it makes that the
  /// `approvedSignOutTime` while the original stays in
  /// [RegularizationRequest.requestedSignOutTime] (§7.4).
  ///
  /// Idempotent (§8.6): approving an already-approved request returns current
  /// state.
  Future<RegularizationRequest> approve(
    String code, {
    DateTime? signOutLocal,
    String note = '',
  });

  /// §9.7 — approve a chosen set, each as submitted.
  ///
  /// [codes] is required; there is deliberately no "approve all pending".
  /// Already-decided items come back under [RegBatchResult.skipped].
  Future<RegBatchResult> approveSelected(List<String> codes);
}
