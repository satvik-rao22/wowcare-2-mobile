import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:wowcare/data/services/file_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File file;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_download_service');
    file = File('${tempDir.path}/report.xlsx');
    await file.writeAsBytes(<int>[1, 2, 3]);
  });

  tearDown(() async => tempDir.delete(recursive: true));

  /// open_filex reports a failed hand-off through the returned [OpenResult],
  /// never by throwing.
  FileDownloadService serviceReturning(ResultType result, String message) =>
      FileDownloadService(
        opener: (filePath, {String? type}) async =>
            OpenResult(type: result, message: message),
      );

  Future<bool> open(FileDownloadService service) => service.openFile(
    filePath: file.path,
    fileName: 'report.xlsx',
    assetCode: 'ASSET_1',
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  test('reports failure when no installed app can open the file', () async {
    // Android's routine outcome for an XLSX on a device with no spreadsheet
    // app: the plugin catches ActivityNotFoundException and hands back
    // noAppToOpen. Discarding that reported it as a success, so the caller
    // told the user the report had opened when nothing had happened.
    final service = serviceReturning(
      ResultType.noAppToOpen,
      'No APP found to open this file。',
    );

    expect(await open(service), isFalse);
  });

  test('reports failure when the platform reports an error', () async {
    final service = serviceReturning(
      ResultType.error,
      'File opened incorrectly。',
    );

    expect(await open(service), isFalse);
  });

  test('reports failure when the platform denies permission', () async {
    final service = serviceReturning(
      ResultType.permissionDenied,
      'Permission denied',
    );

    expect(await open(service), isFalse);
  });

  test('reports success when the handler takes the file', () async {
    final service = serviceReturning(ResultType.done, 'done');

    expect(await open(service), isTrue);
  });

  test('reports failure when the file is not on disk', () async {
    final service = serviceReturning(ResultType.done, 'done');

    expect(
      await service.openFile(
        filePath: '${tempDir.path}/missing.xlsx',
        fileName: 'missing.xlsx',
        assetCode: 'ASSET_2',
        mimeType: 'application/pdf',
      ),
      isFalse,
    );
  });
}
