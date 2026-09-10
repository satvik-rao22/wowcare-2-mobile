import 'package:flutter/services.dart' show PlatformException;
import 'package:wowcare/presentation/features/activities/activity_media_strings.dart';

/// How a picker failure should be treated.
enum MediaPickerErrorKind {
  /// The user backed out. Not an error: no message, no crash report.
  cancellation,

  /// The user (or device policy) refused access. Worth a message that says how
  /// to fix it, and a non-fatal report so refusal rates are visible — but it is
  /// not a defect.
  permission,

  /// Something actually went wrong. Message plus a non-fatal report with the
  /// platform code attached.
  failure,
}

/// Classifies a picker exception and picks the sentence the user sees.
///
/// Exists so the two entry points ([_pickVideo], [_pickPhotos]) cannot drift
/// apart on wording or on which codes count as a refusal, and so the mapping is
/// testable without a platform channel.
class MediaPickerError {
  const MediaPickerError({
    required this.kind,
    required this.message,
    required this.code,
  });

  final MediaPickerErrorKind kind;

  /// The sentence to show. Empty for [MediaPickerErrorKind.cancellation].
  final String message;

  /// The platform error code, or `unknown`. Safe for a breadcrumb: it is a
  /// fixed vocabulary from the plugin, never user text.
  final String code;

  /// Whether this warrants a Crashlytics report. Cancellation never does.
  bool get shouldReport => kind != MediaPickerErrorKind.cancellation;

  /// `already_active` means a picker is genuinely mid-flight; the user has not
  /// lost anything, so it is not classed as a failure.
  static const Set<String> _permissionCodes = <String>{
    'camera_access_denied',
    'photo_access_denied',
  };

  static const Set<String> _restrictedCodes = <String>{
    'camera_access_restricted',
    'photo_access_restricted',
  };

  /// Maps [error] to a kind and a message.
  ///
  /// [isCamera] selects camera- vs library-flavoured wording for the codes that
  /// are shared between the two sources, and [isVideo] between the video and
  /// photo entry points.
  factory MediaPickerError.from(
    Object error, {
    required bool isCamera,
    required bool isVideo,
  }) {
    if (error is! PlatformException) {
      return MediaPickerError(
        kind: MediaPickerErrorKind.failure,
        message: isCamera
            ? ActivityMediaStrings.cameraUnavailable
            : ActivityMediaStrings.videoSourceUnavailable,
        code: 'unknown',
      );
    }

    final code = error.code.trim();

    if (_permissionCodes.contains(code)) {
      return MediaPickerError(
        kind: MediaPickerErrorKind.permission,
        message: code == 'camera_access_denied'
            ? ActivityMediaStrings.cameraPermissionDenied
            : ActivityMediaStrings.photoPermissionDenied,
        code: code,
      );
    }

    if (_restrictedCodes.contains(code)) {
      // Device policy (parental controls, MDM), not something the user can
      // grant — so the wording must not tell them to open Settings.
      return MediaPickerError(
        kind: MediaPickerErrorKind.permission,
        message: code == 'camera_access_restricted'
            ? ActivityMediaStrings.cameraPermissionRestricted
            : ActivityMediaStrings.photoPermissionRestricted,
        code: code,
      );
    }

    switch (code) {
      case 'no_available_camera':
        return MediaPickerError(
          kind: MediaPickerErrorKind.failure,
          message: ActivityMediaStrings.noCameraAvailable,
          code: code,
        );
      case 'already_active':
      case 'multiple_request':
        return MediaPickerError(
          kind: MediaPickerErrorKind.failure,
          message: ActivityMediaStrings.pickerAlreadyOpen,
          code: code,
        );
      // The capture happened but the result could not be read back or copied
      // out — a storage/URI failure, not a camera one, so the message says
      // "recording" rather than "camera".
      case 'no_valid_video_uri':
      case 'no_valid_image_uri':
      case 'no_valid_media_uri':
      case 'invalid_image':
      case 'invalid_source':
      case 'invalid_result':
      case 'create_error':
      case 'video_error':
      case 'flutter_image_picker_copy_video_error':
        return MediaPickerError(
          kind: MediaPickerErrorKind.failure,
          message: isCamera
              ? ActivityMediaStrings.captureUnreadable
              : (isVideo
                    ? ActivityMediaStrings.videoUnreadable
                    : ActivityMediaStrings.unsupportedImageFormat),
          code: code,
        );
      default:
        return MediaPickerError(
          kind: MediaPickerErrorKind.failure,
          message: isCamera
              ? ActivityMediaStrings.cameraUnavailable
              : ActivityMediaStrings.videoSourceUnavailable,
          code: code.isEmpty ? 'unknown' : code,
        );
    }
  }
}
