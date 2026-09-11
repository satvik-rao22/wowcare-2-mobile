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

bool isLikelyStaffCode(String value) {
  final t = value.trim();
  if (t.isEmpty) return false;
  if (t.contains(' ')) return false;

  final hasDigit = RegExp(r'\d').hasMatch(t);
  final hasUnderscore = t.contains('_');
  final hasDash = t.contains('-');
  final upperLike = t.toUpperCase() == t && t.toLowerCase() != t;

  if (hasUnderscore) return true;
  if (hasDash && hasDigit) return true;
  if (RegExp(r'^[A-Za-z]{1,4}\d+$').hasMatch(t)) return true;
  if (hasDigit && upperLike) return true;
  return false;
}

String _validStaffDisplayOrEmpty(String value) {
  final t = value.trim();
  if (t.isEmpty) return '';
  if (isPlaceholderActivityAuthor(t)) return '';
  if (isLikelyStaffCode(t)) return '';
  return t;
}

String resolveActivityCreatedByForUi({
  required String rawCreatedBy,
  String? staffLabelFromParameters,
  String? viewerDisplayNameFallback,
}) {
  final raw = _validStaffDisplayOrEmpty(rawCreatedBy);
  if (raw.isNotEmpty) {
    return raw;
  }
  final st = _validStaffDisplayOrEmpty(staffLabelFromParameters ?? '');
  if (st.isNotEmpty) {
    return st;
  }
  final v = _validStaffDisplayOrEmpty(viewerDisplayNameFallback ?? '');
  if (v.isNotEmpty) {
    return v;
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
  if (layoutAsEdit) {
    // Edit/read-only prefers API-only values.
    // IMPORTANT: allow staff codes (e.g. STF_...) here so UI can map code -> name.
    final createdByRaw = activityCreatedBy.trim();
    if (createdByRaw.isNotEmpty && !isPlaceholderActivityAuthor(createdByRaw)) {
      return createdByRaw;
    }
    final paramsRaw = (staffLabelFromParameters ?? '').trim();
    if (paramsRaw.isNotEmpty && !isPlaceholderActivityAuthor(paramsRaw)) {
      return paramsRaw;
    }
    // No staff-present recorded on the activity: show the current logged-in
    // user rather than a blank/"null" field.
    return loggedInDisplayName.trim();
  }
  // Add/create should always show current logged-in staff.
  final u = loggedInDisplayName.trim();
  if (u.isNotEmpty) return u;
  return resolveActivityCreatedByForUi(
    rawCreatedBy: '',
    staffLabelFromParameters: null,
    viewerDisplayNameFallback: loggedInDisplayName,
  );
}

/// When merging two feed cards, keep the most informative author label.
String preferActivityAuthorLabel(String a, String b) {
  final ta = _validStaffDisplayOrEmpty(a);
  final tb = _validStaffDisplayOrEmpty(b);
  if (ta.isNotEmpty) {
    return ta;
  }
  if (tb.isNotEmpty) {
    return tb;
  }
  return 'Staff';
}
