import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

/// A [TextEditingController] that renders supported inline HTML formatting
/// tags visually while hiding the raw markup from the user.
///
/// Supported tags: `<b>`, `<i>`, `<u>`, `<s>` (and their closing forms).
/// All other markup is displayed verbatim so the user is never surprised by
/// unexpected rendering.
///
/// **How it works**
/// The controller's underlying [text] always contains the raw HTML (so the
/// caller can read and send it to the backend unchanged). [buildTextSpan]
/// overrides the display layer to render formatted [TextSpan]s:
/// — tag characters are drawn with `fontSize: 0.001` + transparent colour so
///   they occupy their cursor positions but are visually invisible.
/// — the surrounding content is styled bold / italic / underline / strikethrough
///   as appropriate.
///
/// **Cursor behaviour**
/// Arrow-key navigation may briefly "dwell" on invisible tag characters, which
/// the user may perceive as the cursor not moving. In practice this only
/// occurs when using keyboard arrow keys to navigate through a formatted word,
/// not during normal typing via the toolbar buttons. This is the standard
/// tradeoff for inline-styled [TextField]s without a full WYSIWYG engine.
class HtmlAwareTextController extends TextEditingController {
  HtmlAwareTextController({super.text});

  /// Intercepts every value change to apply two deterministic corrections
  /// the platform doesn't reliably give us on its own — see
  /// [_continueListPrefixIfNeeded] and [_capitalizeIfNeeded]. Both are
  /// no-ops (return null) for anything that isn't a single-character
  /// insertion at a collapsed cursor, so paste/cut/select-all/clipboard
  /// methods below (which replace multi-character spans) pass through
  /// unchanged.
  @override
  set value(TextEditingValue newValue) {
    super.value =
        _continueListPrefixIfNeeded(newValue) ??
        _capitalizeIfNeeded(newValue) ??
        newValue;
  }

  /// Auto-continues a bullet ("• ") or numbered ("1. ", "2. ", ...) list
  /// prefix onto the next line when Enter is pressed inside one — the web
  /// composer's rich-text editor does this natively; this TextField-based
  /// one doesn't, since Enter on a multiline TextField just inserts a bare
  /// `\n` with no awareness of list context. Pressing Enter on an EMPTY
  /// list line (prefix with nothing typed after it) ends the list instead
  /// of perpetuating empty bullets, matching standard rich-text-editor
  /// convention.
  ///
  /// Returns null when no continuation applies.
  TextEditingValue? _continueListPrefixIfNeeded(TextEditingValue newValue) {
    final insertion = _singleCharInsertion(newValue);
    if (insertion == null || insertion.char != '\n') return null;
    final oldText = text;
    final insertAt = insertion.at;

    // The '\n' landed at index insertAt - 1. If that's 0, it's the very
    // first character (nothing before it) — no prior line to continue.
    // Guards `lastIndexOf`'s start index, which must be >= 0.
    if (insertAt - 1 <= 0) return null;

    final priorLineStart = oldText.lastIndexOf('\n', insertAt - 2) + 1;
    final priorLine = oldText.substring(priorLineStart, insertAt - 1);

    final bulletMatch = RegExp(r'^• ').firstMatch(priorLine);
    final numberedMatch = RegExp(r'^(\d+)\. ').firstMatch(priorLine);
    if (bulletMatch == null && numberedMatch == null) return null;

    final prefixEnd = bulletMatch?.end ?? numberedMatch!.end;
    final priorContent = priorLine.substring(prefixEnd);

    if (priorContent.isEmpty) {
      // Enter on an empty list line ends the list: strip that line's own
      // prefix instead of adding another empty bullet.
      final withoutPrefix =
          oldText.substring(0, priorLineStart) +
          oldText.substring(insertAt - 1);
      return TextEditingValue(
        text: withoutPrefix,
        selection: TextSelection.collapsed(offset: priorLineStart),
      );
    }

    final nextPrefix = numberedMatch != null
        ? '${int.parse(numberedMatch.group(1)!) + 1}. '
        : '• ';
    final newText = newValue.text;
    final withPrefix =
        newText.substring(0, insertAt) +
        nextPrefix +
        newText.substring(insertAt);
    return TextEditingValue(
      text: withPrefix,
      selection: TextSelection.collapsed(offset: insertAt + nextPrefix.length),
    );
  }

