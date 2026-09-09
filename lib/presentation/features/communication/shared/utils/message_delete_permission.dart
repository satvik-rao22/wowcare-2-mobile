import 'package:wowcare/app/di/messaging_resolvers.dart';

/// Resolves the `communication-settings` values [MessageBubble] needs to
/// decide whether Delete shows on a message — see
/// [MessageBubble.isAdminCanDeleteAny] / [MessageBubble.deleteTimeLimitMinutes].
class MessageDeletePermission {
  const MessageDeletePermission({
    required this.isAdminCanDeleteAny,
    required this.deleteTimeLimitMinutes,
  });

  final bool isAdminCanDeleteAny;
  final int? deleteTimeLimitMinutes;

  /// Today's behaviour before this setting existed: only the sender can
  /// delete their own message, with no time limit. Used both as the
  /// pre-fetch default and the fallback on any error, so a network hiccup
  /// can't silently take away a user's ability to delete their own message.
  static const none = MessageDeletePermission(
    isAdminCanDeleteAny: false,
    deleteTimeLimitMinutes: null,
  );

  /// [isAdminViewer] is the CURRENT viewer's persona (not the message
  /// sender's) — only relevant when the school's `adminCanDeleteAny` is on.
  static Future<MessageDeletePermission> resolve({
    required String schoolCode,
    required bool isAdminViewer,
  }) async {
    final code = schoolCode.trim();
    if (code.isEmpty) return none;
    try {
      final result = await resolveGetCommunicationSettingsUseCase()(
        code,
      );
      return result.fold(
        (_) => none,
        (settings) => MessageDeletePermission(
          isAdminCanDeleteAny: isAdminViewer && settings.adminCanDeleteAny,
          deleteTimeLimitMinutes: settings.deleteTimeLimitMinutes,
        ),
      );
    } catch (_) {
      return none;
    }
  }
}
