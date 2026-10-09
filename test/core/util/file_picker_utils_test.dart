import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';

void main() {
  group('FilePickerUtils.getMimeType', () {
    test('resolves .csv to text/csv (not the octet-stream fallback)', () {
      expect(FilePickerUtils.getMimeType('csv'), 'text/csv');
      expect(FilePickerUtils.getMimeType('.csv'), 'text/csv');
      expect(FilePickerUtils.getMimeType('CSV'), 'text/csv');
    });

    test(
      'falls back to application/octet-stream for a genuinely unknown extension',
      () {
        expect(FilePickerUtils.getMimeType('xyz'), 'application/octet-stream');
      },
    );
  });

  test('csv is in allowedDocumentExtensions', () {
    expect(FilePickerUtils.allowedDocumentExtensions, contains('csv'));
  });
}
