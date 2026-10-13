import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';

/// Recovers a capture lost to Android killing the app (the plugin call itself
/// lives in FilePickerUtils.recoverLostMedia).
///
/// `retrieveLostData` is Android-only in effect: the Android implementation
/// caches a completed capture whose activity died before the result could be
/// delivered, and hands it back on the next call. The iOS implementation has no
/// such loss mode and always reports an empty response, so this is a no-op
/// there rather than something the caller has to branch on.
abstract class LostMediaLocalDataSource {
  Future<RecoveredMedia> retrieveLostMedia();
}

class ImagePickerLostMediaLocalDataSource implements LostMediaLocalDataSource {
  @override
  Future<RecoveredMedia> retrieveLostMedia() async {
    // Android-only by contract, and short-circuited here rather than relying on
    // the iOS implementation happening to return empty. Keeping the guard in
    // the data layer means the platform check lives next to the platform call
    // instead of being restated by every caller — and it makes the method a
    // genuine zero-cost no-op on iOS/web rather than a channel round-trip on
    // every screen open.
    if (kIsWeb || !Platform.isAndroid) return RecoveredMedia.none;

    final lost = await FilePickerUtils.recoverLostMedia();
    if (lost == null) return RecoveredMedia.none;

    final type = lost.isVideo
        ? RecoveredMediaType.video
        : RecoveredMediaType.image;
    // The platform cached a failure rather than a file (e.g. the camera app
    // crashed). There is nothing to hand back, but say why.
    if (lost.error != null) {
      return RecoveredMedia(
        type: type,
        filePaths: const <String>[],
        errorMessage: lost.error,
      );
    }
    return RecoveredMedia(type: type, filePaths: lost.paths);
  }
}
