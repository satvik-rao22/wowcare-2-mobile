import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'computeFileChecksumSha256 (streamed, off-isolate) matches the direct '
    'readAsBytes + sha256 digest',
    () async {
      final service = ImageUploadService(ApiClient(baseUrl: 'http://localhost'));

      final dir = await Directory.systemTemp.createTemp('checksum_test');
      final file = File('${dir.path}/blob.bin');
      // Multi-chunk content so the streamed hash spans several reads.
      final bytes = List<int>.generate(200000, (i) => i % 256);
      await file.writeAsBytes(bytes);

      final expected = base64Encode(sha256.convert(bytes).bytes);
      final actual = await service.computeFileChecksumSha256(file);

      expect(actual, expected);

      await dir.delete(recursive: true);
    },
  );
}
