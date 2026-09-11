/// The `communication-settings` values that decide whether Delete shows on a
/// message — see `MessageBubble.isAdminCanDeleteAny` /
/// `MessageBubble.deleteTimeLimitMinutes`. A pure value object (Mandate 3: the
/// authorization rule lives in the domain layer). Resolving it from settings is
/// [ResolveMessageDeletePermissionUseCase]'s job.
class MessageDeletePermission {
  const MessageDeletePermission({
    required this.isAdminCanDeleteAny,
    required this.deleteTimeLimitMinutes,
  });

  final bool isAdminCanDeleteAny;
  final int? deleteTimeLimitMinutes;

  /// Today's behaviour before this setting existed: only the sender can delete
  /// their own message, with no time limit. Used both as the pre-fetch default
  /// and the fallback on any error, so a network hiccup can't silently take
  /// away a user's ability to delete their own message.
  static const none = MessageDeletePermission(
    isAdminCanDeleteAny: false,
    deleteTimeLimitMinutes: null,
  );
}
