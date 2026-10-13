import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mime/mime.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '/tmp/app';

  String? documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
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

  group('mimeType (by name)', () {
    test('same result as before for every extension we know', () {
      for (final MapEntry(key: ext, value: tableType) in _tableBefore.entries) {
        // Was: lookupMimeType(path) ?? FilePickerUtils.getMimeType(ext).
        expect(
          FileUtils.mimeType('/x/file.$ext'),
          lookupMimeType('file.$ext') ?? tableType,
          reason: ext,
        );
        // Was (student documents, profile photos): the table alone.
        expect(FileUtils.mimeType('/x/file.$ext'), tableType, reason: ext);
      }
    });

    test('case-insensitive; unknown → octet-stream or the given fallback', () {
      expect(FileUtils.mimeType('Fees.CSV'), 'text/csv');
      expect(FileUtils.mimeType('/x/file.qqq'), 'application/octet-stream');
      expect(
        FileUtils.mimeType('/x/noext', fallback: 'image/jpeg'),
        'image/jpeg',
      );
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

  group('mimeTypeOfFile (uploads)', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('fu_'));
    tearDown(() => dir.delete(recursive: true));

    Future<String> file(String name, List<int> bytes) async {
      final f = File('${dir.path}/$name');
      await f.writeAsBytes([...bytes, ...List.filled(64, 0)]);
      return f.path;
    }

    final heic = [0, 0, 0, 0x18, ...'ftypheic'.codeUnits];
    final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    final pdf = '%PDF-1.7'.codeUnits;
    final webm = [0x1A, 0x45, 0xDF, 0xA3, ...'webm'.codeUnits];
    final zip = [0x50, 0x4B, 0x03, 0x04]; // what .docx/.xlsx really are

    test(
      'a photo with the wrong extension uploads with its real type',
      () async {
        expect(
          await FileUtils.mimeTypeOfFile(await file('IMG_1.jpg', heic)),
          'image/heic',
        );
        expect(
          await FileUtils.mimeTypeOfFile(await file('shot.jpg', png)),
          'image/png',
        );
      },
    );

    test('a PDF is recognised from its bytes', () async {
      expect(
        await FileUtils.mimeTypeOfFile(await file('scan.dat', pdf)),
        'application/pdf',
      );
    });

    test('videos and Office files keep their name-based type', () async {
      // The mime package would misread WebM bytes as audio/weba.
      expect(
        await FileUtils.mimeTypeOfFile(await file('clip.webm', webm)),
        'video/webm',
      );
      expect(
        await FileUtils.mimeTypeOfFile(await file('form.docx', zip)),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    });

    test(
      'unrecognised bytes or an unreadable file → the name decides',
      () async {
        expect(
          await FileUtils.mimeTypeOfFile(
            await file('notes.csv', 'a,b'.codeUnits),
          ),
          'text/csv',
        );
        expect(
          await FileUtils.mimeTypeOfFile('${dir.path}/missing.png'),
          'image/png',
        );
      },
    );

    test('imageMimeTypeOfFile: real image type, else image/jpeg', () async {
      expect(
        await FileUtils.imageMimeTypeOfFile(await file('a.jpg', png)),
        'image/png',
      );
      expect(
        await FileUtils.imageMimeTypeOfFile(await file('a.pdf', pdf)),
        'image/jpeg',
      );
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

  group('saveToDocuments / documentsFile', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('docs_');
      PathProviderPlatform.instance = _FakePathProvider()
        ..documentsPath = dir.path;
    });
    tearDown(() => dir.delete(recursive: true));

    test('saves under the cleaned name and finds it again', () async {
      final path = await FileUtils.saveToDocuments(
        Uint8List.fromList([1, 2, 3]),
        'Term 1 report.pdf',
      );
      // The exact path the old FileDownloadService used, so files saved
      // before this change are still found and not downloaded again.
      expect(path, '${dir.path}/Term_1_report.pdf');
      final file = await FileUtils.documentsFile('Term 1 report.pdf');
      expect(file.path, path);
      expect(await file.readAsBytes(), [1, 2, 3]);
    });

    test('nothing to save → null, no file', () async {
      expect(await FileUtils.saveToDocuments(Uint8List(0), 'a.pdf'), isNull);
      expect(await File('${dir.path}/a.pdf').exists(), isFalse);
    });
  });
}
