/// Works out which identity props a messaging avatar should hand
/// `ProfileAvatar` so it can resolve a real profile photo.
///
/// The conversation participant payload carries neither `avatarUrl` nor
/// `staffCode` for most people (see `ParticipantEntityDto` — both are parsed
/// defensively but "not currently sent by the backend"), so every messaging
/// surface that only forwarded those two fields fell back to initials. The
/// account code (`USR_*`) is always present, and `ProfileAvatar` can map
/// it to a `STF_*` code and resolve the photo from there — the same path the
/// staff-messaging inbox rows already use.
///
/// Guardians have no staff mapping, so their account code is never forwarded:
/// it would only cost a lookup that can't succeed.
class ParticipantAvatarSource {
  const ParticipantAvatarSource({
    this.imageUrl,
    this.mediaAssetCode,
    this.staffCode,
    this.userCode,
  });

  /// `avatarUrl` when it's already a resolved `http(s)` URL.
  final String? imageUrl;

  /// `avatarUrl` when it's a raw media-asset code rather than a URL.
  final String? mediaAssetCode;

  /// `STF_*`, when the payload actually carried one.
  final String? staffCode;

  /// `USR_*` — only set for staff-side personas with no [staffCode], as the
  /// last resort the widget maps to a staff code itself.
  final String? userCode;

  /// [role] is the participant's role in any of the forms the backend sends
  /// (`ADMIN`, `TEACHER`, `GUARDIAN`, …); pass null when the caller genuinely
  /// doesn't know it, which allows the account-code fallback.
  factory ParticipantAvatarSource.of({
    String? avatarUrl,
    String? staffCode,
    String? userCode,
    String? role,
  }) {
    final avatar = (avatarUrl ?? '').trim();
    final staff = (staffCode ?? '').trim();
    final user = (userCode ?? '').trim();
    final isUrl = avatar.startsWith('http');
    return ParticipantAvatarSource(
      imageUrl: isUrl ? avatar : null,
      mediaAssetCode: (!isUrl && avatar.isNotEmpty) ? avatar : null,
      staffCode: staff.isNotEmpty ? staff : null,
      userCode: (staff.isEmpty && user.isNotEmpty && isStaffSideRole(role))
          ? user
          : null,
    );
  }

  /// True for every persona that can have a staff profile photo — i.e.
  /// anything that isn't a guardian. Deliberately an exclusion rather than an
  /// allow-list of designations: the backend sends granular role codes
  /// (`LEAD_TEACHER`, `ASSISTANT_DIRECTOR`, `OWNER`, …) that an allow-list
  /// keeps missing.
  static bool isStaffSideRole(String? role) {
    final r = (role ?? '').trim().toUpperCase();
    if (r.isEmpty) return true;
    return !r.contains('GUARDIAN') && !r.contains('PARENT');
  }
}
