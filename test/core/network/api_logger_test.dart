import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_logger.dart';

void main() {
  group('formatBody', () {
    test('indents short JSON on its own lines', () {
      expect(ApiLogger.formatBody({'a': 1}), '\n{\n  "a": 1\n}');
    });

    test('keeps long JSON on one line', () {
      final body = {'items': List.generate(2000, (i) => i)};
      final formatted = ApiLogger.formatBody(body);

      expect(formatted, isNot(contains('\n')));
      expect(formatted, startsWith('{"items":[0,1,2'));
    });

    test('lists form data field names and file sizes, not values', () {
      final form = FormData.fromMap({
        'note': 'private text',
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.jpg'),
      });

      final formatted = ApiLogger.formatBody(form);

      expect(formatted, contains('fields: [note]'));
      expect(formatted, contains('file: a.jpg (3 bytes)'));
      expect(formatted, isNot(contains('private text')));
    });

    test('passes strings through', () {
      expect(ApiLogger.formatBody('<binary: 3 bytes>'), '<binary: 3 bytes>');
    });
  });

  group('maskHeader', () {
    test('shortens a bearer token', () {
      expect(
        ApiLogger.maskHeader(
          'Authorization',
          'Bearer ${'x' * 8}SECRET${'y' * 8}',
        ),
        'Bearer xxxxxxxx...yyyyyyyy',
      );
      expect(
        ApiLogger.maskHeader('authorization', 'Bearer short'),
        'Bearer ***',
      );
    });

    test('hides cookies and non-bearer credentials', () {
      expect(ApiLogger.maskHeader('Cookie', 'refresh=abc'), '***');
      expect(ApiLogger.maskHeader('Authorization', 'Basic abc'), '***');
    });

    test('leaves other headers alone', () {
      expect(
        ApiLogger.maskHeader('Content-Type', 'application/json'),
        'application/json',
      );
    });
  });
}
