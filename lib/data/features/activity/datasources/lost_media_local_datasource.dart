import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';

/// The single place `ImagePicker.retrieveLostData()` is called.
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
  /// [picker] is injectable for tests; it defaults here rather than being
  /// supplied by the composition root so `di.dart` does not have to import the
  /// picker plugin to wire this up.
  ImagePickerLostMediaLocalDataSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<RecoveredMedia> retrieveLostMedia() async {
    // Android-only by contract, and short-circuited here rather than relying on
    // the iOS implementation happening to return empty. Keeping the guard in
    // the data layer means the platform check lives next to the platform call
    // instead of being restated by every caller — and it makes the method a
    // genuine zero-cost no-op on iOS/web rather than a channel round-trip on
    // every screen open.
    if (kIsWeb || !Platform.isAndroid) return RecoveredMedia.none;

    final response = await _picker.retrieveLostData();

    if (response.isEmpty) return RecoveredMedia.none;

    // The platform cached a failure rather than a file (e.g. the camera app
    // crashed). There is nothing to hand back, but say why.
    final exception = response.exception;
    if (exception != null) {
      return RecoveredMedia(
        type: _mapType(response.type),
        filePaths: const <String>[],
        errorMessage: exception.message ?? exception.code,
      );
    }

    // `files` covers the multi-image pick; `file` the single one. Prefer
    // `files` and fall back, rather than reading only `file` and silently
    // dropping the rest of a recovered multi-selection.
    final recovered = <String>[
      ...?response.files?.map((f) => f.path),
    ];
    if (recovered.isEmpty && response.file != null) {
      recovered.add(response.file!.path);
    }
    if (recovered.isEmpty) return RecoveredMedia.none;

    return RecoveredMedia(
      type: _mapType(response.type),
      filePaths: recovered,
    );
  }

  /// `RetrieveType.video` maps to video; everything else (including a null
  /// type, which the platform can report alongside an exception) is treated as
  /// an image — matching the picker's own default.
  RecoveredMediaType _mapType(RetrieveType? type) => type == RetrieveType.video
      ? RecoveredMediaType.video
      : RecoveredMediaType.image;
}
