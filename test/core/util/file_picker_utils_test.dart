import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';

void main() {
  group('FilePickerUtils.friendlyUploadErrorMessage', () {
    test('translates a rejected content-type message into plain language', () {
      const backendMessage =
          "Content type 'application/octet-stream' is not allowed for "
          'DOCUMENT.';
      final result = FilePickerUtils.friendlyUploadErrorMessage(backendMessage);
      expect(result, isNot(contains('content type')));
      expect(result, isNot(contains('octet-stream')));
      expect(result, contains('format'));
    });

    test('is case-insensitive when detecting the content-type rejection', () {
      const backendMessage =
          "CONTENT TYPE 'IMAGE/HEIC' IS NOT ALLOWED FOR DOCUMENT.";
      final result = FilePickerUtils.friendlyUploadErrorMessage(backendMessage);
      expect(result, contains('format'));
    });

    test('passes through any other backend message unchanged', () {
      const backendMessage = 'File size exceeds the 25MB limit.';
      expect(
        FilePickerUtils.friendlyUploadErrorMessage(backendMessage),
        backendMessage,
      );
    });
  });
}
