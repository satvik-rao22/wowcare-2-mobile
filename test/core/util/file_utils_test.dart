import 'package:flutter_test/flutter_test.dart';
import 'package:mime/mime.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '/tmp/app';
}

/// FilePickerUtils' MIME table as it was before FileUtils — kept here to prove
/// upload content types don't change.
const _tableBefore = {
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'jpeg': 'image/jpeg',
  'jpg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'heic-sequence': 'image/heic-sequence',
  'heif-sequence': 'image/heif-sequence',
  'avif': 'image/avif',
  'gif': 'image/gif',
  'bmp': 'image/bmp',
  'tif': 'image/tiff',
  'tiff': 'image/tiff',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
  'csv': 'text/csv',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'wav': 'audio/x-wav',
  'aac': 'audio/aac',
  'ogg': 'audio/ogg',
  'opus': 'audio/opus',
};

void main() {
  group('extension', () {
    test('lowercase, no dot', () {
      expect(FileUtils.extension('/a/b/Report.PDF'), 'pdf');
      expect(FileUtils.extension('photo.jpeg'), 'jpeg');
    });

    test('URL: ignores query and fragment', () {
      expect(
        FileUtils.extension('https://cdn.x.com/f/clip.MP4?sig=a.b&x=1#t=2'),
        'mp4',
      );
    });

    test('no extension → empty (not the whole path)', () {
      expect(FileUtils.extension('/data/user/0/cache/image_picker123'), '');
      expect(FileUtils.extension('https://cdn.x.com/asset/abc'), '');
    });
  });

  test('fileName works on paths and URLs', () {
    expect(FileUtils.fileName('/a/b/report.pdf'), 'report.pdf');
    expect(
      FileUtils.fileName('https://cdn.x.com/f/clip.mp4?sig=1'),
      'clip.mp4',
    );
  });

  group('safeFileName', () {
    test('replaces illegal characters and whitespace', () {
      expect(
        FileUtils.safeFileName('a/b:c*d?"e<f>g|h\\i'),
        'a_b_c_d__e_f_g_h_i',
      );
      expect(FileUtils.safeFileName('Term 1  report.pdf'), 'Term_1_report.pdf');
    });

    test('keeps non-Latin letters, so different names stay different', () {
      expect(FileUtils.safeFileName('प्रमाण पत्र.pdf'), 'प्रमाण_पत्र.pdf');
      expect(
        FileUtils.safeFileName('रिपोर्ट.pdf'),
        isNot(FileUtils.safeFileName('प्रमाण.pdf')),
      );
    });
  });

  group('mimeType', () {
    test('same result as before for every extension we know', () {
      // Before: lookupMimeType(path) ?? FilePickerUtils.getMimeType(ext).
      for (final MapEntry(key: ext, value: tableType) in _tableBefore.entries) {
        final before = lookupMimeType('file.$ext') ?? tableType;
        expect(FileUtils.mimeType('/x/file.$ext'), before, reason: ext);
        expect(FileUtils.mimeTypeForExtension(ext), tableType, reason: ext);
      }
    });

    test('unknown → octet-stream, or the given fallback', () {
      expect(FileUtils.mimeType('/x/file.qqq'), 'application/octet-stream');
      expect(
        FileUtils.mimeType('/x/noext', fallback: 'image/jpeg'),
        'image/jpeg',
      );
      expect(FileUtils.mimeTypeForExtension(null), 'application/octet-stream');
      expect(FileUtils.mimeTypeForExtension('.PDF'), 'application/pdf');
    });

    test('works on URLs', () {
      expect(
        FileUtils.mimeType('https://cdn.x.com/a/b.png?sig=1'),
        'image/png',
      );
    });

    test('isImage / isVideo', () {
      expect(FileUtils.isImage('a.HEIC'), isTrue);
      expect(FileUtils.isVideo('https://cdn.x.com/a.mov?s=1'), isTrue);
      expect(FileUtils.isImage('a.pdf'), isFalse);
      expect(FileUtils.isVideo('a.jpg'), isFalse);
    });
  });

  group('tempPathForDownload', () {
    setUp(() => PathProviderPlatform.instance = _FakePathProvider());

    test('name + the URL extension, in the temp folder', () async {
      expect(
        await FileUtils.tempPathForDownload(
          'https://cdn.x.com/d/abc.PDF?sig=1',
          name: 'Medical form',
          fallbackExtension: 'bin',
        ),
        '/tmp/app/Medical_form.pdf',
      );
    });

    test('URL without an extension → fallbackExtension', () async {
      expect(
        await FileUtils.tempPathForDownload(
          'https://cdn.x.com/d/abc',
          name: 'photo',
          fallbackExtension: 'jpg',
        ),
        '/tmp/app/photo.jpg',
      );
    });

    test('blank name → wowcare_file_<time>', () async {
      final path = await FileUtils.tempPathForDownload(
        'https://cdn.x.com/d/abc.mp4',
        name: '  ',
        fallbackExtension: 'mp4',
      );
      expect(path, matches(RegExp(r'^/tmp/app/wowcare_file_\d+\.mp4$')));
    });
  });
}
