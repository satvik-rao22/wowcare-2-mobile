/// Shared field-aliasing helpers for activity API responses.
///
/// Declared once so a new alias is added in one place instead of being
/// re-derived (or forgotten) independently in every model that reads the
/// same field. `approvalStatus` moved to this key on newer endpoints; older
/// ones still send `status` for the same concept.
String resolveActivityApprovalStatusAlias(Map<String, dynamic> json) {
  return (json['approvalStatus'] ?? json['status'] ?? '').toString().trim();
}
