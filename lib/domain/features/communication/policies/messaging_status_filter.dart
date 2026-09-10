/// How the Staff Messaging inbox's "Status" filter maps onto the backend's
/// conversation query, and onto the client-side re-check that keeps the
/// realtime (Firestore) merge from undoing it.
///
/// For a STAFF_DIRECT conversation the filter means the COUNTERPART'S
/// EMPLOYMENT status, which the conversation's own `status` cannot express:
/// an upcoming staff member's conversation is itself `ACTIVE`, so a query
/// (or a client-side check) that looks only at `status` returns active AND
/// upcoming staff together — which is what the inbox did on landing.
/// `staffStatuses` is the only param that narrows by employment status.
///
/// `INACTIVE` is the one exception and stays on the conversation-level
/// `status`: `status=INACTIVE&staffStatuses=INACTIVE` returns EMPTY from the
/// backend, while `status=INACTIVE` alone returns the expected conversations.
class MessagingStatusFilter {
  MessagingStatusFilter._();

  static const String active = 'ACTIVE';
  static const String upcoming = 'UPCOMING';
  static const String inactive = 'INACTIVE';

  /// The picked status, normalised. No selection means the inbox default —
  /// `ACTIVE` — never "every status".
  static String selection(String? selected) {
    final normalized = selected?.trim().toUpperCase() ?? '';
    return normalized.isEmpty ? active : normalized;
  }

  /// The conversation-level `status` query param.
  static String conversationStatus(String? selected) =>
      selection(selected) == inactive ? inactive : active;

  /// The `staffStatuses` query param — empty for `INACTIVE` (see the class
  /// doc), a single-entry list otherwise.
  static List<String> staffStatuses(String? selected) {
    final picked = selection(selected);
    return picked == inactive ? const [] : <String>[picked];
  }

  /// Whether a STAFF_DIRECT conversation belongs in the list under
  /// [selected]. Applied on top of the server-side params above because the
  /// inbox's Firestore subscription keeps merging updates into the loaded
  /// list; without this the next realtime snapshot silently reverts the list
  /// to unfiltered.
  ///
  /// [counterpartStaffStatus] is the OTHER participant's employment status.
  /// Fails OPEN when it is null (not every backend build sends it) — only a
  /// known, non-matching status hides a conversation.
  static bool matches({
    String? selected,
    required String conversationStatus,
    String? counterpartStaffStatus,
  }) {
    final picked = selection(selected);
    final convStatus = conversationStatus.trim().toUpperCase();
    if (picked == inactive) return convStatus == inactive;
    if (convStatus != active) return false;

    final staffStatus = counterpartStaffStatus?.trim().toUpperCase();
    if (staffStatus == null || staffStatus.isEmpty) return true;
    return staffStatus == picked;
  }
}
