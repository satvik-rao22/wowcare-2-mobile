import 'dart:io';

import 'package:file_picker/file_picker.dart';
// ignore: implementation_imports
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';

/// Leading bytes of real formats, enough for the `mime` sniffer.
const _jpegHeader = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
const _pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
const _zipHeader = [0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x00, 0x00];

class _FakeFilePicker extends FilePickerPlatform {
  _FakeFilePicker(this.onPick);

  final Future<FilePickerResult?> Function() onPick;
  List<String>? lastDialogExtensions;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) {
    lastDialogExtensions = allowedExtensions;
    return onPick();
  }
}

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

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('fpu_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String write(String name, List<int> bytes) {
    final file = File('${tmp.path}/$name')..writeAsBytesSync(bytes);
    return file.path;
  }

  const documentsAndMedia = [
    ...FilePickerUtils.allowedDocumentExtensions,
    ...FilePickerUtils.allowedImageExtensions,
    ...FilePickerUtils.allowedVideoExtensions,
  ];

  group('FilePickerUtils.dialogExtensions', () {
    test('drops the MIME-subtype entries that disable the Android filter', () {
      final dialog = FilePickerUtils.dialogExtensions(
        FilePickerUtils.allowedImageExtensions,
      );
      expect(dialog, isNot(contains('heic-sequence')));
      expect(dialog, isNot(contains('heif-sequence')));
      expect(dialog, containsAll(['jpg', 'png', 'heic', 'heif', 'webp']));
    });

    test('every extension sent to the dialog has a MIME type', () {
      // file_picker drops the whole filter on Android if any one is unknown.
      for (final ext in FilePickerUtils.dialogExtensions(documentsAndMedia)) {
        expect(
          FilePickerUtils.getMimeType(ext),
          isNot('application/octet-stream'),
          reason: ext,
        );
      }
    });
  });

  group('FilePickerUtils.isAllowedType', () {
    Future<bool> allowed(String name, List<int> bytes, List<String> exts) =>
        FilePickerUtils.isAllowedType(
          name: name,
          path: write(name, bytes),
          allowedExtensions: exts,
        );

    test('accepts listed extensions, case-insensitively', () async {
      expect(await allowed('report.pdf', _pdfHeader, documentsAndMedia), true);
      expect(await allowed('sheet.xlsx', _zipHeader, documentsAndMedia), true);
      expect(await allowed('IMG_1.JPG', _jpegHeader, documentsAndMedia), true);
    });

    test('rejects archives, apps, executables and text', () async {
      expect(await allowed('a.zip', _zipHeader, documentsAndMedia), false);
      expect(await allowed('app.apk', _zipHeader, documentsAndMedia), false);
      expect(
        await allowed('setup.exe', [0x4D, 0x5A], documentsAndMedia),
        false,
      );
      expect(
        await allowed('note.txt', 'hello'.codeUnits, documentsAndMedia),
        false,
      );
    });

    test('a name with no extension falls back to the content', () async {
      expect(
        await allowed(
          'IMG_1234',
          _jpegHeader,
          FilePickerUtils.allowedImageExtensions,
        ),
        true,
      );
      expect(await allowed('Report', _pdfHeader, documentsAndMedia), true);
      expect(await allowed('Archive', _zipHeader, documentsAndMedia), false);
    });

    test('content outside the list is still rejected', () async {
      // A PDF is not an image, whatever its name.
      expect(
        await allowed(
          'scan',
          _pdfHeader,
          FilePickerUtils.allowedImageExtensions,
        ),
        false,
      );
    });

    test('an unreadable path is rejected, not thrown', () async {
      expect(
        await FilePickerUtils.isAllowedType(
          name: 'gone',
          path: '${tmp.path}/missing',
          allowedExtensions: documentsAndMedia,
        ),
        false,
      );
    });

    test('an empty list means no filter', () async {
      expect(await allowed('a.zip', _zipHeader, const []), true);
    });
  });

  group('FilePickerUtils.pickFile', () {
    late FilePickerPlatform original;
    setUp(() => original = FilePickerPlatform.instance);
    tearDown(() => FilePickerPlatform.instance = original);

    void pickReturns(String name, {List<int>? bytes, bool noPath = false}) {
      final path = noPath ? null : write(name, bytes ?? const []);
      FilePickerPlatform.instance = _FakeFilePicker(
        () async => FilePickerResult([
          PlatformFile(name: name, path: path, size: bytes?.length ?? 0),
        ]),
      );
    }

    test('returns an allowed file unchanged', () async {
      pickReturns('report.pdf', bytes: _pdfHeader);
      final file = await FilePickerUtils.pickFile(
        allowedExtensions: documentsAndMedia,
      );
      expect(file?.name, 'report.pdf');
    });

    test('returns an extension-less photo that sniffs as an image', () async {
      pickReturns('IMG_1234', bytes: _jpegHeader);
      final file = await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
      );
      expect(file?.name, 'IMG_1234');
    });

    test('rejects a zip or apk that got past the dialog filter', () async {
      pickReturns('a.zip', bytes: _zipHeader);
      expect(
        await FilePickerUtils.pickFile(allowedExtensions: documentsAndMedia),
        isNull,
      );
      pickReturns('app.apk', bytes: _zipHeader);
      expect(
        await FilePickerUtils.pickFile(allowedExtensions: documentsAndMedia),
        isNull,
      );
    });

    test('rejects a file with no local path', () async {
      pickReturns('cloud.pdf', noPath: true);
      expect(
        await FilePickerUtils.pickFile(allowedExtensions: documentsAndMedia),
        isNull,
      );
    });

    test('both pickers hand the dialog a filter it can apply', () async {
      final fake = _FakeFilePicker(() async => null);
      FilePickerPlatform.instance = fake;
      await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
      );
      expect(fake.lastDialogExtensions, isNot(contains('heic-sequence')));
      await FilePickerUtils.pickMultipleFiles(kind: FilePickerKind.image);
      expect(fake.lastDialogExtensions, isNot(contains('heic-sequence')));
      expect(fake.lastDialogExtensions, contains('jpg'));
    });

    test('cancel returns null', () async {
      FilePickerPlatform.instance = _FakeFilePicker(() async => null);
      expect(await FilePickerUtils.pickFile(), isNull);
    });

    testWidgets('a rejected pick shows an error toast', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final path = tmp.path;
      await tester.runAsync(() async {
        File('$path/a.zip').writeAsBytesSync(_zipHeader);
        FilePickerPlatform.instance = _FakeFilePicker(
          () async => FilePickerResult([
            PlatformFile(name: 'a.zip', path: '$path/a.zip', size: 8),
          ]),
        );
        final file = await FilePickerUtils.pickFile(
          allowedExtensions: documentsAndMedia,
          context: ctx,
        );
        expect(file, isNull);
      });
      await tester.pump();
      expect(find.text('a.zip is not a supported file type'), findsOneWidget);
      // Let the banner's auto-dismiss timer run out.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}
