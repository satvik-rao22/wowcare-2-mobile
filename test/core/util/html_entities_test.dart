import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/html_entities.dart';

void main() {
  group('HtmlEntities.decode', () {
    test('turns the escaped apostrophe from a notification back', () {
      expect(
        HtmlEntities.decode('- I can&#39;t see you after 4 pm'),
        "- I can't see you after 4 pm",
      );
    });

    test('decodes hex and named references', () {
      expect(HtmlEntities.decode('it&#x27;s'), "it's");
      expect(
        HtmlEntities.decode('Tom &amp; Jerry &quot;hi&quot;'),
        'Tom & Jerry "hi"',
      );
    });

    test('is a single pass, so double-escaped text loses one level only', () {
      expect(HtmlEntities.decode('&amp;lt;b&amp;gt;'), '&lt;b&gt;');
    });

    test('leaves plain text and unknown references alone', () {
      expect(HtmlEntities.decode('A & B'), 'A & B');
      expect(HtmlEntities.decode('&bogus;'), '&bogus;');
      expect(HtmlEntities.decodeOrNull(null), isNull);
    });
  });
}
