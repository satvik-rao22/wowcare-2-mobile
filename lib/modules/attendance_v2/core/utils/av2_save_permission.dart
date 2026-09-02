import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Outcome of asking for permission to save a file to device storage.
enum Av2SavePermission { granted, denied, permanentlyDenied }

/// Centralises the "can we save a file?" check for the export feature.
///
/// The export saves through the system "Save to Files" dialog (Android Storage
/// Access Framework / iOS document picker). That mechanism needs **no** runtime
/// permission on iOS or on Android 10+ (API 29+, scoped storage). The legacy
/// `WRITE_EXTERNAL_STORAGE` permission only applies to Android 9 and below
/// (and our manifest caps it at `maxSdkVersion=29`), so we only request it
/// there. On everything else we return [granted] immediately — requesting a
/// permission the OS no longer recognises would falsely come back denied and
/// block a save that actually works.
///
/// Never throws; logs and falls back to [granted] on any unexpected error.
class Av2SavePermissionHelper {
  const Av2SavePermissionHelper._();

  static Future<Av2SavePermission> ensure() async {
    if (!Platform.isAndroid) return Av2SavePermission.granted;

    try {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      AppLogger.d('[AV2-EXPORT] android sdkInt=$sdkInt');

      // Android 10+ uses scoped storage / SAF — no permission needed.
      if (sdkInt >= 29) return Av2SavePermission.granted;

      var status = await Permission.storage.status;
      AppLogger.d('[AV2-EXPORT] storage permission status: $status');
      if (status.isGranted) return Av2SavePermission.granted;
      if (status.isPermanentlyDenied) {
        return Av2SavePermission.permanentlyDenied;
      }

      status = await Permission.storage.request();
      AppLogger.d('[AV2-EXPORT] storage permission after request: $status');
      if (status.isGranted) return Av2SavePermission.granted;
      if (status.isPermanentlyDenied) {
        return Av2SavePermission.permanentlyDenied;
      }
      return Av2SavePermission.denied;
    } catch (e, s) {
      AppLogger.w('[AV2-EXPORT] storage permission check failed: $e\n$s');
      // Don't block — the SAF save dialog may still work without it.
      return Av2SavePermission.granted;
    }
  }
}
