/// Strips the filler markup a WYSIWYG editor leaves behind, so authored blank
/// lines don't become dead vertical space on a phone.
///
/// **Why this exists.** Newsletters are composed in a web rich-text editor on a
/// wide, roughly page-shaped canvas. Pressing Enter to push an image down, or to
/// pad a block out to the bottom of its column, is stored verbatim as
/// `<p><br></p>` (or a run of bare `<br>`s) — layout that only makes sense at the
/// width it was authored at. Mobile stacks the same components in a narrow
/// column where each of those costs a full line box, so a handful of them opens
/// a gap several hundred pixels tall between a text block and the image after
/// it, with the real content already finished.
///
/// It is specifically NOT a general HTML sanitizer, and deliberately leaves
/// genuine authored line breaks alone: a `<br>` between two lines of prose still
/// breaks the line, and a single blank line between paragraphs survives. Only
/// runs longer than one blank line, and empty blocks at the very start or end of
/// a fragment (where nothing follows them to separate), are removed.
library;

/// Inline markup an "empty" block is still allowed to contain — editors wrap
/// even a blank line in the formatting that was active when it was typed, so
/// `<p><span style="…"><br></span></p>` is the same nothing as `<p><br></p>`.
const String _inlineNoise =
    r'(?:\s|&nbsp;|&#160;|<br\s*/?>|</?(?:span|em|strong|b|i|u|font)\b[^>]*>)*';

/// A block element whose entire content is [_inlineNoise]. The backreference
/// ties the closing tag to the opening one so `<p>…</div>` can't match.
final RegExp _emptyBlock = RegExp(
  '<(p|div|h[1-6])\\b[^>]*>$_inlineNoise</\\1>',
  caseSensitive: false,
);

final RegExp _leadingEmptyBlocks = RegExp(
  '^(?:\\s*${_emptyBlock.pattern})+',
  caseSensitive: false,
);

final RegExp _trailingEmptyBlocks = RegExp(
  '(?:${_emptyBlock.pattern}\\s*)+\$',
  caseSensitive: false,
);

/// Three or more `<br>`s in a row. Two are kept — that is one deliberate blank
/// line between paragraphs, which is legitimate authoring.
final RegExp _brRun = RegExp(
  r'(?:<br\s*/?>\s*){3,}',
  caseSensitive: false,
);

/// Trailing whitespace and `<br>`s that aren't wrapped in a block of their own.
final RegExp _trailingBreaks = RegExp(
  r'(?:\s|&nbsp;|&#160;|<br\s*/?>)+$',
  caseSensitive: false,
);

final RegExp _leadingBreaks = RegExp(
  r'^(?:\s|&nbsp;|&#160;|<br\s*/?>)+',
  caseSensitive: false,
);

/// Returns [rawHtml] with editor filler removed, or `''` when nothing but
/// filler was there to begin with.
///
/// Purely textual and non-destructive to content: it never touches a block that
/// carries text, an image, or any tag outside the small inline set above.
String normalizeNewsletterHtml(String rawHtml) {
  var html = rawHtml.trim();
  if (html.isEmpty) return '';

  html = html.replaceAll(_brRun, '<br><br>');

  // Stripping an outer empty block can expose another one that was separated
  // from the edge only by the block just removed, so both edges are re-tested
  // until they stop changing. Bounded: every pass either shortens the string or
  // ends the loop.
  String previous;
  do {
    previous = html;
    html = html
        .replaceFirst(_leadingEmptyBlocks, '')
        .replaceFirst(_trailingEmptyBlocks, '')
        .replaceFirst(_leadingBreaks, '')
        .replaceFirst(_trailingBreaks, '')
        .trim();
  } while (html != previous && html.isNotEmpty);

  return html;
}
