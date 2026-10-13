import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';

/// The one place the app downloads a ready URL: into a file, or into memory
/// as image bytes.
///
/// "Ready" means already resolved: features turn our server's asset codes
/// into a delivery URL first (e.g. AttachmentUrlResolver), then hand that URL
/// here. This class knows nothing about our server.
///
/// Uses a plain [Dio] with NO auth interceptors on purpose: student/staff
/// document links are pre-signed EXTERNAL (CloudFront/document-MS) URLs, so the
/// app's `Authorization` header and API base URL must not be attached to the
/// request. Living in the network/data layer keeps views from constructing a
/// `Dio()` themselves (MVVM: the UI dispatches, it does not do network I/O).
///
/// Cubits take it as a constructor argument (so tests can pass a fake);
/// screens with no cubit use [instance].
///
/// Which file util?
/// | Need                                        | Use                       |
/// |---------------------------------------------|---------------------------|
/// | Name, extension, MIME type, app folders     | FileUtils                 |
/// | Let the user pick a file / photo / video    | FilePickerUtils           |
/// | Download a URL into a file                  | FileDownloadService (this)|
/// | Open, share or save a file to the gallery   | FileActions               |
class FileDownloadService {
  FileDownloadService({
    Dio? dio,
    Duration retryDelay = const Duration(milliseconds: 600),
  }) : _dio = dio ?? Dio(),
       _retryDelay = retryDelay;

  /// Shared instance for screens that have no cubit to inject one into.
  static final FileDownloadService instance = FileDownloadService();

  final Dio _dio;
  final Duration _retryDelay;

  /// Streams [url] to [savePath]. Throws when the download fails or the file
  /// comes back empty — an empty file is deleted rather than left behind,
  /// where it would be mistaken for a cached copy.
  Future<void> downloadToFile(String url, String savePath) async {
    await _dio.download(url, savePath);
    final file = File(savePath);
    if (await file.length() == 0) {
      await file.delete();
      throw const FileSystemException('Downloaded file is empty');
    }
  }

  /// The image at [url] as bytes, or empty bytes when it can't be loaded.
  ///
  /// Tries [attempts] times, waiting a little longer each time: a just-uploaded
  /// image can 403/404 on the CDN edge for a moment before it propagates, and
  /// a 200 isn't proof of an image either (a still-propagating edge, a
  /// redirect page or a cut-short body can all come back as 200). Bytes count
  /// only when they decode as an image, so the caller never hands broken data
  /// to an image widget.
  Future<Uint8List> downloadImageBytes(String url, {int attempts = 5}) async {
    for (var i = 0; i < attempts; i++) {
      try {
        final response = await _dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final data = response.data;
        if (response.statusCode == 200 && data != null && data.isNotEmpty) {
          final bytes = Uint8List.fromList(data);
          if (await _isImage(bytes)) return bytes;
        }
      } catch (_) {
        // Retried below.
      }
      if (i < attempts - 1) await Future<void>.delayed(_retryDelay * (i + 1));
    }
    return Uint8List(0);
  }

  static Future<bool> _isImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }
}
