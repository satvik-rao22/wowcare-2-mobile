import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// WhatsApp-style rich text formatting toolbar.
///
/// Wraps the current selection in the given HTML tags, or (when no text is
/// selected) inserts the tags with the cursor placed between them so the user
/// can start typing formatted content immediately.
///
/// Bullet list: prepends "• " to the current line.
/// Numbered list: prepends "1. " to the current line.
///
/// The controller is expected to own a [TextEditingController] already
/// attached to the active [TextField]. This widget does NOT manage focus.
class RichTextToolbar extends StatelessWidget {
  const RichTextToolbar({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  // ── Tag wrapping ─────────────────────────────────────────────────────────

  void _wrapWith(String openTag, String closeTag) {
    final sel = controller.selection;
    if (!sel.isValid) return;
    final text = controller.text;

    if (sel.isCollapsed) {
      // No selection: insert both tags and place cursor between them.
      final pos = sel.baseOffset;
      controller.value = controller.value.copyWith(
        text:
            text.substring(0, pos) + openTag + closeTag + text.substring(pos),
        selection: TextSelection.collapsed(offset: pos + openTag.length),
      );
    } else {
      // Selection: wrap the selected text.
      final start = sel.start;
      final end = sel.end;
      final selected = text.substring(start, end);
      controller.value = controller.value.copyWith(
        text: text.substring(0, start) +
            openTag +
            selected +
            closeTag +
            text.substring(end),
        selection: TextSelection.collapsed(
          offset: start + openTag.length + selected.length + closeTag.length,
        ),
      );
    }
  }

  // ── List prefixes ─────────────────────────────────────────────────────────

  void _prefixCurrentLine(String prefix) {
    final sel = controller.selection;
    final text = controller.text;
    final pos = sel.isValid ? sel.baseOffset : text.length;

    // Find the start of the current line.
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;

    // If the line already starts with this prefix, remove it (toggle).
    if (text.substring(lineStart).startsWith(prefix)) {
      final newText =
          text.substring(0, lineStart) + text.substring(lineStart + prefix.length);
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: (pos - prefix.length).clamp(lineStart, newText.length),
        ),
      );
    } else {
      controller.value = controller.value.copyWith(
        text: text.substring(0, lineStart) + prefix + text.substring(lineStart),
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _ToolbarBtn(
              icon: Icons.format_bold,
              label: 'Bold',
              onTap: () => _wrapWith('<b>', '</b>'),
            ),
            _ToolbarBtn(
              icon: Icons.format_italic,
              label: 'Italic',
              onTap: () => _wrapWith('<i>', '</i>'),
            ),
            _ToolbarBtn(
              icon: Icons.format_underlined,
              label: 'Underline',
              onTap: () => _wrapWith('<u>', '</u>'),
            ),
            _ToolbarBtn(
              icon: Icons.format_strikethrough,
              label: 'Strikethrough',
              onTap: () => _wrapWith('<s>', '</s>'),
            ),
            const _Divider(),
            _ToolbarBtn(
              icon: Icons.format_list_bulleted,
              label: 'Bullet list',
              onTap: () => _prefixCurrentLine('• '),
            ),
            _ToolbarBtn(
              icon: Icons.format_list_numbered,
              label: 'Numbered list',
              onTap: () => _prefixCurrentLine('1. '),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // onTapDown fires on pointer-down, before the text field loses focus.
    // InkWell.onTap fires on pointer-up — too late when focus loss removes
    // the toolbar from the tree first (empty field, _hasFocus → false).
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTapDown: (_) => onTap(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFE2E8F0),
    );
  }
}