  /// Auto-capitalizes a letter typed at the start of the message, right
  /// after a newline, right after a fresh bullet/numbered prefix (typed
  /// via the toolbar or continued by [_continueListPrefixIfNeeded]), or
  /// right after sentence-ending punctuation + space — deterministic
  /// backstop for `TextCapitalization.sentences` (set on the field
  /// itself), which delegates to the platform keyboard and is known to
  /// not reliably fire on several Android keyboards once the period and
  /// the next word are typed as separate "words" rather than one gesture.
  ///
  /// Returns null when no correction applies.
  TextEditingValue? _capitalizeIfNeeded(TextEditingValue newValue) {
    final insertion = _singleCharInsertion(newValue);
    if (insertion == null) return null;
    final upper = insertion.char.toUpperCase();
    if (insertion.char == upper) return null; // not a lowercase letter

    final before = newValue.text.substring(0, insertion.at - 1);
    final atStart = before.isEmpty || before.endsWith('\n');
    // No space required after the punctuation — real typing on mobile
    // routinely runs the next letter straight into the period with no gap
    // (as reported: "Hhnnn." followed immediately by "b", no space typed),
    // and `\s+` here meant that exact, common case never capitalized.
    final afterSentenceEnd = RegExp(r'[.!?]\s*$').hasMatch(before);
    final afterFreshListPrefix = RegExp(
      r'(?:^|\n)(?:• |\d+\. )$',
    ).hasMatch(before);
    if (!atStart && !afterSentenceEnd && !afterFreshListPrefix) return null;

    final newText = newValue.text;
    final capitalized =
        newText.substring(0, insertion.at - 1) +
        upper +
        newText.substring(insertion.at);
    return TextEditingValue(
      text: capitalized,
      selection: TextSelection.collapsed(offset: insertion.at),
    );
  }

  /// Recognizes "exactly one character was inserted at a collapsed
  /// cursor, nothing else in the text changed" — the shape of a single
  /// keypress, as opposed to an IME autocomplete replace, a paste, or a
  /// toolbar/clipboard edit (all of which this controller's own methods
  /// below also route through the [value] setter).
  ({int at, String char})? _singleCharInsertion(TextEditingValue newValue) {
    final oldText = text;
    final newText = newValue.text;
    if (newText.length != oldText.length + 1) return null;
    if (!newValue.selection.isValid || !newValue.selection.isCollapsed) {
      return null;
    }
    final at = newValue.selection.baseOffset;
    if (at < 1 || at > newText.length) return null;
    if (newText.substring(0, at - 1) != oldText.substring(0, at - 1)) {
      return null;
    }
    if (newText.substring(at) != oldText.substring(at - 1)) return null;
    return (at: at, char: newText[at - 1]);
  }

  /// Copies the current selection as plain text (stripping any rich-text tags)
  /// rather than the underlying HTML markup.
  String plainTextSelection() {
    final selection = this.selection;
    if (!selection.isValid) return '';
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (start >= end) return '';
    return MessageContentProcessor.stripHtmlTags(text.substring(start, end));
  }

  /// Converts clipboard payloads into a safe inline HTML representation for
  /// editing. Supported inline tags are kept so the editor renders them
  /// visually while the raw markup stays internal to the existing controller.
  String normalizeClipboardPayload(String input) {
    if (input.trim().isEmpty) return '';

    var normalized = input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');

    normalized = normalized.replaceAllMapped(
      RegExp(r'<(/?)(b|i|u|s|strong|em)\b[^>]*>', caseSensitive: false),
      (match) {
        final closing = match.group(1) == '/' ? '/' : '';
        final tag = match.group(2)!.toLowerCase();
        switch (tag) {
          case 'strong':
            return '<${closing}b>';
          case 'em':
            return '<${closing}i>';
          default:
            return '<${closing}$tag>';
        }
      },
    );

    normalized = normalized.replaceAll(
      RegExp(r'<(?!/?(?:b|i|u|s|strong|em)\b)[^>]+>', caseSensitive: false),
      '',
    );

    final cleaned = normalized
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');

    if (cleaned.trim().isEmpty) return '';

    return cleaned
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .replaceAll(RegExp(r'\n+$'), '');
  }

  /// Inserts clipboard content at the current selection while preserving the
  /// editor’s existing HTML-aware representation.
  void insertClipboardContent(String input) {
    final normalized = normalizeClipboardPayload(input);
    if (normalized.isEmpty) return;

    final selection = this.selection;
    if (!selection.isValid) return;

    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final before = text.substring(0, start);
    final after = text.substring(end);

    final replacement = '$before$normalized$after';
    final newSelection = TextSelection.collapsed(
      offset: start + normalized.length,
    );

    value = value.copyWith(
      text: replacement,
      selection: newSelection,
      composing: TextRange.empty,
    );
  }

