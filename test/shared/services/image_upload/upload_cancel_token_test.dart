import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uploadFileToPresignedUrl aborts with a cancel DioException when the '
    'CancelToken is already cancelled before the request is sent',
    () async {
      final service = ImageUploadService(ApiClient(baseUrl: 'http://localhost'));

      final dir = await Directory.systemTemp.createTemp('upload_cancel_test');
      final file = File('${dir.path}/blob.bin');
      final bytes = List<int>.generate(2048, (i) => i % 256);
      await file.writeAsBytes(bytes);

      final token = CancelToken();
      // Cancel up front: Dio checks the token before dispatching, so the PUT
      // is aborted immediately with a `cancel`-type DioException rather than
      // ever hitting the network.
      token.cancel('cancelled before send');

      Object? thrown;
      try {
        await service.uploadFileToPresignedUrl(
          file: file,
          presignedPutUrl: 'http://localhost/x',
          cancelToken: token,
        );
        fail('expected uploadFileToPresignedUrl to throw when cancelled');
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isA<DioException>());
      expect(CancelToken.isCancel(thrown as DioException), isTrue);

      await dir.delete(recursive: true);
    },
  );
}
