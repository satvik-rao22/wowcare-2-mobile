import 'package:wowcare/domain/features/communication/policies/message_delete_permission.dart';
import 'package:wowcare/domain/features/communication/usecases/get_communication_settings_usecase.dart';

/// Resolves the [MessageDeletePermission] for a school from its
/// communication-settings, applying the current viewer's persona. Falls back to
/// [MessageDeletePermission.none] on empty school code or any error, so a
/// network hiccup never removes a user's ability to delete their own message.
class ResolveMessageDeletePermissionUseCase {
  ResolveMessageDeletePermissionUseCase(this._getCommunicationSettings);

  final GetCommunicationSettingsUseCase _getCommunicationSettings;

  /// [isAdminViewer] is the CURRENT viewer's persona (not the message
  /// sender's) — only relevant when the school's `adminCanDeleteAny` is on.
  Future<MessageDeletePermission> call({
    required String schoolCode,
    required bool isAdminViewer,
  }) async {
    final code = schoolCode.trim();
    if (code.isEmpty) return MessageDeletePermission.none;
    try {
      final result = await _getCommunicationSettings(code);
      return result.fold(
        (_) => MessageDeletePermission.none,
        (settings) => MessageDeletePermission(
          isAdminCanDeleteAny: isAdminViewer && settings.adminCanDeleteAny,
          deleteTimeLimitMinutes: settings.deleteTimeLimitMinutes,
        ),
      );
    } catch (_) {
      return MessageDeletePermission.none;
    }
  }
}
