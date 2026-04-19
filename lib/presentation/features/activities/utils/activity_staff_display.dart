/// API sometimes returns [createdBy] as "system" or empty; prefer staff from
/// activity parameters, then the logged-in user's display name for UI.
bool isPlaceholderActivityAuthor(String value) {
  final t = value.trim().toLowerCase();
  if (t.isEmpty) return true;
  return t == 'system' ||
      t == 'null' ||
      t == 'n/a' ||
      t == 'na' ||
      t == 'unknown' ||
      t == '—' ||
      t == '-';
}

String resolveActivityCreatedByForUi({
  required String rawCreatedBy,
  String? staffLabelFromParameters,
  String? viewerDisplayNameFallback,
}) {
  final raw = rawCreatedBy.trim();
  if (raw.isNotEmpty && !isPlaceholderActivityAuthor(raw)) {
    return raw;
  }
  final st = (staffLabelFromParameters ?? '').trim();
  if (st.isNotEmpty && !isPlaceholderActivityAuthor(st)) {
    return st;
  }
  final v = (viewerDisplayNameFallback ?? '').trim();
  if (v.isNotEmpty) {
    return v;
  }
  if (raw.isNotEmpty) {
    return raw;
  }
  return 'Staff';
}

/// Label for [StaffPresentWidget] on add vs edit/read-only flows.
String staffPresentLabelForActivity({
  required bool layoutAsEdit,
  required String activityCreatedBy,
  required String loggedInDisplayName,
  String? staffLabelFromParameters,
}) {
  if (!layoutAsEdit) {
    final u = loggedInDisplayName.trim();
    if (u.isNotEmpty) {
      return u;
    }
    return resolveActivityCreatedByForUi(
      rawCreatedBy: activityCreatedBy,
      staffLabelFromParameters: staffLabelFromParameters,
      viewerDisplayNameFallback: null,
    );
  }
  return resolveActivityCreatedByForUi(
    rawCreatedBy: activityCreatedBy,
    staffLabelFromParameters: staffLabelFromParameters,
    viewerDisplayNameFallback: loggedInDisplayName,
  );
}

/// When merging two feed cards, keep the most informative author label.
String preferActivityAuthorLabel(String a, String b) {
  final ta = a.trim();
  final tb = b.trim();
  if (ta.isNotEmpty && !isPlaceholderActivityAuthor(ta)) {
    return ta;
  }
  if (tb.isNotEmpty && !isPlaceholderActivityAuthor(tb)) {
    return tb;
  }
  if (ta.isNotEmpty) {
    return ta;
  }
  if (tb.isNotEmpty) {
    return tb;
  }
  return 'Staff';
}
