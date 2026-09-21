import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';

/// Blocks navigation when a notification/deep-link was generated for a
/// DIFFERENT account than whoever is currently logged in on this device.
///
/// Real FCM pushes never carry [PushNotification.userCode] (a push only ever
/// reaches the device token it targeted), so this is a no-op for every
/// existing push flow. Email action-button links, however, can be opened on
/// any device — a shared/family tablet, or a forwarded email — so without
/// this check the app would silently render one person's invoice/incident
/// under whoever else happens to be logged in.
///
/// Returns `true` when navigation was blocked (an error was already shown);
/// the caller must not proceed with any school-switch or redirect in that case.
Future<bool> blockIfWrongAccount(PushNotification n) async {
  final linkUserCode = (n.userCode ?? '').trim();
  if (linkUserCode.isEmpty) return false;

  final storage = serviceLocator<StorageService>();
  final myUserCode = (await storage.getString(StorageKeys.userCode) ?? '')
      .trim();
  if (myUserCode.isEmpty || myUserCode == linkUserCode) return false;

  AppLogger.d(
    '[FCM] Link userCode ($linkUserCode) does not match the logged-in '
    'account ($myUserCode) — blocking navigation.',
  );
  final ctx = CoreUtils.rootNavigatorKey.currentContext;
  if (ctx != null && ctx.mounted) {
    CoreUtils.showTopSnackBar(
      context: ctx,
      message:
          'This link is for a different account. Please sign out and sign '
          'in as the correct user to continue.',
      isError: true,
    );
  }
  return true;
}
