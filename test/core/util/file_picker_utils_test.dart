import 'dart:io';

import 'package:file_picker/file_picker.dart';
// ignore: implementation_imports
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';

/// Stands in for the OS file picker: hands back [paths], or throws [error].
class _FakeFilePicker extends FilePickerPlatform
    with MockPlatformInterfaceMixin {
  List<String>? paths;
  Object? error;
  FileType? lastType;
  List<String>? lastExtensions;
  bool? lastMultiple;

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
  }) async {
    lastType = type;
    lastExtensions = allowedExtensions;
    lastMultiple = allowMultiple;
    if (error != null) throw error!;
    final picked = paths;
    if (picked == null) return null; // cancelled
    return FilePickerResult([
      for (final p in picked)
        PlatformFile(path: p, name: p.split('/').last, size: 0),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late _FakeFilePicker picker;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pick_');
    picker = _FakeFilePicker();
    FilePickerPlatform.instance = picker;
  });
  tearDown(() => dir.delete(recursive: true));

  /// A real file of [sizeMB] megabytes (plus a few bytes).
  Future<String> file(String name, {double sizeMB = 0}) async {
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(List.filled((sizeMB * 1024 * 1024).round() + 8, 0));
    return f.path;
  }

  test('csv is in allowedDocumentExtensions', () {
    expect(FilePickerUtils.allowedDocumentExtensions, contains('csv'));
  });

  group('pick', () {
    test('files: opens the browser with the type\'s extensions', () async {
      picker.paths = [await file('report.pdf')];

      final files = await FilePickerUtils.pick(multiple: true);

      expect(picker.lastType, FileType.custom);
      expect(picker.lastExtensions, FilePickerUtils.allowedDocumentExtensions);
      expect(picker.lastMultiple, isTrue);
      expect(files.single.name, 'report.pdf');
      expect(files.single.extension, 'pdf');
      expect(files.single.mimeType, 'application/pdf');
      expect(files.single.size, greaterThan(0));
    });

    test('photos: opens the library for the right media', () async {
      picker.paths = [];
      await FilePickerUtils.pick(
        type: PickType.image,
        source: PickSource.photos,
      );
      expect(picker.lastType, FileType.image);

      await FilePickerUtils.pick(
        type: PickType.video,
        source: PickSource.photos,
      );
      expect(picker.lastType, FileType.video);

      await FilePickerUtils.pick(
        type: PickType.imageOrVideo,
        source: PickSource.photos,
      );
      expect(picker.lastType, FileType.media);
    });

    test('drops unsupported types and files over the limit', () async {
      picker.paths = [
        await file('ok.jpg'),
        await file('song.mp3'),
        await file('big.png', sizeMB: 2),
      ];

      final files = await FilePickerUtils.pick(
        type: PickType.image,
        source: PickSource.photos,
        multiple: true,
        maxSizeMB: 1,
      );

      expect(files.map((f) => f.name), ['ok.jpg']);
    });

    test('videos use maxVideoSizeMB, other files maxSizeMB', () async {
      picker.paths = [
        await file('clip.mp4', sizeMB: 2),
        await file('photo.jpg', sizeMB: 2),
      ];

      final files = await FilePickerUtils.pick(
        type: PickType.imageOrVideo,
        multiple: true,
        maxSizeMB: 1,
        maxVideoSizeMB: 5,
      );

      expect(files.map((f) => f.name), ['clip.mp4']);
      expect(files.single.isVideo, isTrue);
    });

    test('allowedExtensions overrides the type\'s list', () async {
      picker.paths = [await file('scan.pdf')];
      final files = await FilePickerUtils.pick(
        type: PickType.image,
        allowedExtensions: ['pdf'],
      );
      expect(picker.lastExtensions, ['pdf']);
      expect(files.single.name, 'scan.pdf');
    });

    test('cancel → empty list', () async {
      picker.paths = null;
      expect(await FilePickerUtils.pick(), isEmpty);
      expect(await FilePickerUtils.pickOne(), isNull);
    });

    test('picker error → onError, empty list, no throw', () async {
      picker.error = Exception('broken provider');
      Object? reported;

      final files = await FilePickerUtils.pick(onError: (e, _) => reported = e);

      expect(files, isEmpty);
      expect(reported, picker.error);
    });
  });

  group('rejectionMessage', () {
    test('nothing rejected → null', () {
      expect(
        FilePickerUtils.rejectionMessage(unsupported: [], oversized: {}),
        isNull,
      );
    });

    test('names the file when only one was skipped', () {
      expect(
        FilePickerUtils.rejectionMessage(
          unsupported: [],
          oversized: {'photo.png': 10 * 1024 * 1024},
        ),
        allOf(contains('photo.png'), contains('10 MB')),
      );
      expect(
        FilePickerUtils.rejectionMessage(
          unsupported: ['song.mp3'],
          oversized: {},
        ),
        contains('song.mp3'),
      );
    });

    test('counts files when several were skipped', () {
      final message = FilePickerUtils.rejectionMessage(
        unsupported: ['a.mp3'],
        oversized: {'b.png': 10 * 1024 * 1024},
      );
      expect(message, contains('2'));
    });
  });
}
