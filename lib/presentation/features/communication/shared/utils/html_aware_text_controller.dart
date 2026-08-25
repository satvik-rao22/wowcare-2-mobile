import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
    final base = style ?? AppTextStyles.body;
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
      AppTextStyles.body.copyWith(decoration: TextDecoration.underline),
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
