import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_component_view.dart';

NewsletterComponent _component({
  required String type,
  List<NewsletterContentPart> parts = const <NewsletterContentPart>[],
}) =>
    NewsletterComponent(
      id: 1,
      componentType: type,
      sortOrder: 1,
      parts: parts,
    );

void main() {
  group('NewsletterComponentList.hasRenderableContent', () {
    test('a TEXT component whose markup is only editor filler does not count '
        '— it builds a zero-height box, so it must not earn a gap', () {
      final components = <NewsletterComponent>[
        _component(
          type: 'TEXT',
          parts: const [
            NewsletterContentPart.text(text: '<p><br></p><p>&nbsp;</p>'),
          ],
        ),
      ];

      expect(NewsletterComponentList.hasRenderableContent(components), isFalse);
    });

    test('a TEXT component with real prose counts', () {
      final components = <NewsletterComponent>[
        _component(
          type: 'TEXT',
          parts: const [NewsletterContentPart.text(text: '<p>Real copy.</p>')],
        ),
      ];

      expect(NewsletterComponentList.hasRenderableContent(components), isTrue);
    });

    test('a component with a usable image counts even when its text is '
        'filler', () {
      final components = <NewsletterComponent>[
        _component(
          type: 'TEXT_TOP_IMAGE',
          parts: const [
            NewsletterContentPart.text(text: '<p><br></p>'),
            NewsletterContentPart.image(imageUrl: 'https://example.com/a.png'),
          ],
        ),
      ];

      expect(NewsletterComponentList.hasRenderableContent(components), isTrue);
    });

    test('an IMAGE component with no usable part still counts — the block '
        'deliberately falls back to the default artwork', () {
      final components = <NewsletterComponent>[_component(type: 'IMAGE')];

      expect(NewsletterComponentList.hasRenderableContent(components), isTrue);
    });

    test('a DIVIDER counts; it paints a rule and carries no parts', () {
      final components = <NewsletterComponent>[_component(type: 'DIVIDER')];

      expect(NewsletterComponentList.hasRenderableContent(components), isTrue);
    });

    test('an all-filler component list reports nothing renderable, so the '
        'preview can fall through to its own empty state', () {
      final components = <NewsletterComponent>[
        _component(
          type: 'TEXT',
          parts: const [NewsletterContentPart.text(text: '<p><br></p>')],
        ),
        _component(type: 'UNKNOWN_TYPE'),
        _component(
          type: 'TEXT_BLOCK',
          parts: const [NewsletterContentPart.text(text: '<br><br><br>')],
        ),
      ];

      expect(NewsletterComponentList.hasRenderableContent(components), isFalse);
    });

    test('one real component among filler is enough', () {
      final components = <NewsletterComponent>[
        _component(
          type: 'TEXT',
          parts: const [NewsletterContentPart.text(text: '<p><br></p>')],
        ),
        _component(
          type: 'TEXT',
          parts: const [NewsletterContentPart.text(text: '<p>Kept.</p>')],
        ),
      ];

      expect(NewsletterComponentList.hasRenderableContent(components), isTrue);
    });

    test('an empty list is not renderable', () {
      expect(
        NewsletterComponentList.hasRenderableContent(
          const <NewsletterComponent>[],
        ),
        isFalse,
      );
    });
  });
}
