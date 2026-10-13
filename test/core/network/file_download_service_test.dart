import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/file_download_service.dart';

/// A 1×1 transparent PNG — the smallest bytes that decode as an image.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Answers each request with the next queued (status, body) pair.
class _FakeNetwork implements HttpClientAdapter {
  _FakeNetwork(this.replies);

  final List<(int, List<int>)> replies;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = replies[requests++ % replies.length];
    return ResponseBody.fromBytes(body, status);
  }

  @override
  void close({bool force = false}) {}
}

FileDownloadService _service(_FakeNetwork network) => FileDownloadService(
  dio: Dio()..httpClientAdapter = network,
  retryDelay: Duration.zero,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('downloadToFile', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('dl_'));
    tearDown(() => dir.delete(recursive: true));

    test('writes the body to the path', () async {
      final path = '${dir.path}/doc.pdf';
      await _service(
        _FakeNetwork([
          (200, [1, 2, 3]),
        ]),
      ).downloadToFile('https://cdn.example/doc.pdf', path);
      expect(await File(path).readAsBytes(), [1, 2, 3]);
    });

    test(
      'an empty body throws and leaves no file to mistake for a cache',
      () async {
        final path = '${dir.path}/empty.pdf';
        await expectLater(
          _service(
            _FakeNetwork([(200, [])]),
          ).downloadToFile('https://cdn.example/empty.pdf', path),
          throwsA(isA<FileSystemException>()),
        );
        expect(await File(path).exists(), isFalse);
      },
    );

    test('an HTTP error throws', () async {
      await expectLater(
        _service(
          _FakeNetwork([(403, [])]),
        ).downloadToFile('https://cdn.example/x.pdf', '${dir.path}/x.pdf'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('downloadImageBytes', () {
    test('returns the image on the first good answer', () async {
      final network = _FakeNetwork([(200, _png)]);
      expect(
        await _service(network).downloadImageBytes('https://cdn/a.png'),
        _png,
      );
      expect(network.requests, 1);
    });

    test('retries through a CDN 404 and non-image bytes', () async {
      final network = _FakeNetwork([
        (404, []),
        (200, utf8.encode('<html>redirect</html>')),
        (200, _png),
      ]);
      expect(
        await _service(network).downloadImageBytes('https://cdn/a.png'),
        _png,
      );
      expect(network.requests, 3);
    });

    test('gives up after the attempts with empty bytes', () async {
      final network = _FakeNetwork([(404, [])]);
      expect(
        await _service(network).downloadImageBytes('https://cdn/a.png'),
        isEmpty,
      );
      expect(network.requests, 5);
    });
  });
}
