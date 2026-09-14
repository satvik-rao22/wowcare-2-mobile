import 'package:dio/dio.dart';

/// Downloads a file from a URL to a local [savePath].
///
/// Uses a plain [Dio] with NO auth interceptors on purpose: student/staff
/// document links are pre-signed EXTERNAL (CloudFront/document-MS) URLs, so the
/// app's `Authorization` header and API base URL must not be attached to the
/// request. Living in the network/data layer keeps views from constructing a
/// `Dio()` themselves (MVVM: the UI dispatches, it does not do network I/O).
class FileDownloadService {
  FileDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<void> downloadToFile(String url, String savePath) =>
      _dio.download(url, savePath);
}
