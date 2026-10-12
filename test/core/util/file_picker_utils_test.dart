import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';

void main() {
  test('csv is in allowedDocumentExtensions', () {
    expect(FilePickerUtils.allowedDocumentExtensions, contains('csv'));
  });
}
