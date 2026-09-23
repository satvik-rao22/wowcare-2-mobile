import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_html_normalizer.dart';

void main() {
  group('normalizeNewsletterHtml: removes editor filler', () {
    test('strips the trailing empty paragraphs that open the mobile gap', () {
      const authored = '<p><strong>Classroom Spotlights</strong></p>'
          '<ul><li>Infants &amp; Toddlers: sensory play.</li></ul>'
          '<p><br></p><p><br></p><p><br></p><p><br></p><p><br></p>';

      expect(
        normalizeNewsletterHtml(authored),
        '<p><strong>Classroom Spotlights</strong></p>'
        '<ul><li>Infants &amp; Toddlers: sensory play.</li></ul>',
      );
    });

    test('strips empty blocks wrapped in the formatting that was active', () {
      const authored = '<p>Body copy.</p>'
          '<p><span style="color:#4b2354"><br></span></p>'
          '<div><strong>&nbsp;</strong></div>';

      expect(normalizeNewsletterHtml(authored), '<p>Body copy.</p>');
    });

    test('strips leading empty blocks too', () {
      const authored = '<p><br></p><p>&nbsp;</p><p>Real content.</p>';

      expect(normalizeNewsletterHtml(authored), '<p>Real content.</p>');
    });

    test('strips bare trailing and leading <br> runs', () {
      expect(
        normalizeNewsletterHtml('<br><br>Some text.<br><br><br>'),
        'Some text.',
      );
    });

    test('collapses a long run of <br> in the middle to one blank line', () {
      expect(
        normalizeNewsletterHtml('<p>One.<br><br><br><br><br><br>Two.</p>'),
        '<p>One.<br><br>Two.</p>',
      );
    });

    test('content that is nothing but filler normalizes to empty, so the '
        'widget renders nothing at all', () {
      expect(normalizeNewsletterHtml('<p><br></p><p>&nbsp;</p>'), '');
      expect(normalizeNewsletterHtml('<br><br><br>'), '');
      expect(normalizeNewsletterHtml('   '), '');
      expect(normalizeNewsletterHtml(''), '');
    });
  });

  group('normalizeNewsletterHtml: leaves real content alone', () {
    test('a genuine in-prose line break survives', () {
      const authored = '<p>Line one.<br>Line two.</p>';

      expect(normalizeNewsletterHtml(authored), authored);
    });

    test('one deliberate blank line between paragraphs survives', () {
      const authored = '<p>One.<br><br>Two.</p>';

      expect(normalizeNewsletterHtml(authored), authored);
    });

    test('an empty block BETWEEN two content blocks is kept — it is spacing '
        'the author put between things, not padding at an edge', () {
      const authored = '<p>Above.</p><p><br></p><p>Below.</p>';

      expect(normalizeNewsletterHtml(authored), authored);
    });

    test('a block holding only an image is not treated as empty', () {
      const authored = '<p><img src="https://example.com/a.png"></p>';

      expect(normalizeNewsletterHtml(authored), authored);
    });

    test('mismatched tags are never collapsed across each other', () {
      const authored = '<div><p>Kept.</p></div>';

      expect(normalizeNewsletterHtml(authored), authored);
    });

    test('a fully-populated fragment is returned byte-for-byte', () {
      const authored = '<h2>Title</h2>'
          '<p>Paragraph with <em>emphasis</em> and a '
          '<a href="https://example.com">link</a>.</p>'
          '<ul><li>First</li><li>Second</li></ul>';

      expect(normalizeNewsletterHtml(authored), authored);
    });
  });
}