  /// Copies the current selection to the system clipboard using plain text.
  Future<bool> copySelectionToClipboard() async {
    final plainText = plainTextSelection();
    if (plainText.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: plainText));
    return true;
  }

  /// Cuts the current selection to the system clipboard and removes it from
  /// the editor while preserving cursor stability.
  Future<bool> cutSelectionToClipboard() async {
    final plainText = plainTextSelection();
    if (plainText.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: plainText));

    final selection = this.selection;
    if (!selection.isValid) return false;

    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (start >= end) return true;

    final replacement = '${text.substring(0, start)}${text.substring(end)}';
    final newSelection = TextSelection.collapsed(offset: start);
    value = value.copyWith(
      text: replacement,
      selection: newSelection,
      composing: TextRange.empty,
    );
    return true;
  }

  /// Pastes clipboard content into the editor at the current selection.
  Future<bool> pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final content = clipboardData?.text ?? '';
    if (content.isEmpty) return false;

    insertClipboardContent(content);
    return true;
  }

  /// Selects all text in the editor.
  void selectAllText() {
    if (text.isEmpty) return;
    value = value.copyWith(
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      composing: TextRange.empty,
    );
  }

  // Matches opening or closing b/i/u/s/strong/em tags.
  static final RegExp _tagRx = RegExp(
    r'<(/?\s*(?:b|i|u|s|strong|em)\s*)>',
    caseSensitive: false,
  );

  // Tag characters are drawn invisible but still exist at their cursor offsets.
  static const TextStyle _hidden = TextStyle(
    fontSize: 0.001,
    color: Colors.transparent,
    height: 0.0,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : null;
    return _buildFormattedSpan(text, base, composing: composing);
  }

  TextSpan _buildFormattedSpan(
    String raw,
    TextStyle base, {
    TextRange? composing,
  }) {
    if (raw.isEmpty) return TextSpan(text: '', style: base);

    final children = <InlineSpan>[];
    int pos = 0;
    int bold = 0, italic = 0, underline = 0, strike = 0;

    for (final m in _tagRx.allMatches(raw)) {
      // Text chunk before this tag.
      if (m.start > pos) {
        _addChunk(
          children,
          raw,
          pos,
          m.start,
          base,
          bold,
          italic,
          underline,
          strike,
          composing,
        );
      }

      // Render the tag itself as invisible so it occupies its cursor offset
      // but never appears to the user.
      children.add(TextSpan(text: m.group(0), style: _hidden));

      // Maintain formatting depth so nested / mismatched tags degrade gracefully.
      final inner = m.group(1)!.trim().toLowerCase();
      final isClose = inner.startsWith('/');
      final name = inner.replaceFirst('/', '').trim();
      if (name == 'b' || name == 'strong') {
        bold = (bold + (isClose ? -1 : 1)).clamp(0, 10);
      } else if (name == 'i' || name == 'em') {
        italic = (italic + (isClose ? -1 : 1)).clamp(0, 10);
      } else if (name == 'u') {
        underline = (underline + (isClose ? -1 : 1)).clamp(0, 10);
      } else if (name == 's') {
        strike = (strike + (isClose ? -1 : 1)).clamp(0, 10);
      }

      pos = m.end;
    }

    // Remaining text after the last matched tag.
    if (pos < raw.length) {
      _addChunk(
        children,
        raw,
        pos,
        raw.length,
        base,
        bold,
        italic,
        underline,
        strike,
        composing,
      );
    }

    return TextSpan(
      style: base,
      children: children.isEmpty
          ? [TextSpan(text: raw, style: base)]
          : children,
    );
  }

  void _addChunk(
    List<InlineSpan> out,
    String raw,
    int start,
    int end,
    TextStyle base,
    int bold,
    int italic,
    int underline,
    int strike,
    TextRange? composing,
  ) {
    if (start >= end) return;

    final decorations = <TextDecoration>[
      if (underline > 0) TextDecoration.underline,
      if (strike > 0) TextDecoration.lineThrough,
    ];

    final formatted = base.copyWith(
      fontWeight: bold > 0 ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic > 0 ? FontStyle.italic : FontStyle.normal,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );

    if (composing == null || !composing.isValid) {
      out.add(TextSpan(text: raw.substring(start, end), style: formatted));
      return;
    }

    // Intersect [start, end) with the IME composing range and apply the
    // standard composing underline to that portion.
    final composingStyle = formatted.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    final cStart = composing.start.clamp(start, end);
    final cEnd = composing.end.clamp(start, end);

    if (start < cStart) {
      out.add(TextSpan(text: raw.substring(start, cStart), style: formatted));
    }
    if (cStart < cEnd) {
      out.add(
        TextSpan(text: raw.substring(cStart, cEnd), style: composingStyle),
      );
    }
    if (cEnd < end) {
      out.add(TextSpan(text: raw.substring(cEnd, end), style: formatted));
    }
  }
}

class HtmlAwareTextSelectionControls {
  const HtmlAwareTextSelectionControls._();

  static Widget buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
    HtmlAwareTextController controller,
  ) {
    final plainText = controller.plainTextSelection();
    final buttonItems = <ContextMenuButtonItem>[];

    if (plainText.isNotEmpty) {
      buttonItems.add(
        ContextMenuButtonItem(
          onPressed: () async {
            await controller.copySelectionToClipboard();
            editableTextState.hideToolbar();
          },
          label: 'Copy',
        ),
      );
      buttonItems.add(
        ContextMenuButtonItem(
          onPressed: () async {
            await controller.cutSelectionToClipboard();
            editableTextState.hideToolbar();
          },
          label: 'Cut',
        ),
      );
    }

    buttonItems.add(
      ContextMenuButtonItem(
        onPressed: () async {
          await controller.pasteFromClipboard();
          editableTextState.hideToolbar();
        },
        label: 'Paste',
      ),
    );

    buttonItems.add(
      ContextMenuButtonItem(
        onPressed: () {
          controller.selectAllText();
          editableTextState.hideToolbar();
        },
        label: 'Select All',
      ),
    );

    if (buttonItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }
}
