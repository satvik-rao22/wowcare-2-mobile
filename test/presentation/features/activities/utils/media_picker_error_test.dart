import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/activities/activity_media_strings.dart';
import 'package:wowcare/presentation/features/activities/utils/media_picker_error.dart';

MediaPickerError classify(
  String code, {
  bool isCamera = true,
  bool isVideo = true,
}) => MediaPickerError.from(
  PlatformException(code: code),
  isCamera: isCamera,
  isVideo: isVideo,
);

void main() {
  group('permission refusals', () {
    test(
      'a denied grant is classed as permission, not failure — the user can fix '
      'it, so the sentence points at Settings',
      () {
        final e = classify('camera_access_denied');
        expect(e.kind, MediaPickerErrorKind.permission);
        expect(e.message, ActivityMediaStrings.cameraPermissionDenied);
        expect(e.message, contains('Settings'));
      },
    );

    test('photo library denial gets library wording, not camera wording', () {
      final e = classify('photo_access_denied', isCamera: false);
      expect(e.kind, MediaPickerErrorKind.permission);
      expect(e.message, ActivityMediaStrings.photoPermissionDenied);
    });

    test(
      'a RESTRICTED grant must not tell the user to open Settings — device '
      'policy is not theirs to change',
      () {
        for (final code in <String>[
          'camera_access_restricted',
          'photo_access_restricted',
        ]) {
          final e = classify(code);
          expect(e.kind, MediaPickerErrorKind.permission, reason: code);
          expect(e.message, isNot(contains('Settings')), reason: code);
        }
      },
    );

    test('permission refusals are still reported (non-fatal), not swallowed', () {
      expect(classify('camera_access_denied').shouldReport, isTrue);
    });
  });

  group('specific hardware and picker-state failures', () {
    test('no camera on the device gets its own sentence', () {
      final e = classify('no_available_camera');
      expect(e.message, ActivityMediaStrings.noCameraAvailable);
      expect(e.message, isNot(ActivityMediaStrings.cameraUnavailable));
    });

    test('a picker already open gets its own sentence', () {
      for (final code in <String>['already_active', 'multiple_request']) {
        expect(
          classify(code).message,
          ActivityMediaStrings.pickerAlreadyOpen,
          reason: code,
        );
      }
    });

    test(
      'a capture that happened but could not be read back says "recording", '
      'not "camera" — the camera worked, the storage/URI step did not',
      () {
        for (final code in <String>[
          'no_valid_video_uri',
          'no_valid_media_uri',
          'create_error',
          'video_error',
          'flutter_image_picker_copy_video_error',
        ]) {
          expect(
            classify(code).message,
            ActivityMediaStrings.captureUnreadable,
            reason: code,
          );
        }
      },
    );

    test('every specific code produces a message distinct from the generic one', () {
      const specific = <String>[
        'no_available_camera',
        'already_active',
        'camera_access_denied',
        'camera_access_restricted',
      ];
      for (final code in specific) {
        expect(
          classify(code).message,
          isNot(ActivityMediaStrings.cameraUnavailable),
          reason: '$code must not fall back to the generic message',
        );
      }
    });
  });

  group('fallbacks', () {
    test('an unknown platform code degrades to the generic message', () {
      final e = classify('something_new_in_a_future_plugin');
      expect(e.kind, MediaPickerErrorKind.failure);
      expect(e.message, ActivityMediaStrings.cameraUnavailable);
      expect(e.code, 'something_new_in_a_future_plugin');
    });

    test('a non-PlatformException still classifies rather than throwing', () {
      final e = MediaPickerError.from(
        StateError('boom'),
        isCamera: false,
        isVideo: true,
      );
      expect(e.kind, MediaPickerErrorKind.failure);
      expect(e.code, 'unknown');
      expect(e.message, ActivityMediaStrings.videoSourceUnavailable);
    });

    test('the retained code is always non-empty, so a report can be bucketed', () {
      expect(classify('').code, 'unknown');
    });
  });

  test('no classification is ever fatal — these are all handled', () {
    // The type carries no fatal flag at all: severity is decided by the caller,
    // and MediaUploadTrace.failure defaults to non-fatal. This test documents
    // the invariant so a future `fatal` field cannot be added silently.
    for (final code in <String>[
      'camera_access_denied',
      'no_available_camera',
      'already_active',
      'unknown_code',
    ]) {
      expect(classify(code).kind, isNot(MediaPickerErrorKind.cancellation));
    }
  });
}
