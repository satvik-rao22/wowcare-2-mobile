import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Splits newsletter HTML into block-level chunks for wrap-around layout.
List<String> splitNewsletterHtmlIntoBlocks(String rawHtml) {
  final String trimmed = rawHtml.trim();
  if (trimmed.isEmpty) return const <String>[];

  final dom.DocumentFragment fragment = html_parser.parseFragment(trimmed);
  final List<String> blocks = <String>[];

  for (final dom.Node node in fragment.nodes) {
    if (node is dom.Element) {
      final String outer = node.outerHtml.trim();
      if (outer.isNotEmpty) blocks.add(outer);
      continue;
    }
    if (node is dom.Text) {
      final String text = node.text.trim();
      if (text.isNotEmpty) blocks.add('<p>$text</p>');
    }
  }

  if (blocks.isEmpty) {
    return <String>[
      trimmed.startsWith('<') ? trimmed : '<p>$trimmed</p>',
    ];
  }

  return blocks;
}
